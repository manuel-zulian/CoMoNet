// twister_io.js
// 2013 Miguel Freitas
//
// low-level twister i/o.
// implements requests of dht resources. multiple pending requests to the same resource are joined.
// cache results (profile, avatar, etc) in memory.
// avatars are cached in localstored (expiration = 24 hours)
/*jslint browser:true*/
/*globals $, jQuery, console, alert, polyglot*/
(function (globals) {
    'use strict';

    // join multiple dhtgets to the same resources in this map
    var dhtgetPendingMap = {},

        // number of dhtgets in progress (requests to the daemon)
        dhtgetsInProgress = 0,

        // keep maxDhtgets smaller than the number of daemon/browser sockets
        // most browsers limit to 6 per domain (see http://www.browserscope.org/?category=network)
        maxDhtgets = 5,

        // requests not yet sent to the daemon due to maxDhtgets limit
        queuedDhtgets = [],
        
        // last post we got for every user
        lastHaveMap = {};

    // private function to define a key in _dhtgetPendingMap
    function dhtgetLocator(username, resource, multi) {
        return username + ";" + resource + ";" + multi;
    }

    function dhtgetAddPending(locator, cbFunc, cbArg) {
        if (!dhtgetPendingMap.hasOwnProperty(locator)) {
            dhtgetPendingMap[locator] = [];
        }
        dhtgetPendingMap[locator].push({
            cbFunc: cbFunc,
            cbArg: cbArg
        });
    }

    function dhtgetProcessPending(locator, multi, ret) {
        var i, j,
            cbFunc,
            cbArg,
            multiret = [];
        if (dhtgetPendingMap.hasOwnProperty(locator)) {
            for (i = 0; i < dhtgetPendingMap[locator].length; i += 1) {
                cbFunc = dhtgetPendingMap[locator][i].cbFunc;
                cbArg = dhtgetPendingMap[locator][i].cbArg;
                if (multi === 's') {
                    if (ret[0] !== undefined) {
                        cbFunc(cbArg, ret[0].p.v, ret);
                    } else {
                        cbFunc(cbArg, null);
                    }
                } else {
                    for (j = 0; j < ret.length; j += 1) {
                        multiret.push(ret[j].p.v);
                    }
                    cbFunc(cbArg, multiret, ret);
                }
            }
            delete dhtgetPendingMap[locator];
        } else {
            console.log("warning: _dhtgetProcessPending with unknown locator " + locator);
        }
    }

    function dhtgetAbortPending(locator) {
        var i,
            cbFunc,
            cbArg;
        if (dhtgetPendingMap.hasOwnProperty(locator)) {
            for (i = 0; i < dhtgetPendingMap[locator].length; i += 1) {
                cbFunc = dhtgetPendingMap[locator][i].cbFunc;
                cbArg = dhtgetPendingMap[locator][i].cbArg;
                cbFunc(cbArg, null);
            }
            delete dhtgetPendingMap[locator];
        } else {
            console.log("warning: _dhtgetAbortPending with unknown locator " + locator);
        }
    }
    
    function dhtgetInternal(username, resource, multi, timeoutArgs) {
        var locator = dhtgetLocator(username, resource, multi),
            argsList = [username, resource, multi],
            locatorSplit;
        dhtgetsInProgress += 1;
        
        if (typeof timeoutArgs !== 'undefined') {
            argsList = argsList.concat(timeoutArgs);
        }
        globals.twisterRpc("dhtget", argsList,
            function (args, ret) {
                dhtgetsInProgress -= 1;
                dhtgetProcessPending(args.locator, args.multi, ret);
                if (queuedDhtgets.length) {
                    locatorSplit = queuedDhtgets.pop().split(";");
                    dhtgetInternal(locatorSplit[0], locatorSplit[1], locatorSplit[2]);
                }
            }, {
                locator: locator,
                multi: multi
            },
            function (cbArg, ret) {
                console.log("ajax error:" + ret);
                dhtgetsInProgress -= 1;
                dhtgetAbortPending(locator);
                if (queuedDhtgets.length) {
                    locatorSplit = queuedDhtgets.pop().split(";");
                    dhtgetInternal(locatorSplit[0], locatorSplit[1], locatorSplit[2]);
                }
            }, locator);
    }

    // pubkey is obtained from block chain db.
    // so only accepted registrations are reported (local wallet users are not)
    // cbFunc is called as cbFunc(cbArg, pubkey)
    // if user doesn't exist then pubkey.length == 0
    function dumpPubkey(username, cbFunc, cbArg) {
        // pubkey is checked in block chain db.
        // so only accepted registrations are reported (local wallet users are not)
        globals.twisterRpc("dumppubkey", [username],
            function (args, ret) {
                args.cbFunc(args.cbArg, ret);
            }, {
                cbFunc: cbFunc,
                cbArg: cbArg
            },
            function (args, ret) {
                alert(polyglot.t("error_connecting_to_daemon"));
            }, {
                cbFunc: cbFunc,
                cbArg: cbArg
            });
    }

    // privkey is obtained from wallet db
    // so privkey is returned even for unsent transactions
    function dumpPrivkey(username, cbFunc, cbArg) {
        globals.twisterRpc("dumpprivkey", [username],
            function (args, ret) {
                args.cbFunc(args.cbArg, ret);
            }, {
                cbFunc: cbFunc,
                cbArg: cbArg
            },
            function (args, ret) {
                args.cbFunc(args.cbArg, "");
                console.log("dumpprivkey: user unknown");
            }, {
                cbFunc: cbFunc,
                cbArg: cbArg
            });
    }
    
    // handle getlasthave response. the increase in lasthave cannot be assumed to
    // produce new items for timeline since some posts might be directmessages (which
    // won't be returned by getposts, normally).
    function processLastHave(main_status, userHaves) {
        var user;
        for (user in userHaves ) {
            if (userHaves.hasOwnProperty(user)) {
                if (lastHaveMap.hasOwnProperty(user)) {
                    if (userHaves[user] > lastHaveMap[user]) {
                        main_status.should_reload = true;
                    }
                }
                lastHaveMap[user] = userHaves[user];
            }
        }
    }
    
    /****************************
     * Exporting variables
     ****************************/
    
    (function () {
        var posts = [],
            
            // store value at the dht resource
            dhtput = function (username, resource, multi, value, sig_user, seq, cbFunc, cbArg) {
                globals.twisterRpc("dhtput", [username, resource, multi, value, sig_user, seq],
                    function (args, ret) {
                        if (args.cbFunc) {
                            args.cbFunc(args.cbArg, true);
                        }
                    }, {
                        cbFunc: cbFunc,
                        cbArg: cbArg
                    },
                    function (args, ret) {
                        console.log("ajax error:" + ret);
                        if (args.cbFunc) {
                            args.cbFunc(args.cbArg, false);
                        }
                    }, cbArg);
            },
            
            // main json rpc method. receives callbacks for success and error
            twisterRpc = function (method, params, resultFunc, resultArg, errorFunc, errorArg) {
                var foo = new $.JsonRpcClient({
                    ajaxUrl: '/',
                    username: 'user',
                    password: 'pwd'
                });
                foo.call(method, params,
                    function (ret) {
                        resultFunc(resultArg, ret);
                    },
                    function (ret) {
                        if (ret !== null) {
                            errorFunc(errorArg, ret);
                        }
                    }
                        );
            },

            // get data from dht resource
            // the value ["v"] is extracted from response and returned to callback
            // null is passed to callback in case of an error
            dhtget = function (username, resource, multi, cbFunc, cbArg, timeoutArgs) {
                var locator = dhtgetLocator(username, resource, multi);
                if (dhtgetPendingMap.hasOwnProperty(locator)) {
                    dhtgetAddPending(locator, cbFunc, cbArg);
                } else {
                    dhtgetAddPending(locator, cbFunc, cbArg);
                    // limit the number of simultaneous dhtgets.
                    // this should leave some sockets for other non-blocking daemon requests.
                    if (dhtgetsInProgress < maxDhtgets) {
                        dhtgetInternal(username, resource, multi, timeoutArgs);
                    } else {
                        // just queue the locator. it will be unqueue when some dhtget completes.
                        queuedDhtgets.push(locator);
                    }
                }
            },
            
            // calls cbFunc(req, posts) with posts being an array of post
            // this is the real one
            getposts = function (username, cbFunc, cbArgs, limit, max, since) {
                var paramObj = {"username": username},
                    p_limit = 10;
                if (max !== 'undefined') {
                    paramObj.max = max;
                }
                if (since !== 'undefined') {
                    paramObj.since = since;
                }
                if (limit === 'undefined') {
                    p_limit = limit;
                }
                twisterRpc("getposts", [p_limit, [paramObj]], cbFunc, cbArgs);
            },
        
            getlasthave = function (current_user, main_status) {
                twisterRpc("getlasthave", [current_user], processLastHave, main_status);
            };
        
        globals.twisterRpc  = twisterRpc;
        globals.dhtget      = dhtget;
        globals.getposts    = getposts;
        globals.getlasthave = getlasthave;
        globals.dhtput      = dhtput;
    }());

}(this));