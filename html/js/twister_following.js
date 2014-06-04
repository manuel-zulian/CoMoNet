// twister_following.js
// 2013 Miguel Freitas
//
// Manage list of following users. Load/Save to localstorage and DHT.
// Provides random user suggestions to follow.
/*globals console, jQuery*/
(function (globals, $) {
    'use strict';

    /*
    followingUsers = {
        "username": {
            "lastUpdate": <updatetime>,
            "seqNum": <seqNum>,
            "witness": <witness>
        }
    }
    */
    var followingUsers = {},
        isFollowPublic = {},
        followsPerPage = 200,
        maxFollowingPages = 50,
        followingSeqNum = 0,
        followSuggestions = [],
        searchingPartialUsers = "",
        searchKeypressTimer,
        lastSearchUsersResults = [],
        lastLoadFromDhtTime = 0,

        twisterFollowingO,

        TwisterFollowing = function (user) {
            if (!(this instanceof TwisterFollowing)) {
                return new TwisterFollowing(user);
            }

            this.init(user);
        };

    TwisterFollowing.minUpdateInterval = 43200; // 1/2 day
    TwisterFollowing.maxUpdateInterval = 691200; // 8 days

    TwisterFollowing.prototype = {
        user: undefined,
        init: function (user) {
            this.user = user;
            this.load();
            this.update();
        },
        knownFollowers: [],
        knownFollowersResetTime: new Date().getTime() / 1000,
        notFollowers: [],
        /*
        followinsFollowings = {
            "username": {
                "lastUpdate": <updatetime>,
                "updateInterval": <updateinterval>,
                "following": []
            }
        }
         */
        followingsFollowings: {},

        load: function () {
            var ns = $.initNamespaceStorage(this.user),
                ctime;

            if (ns.localStorage.isSet("followingsFollowings")) {
                this.followingsFollowings = ns.localStorage.get("followingsFollowings");
            }

            if (ns.localStorage.isSet("knownFollowersResetTime")) {
                this.knownFollowersResetTime = ns.localStorage.get("knownFollowersResetTime");
            }

            ctime = new Date().getTime() / 1000;
            if (ctime - this.knownFollowersResetTime < TwisterFollowing.maxUpdateInterval &&
                    ns.localStorage.isSet("knownFollowers")) {
                this.knownFollowers = ns.localStorage.get("knownFollowers");
            } else {
                this.knownFollowers = [];
                this.knownFollowersResetTime = ctime;
                ns.localStorage.set("knownFollowersResetTime", this.knownFollowersResetTime);
            }

            if (ns.sessionStorage.isSet("notFollowers")) {
                this.notFollowers = ns.sessionStorage.get("notFollowers");
            }
        },

        save: function () {
            var ns = $.initNamespaceStorage(this.user);
            ns.localStorage.set("followingsFollowings", this.followingsFollowings);
            ns.sessionStorage.set("notFollowers", this.notFollowers);
            ns.localStorage.set("knownFollowers", this.knownFollowers);
            ns.localStorage.set("knownFollowersResetTime", this.knownFollowersResetTime);
        },

        update: function (username) {
            var oneshot = false,
                i = 0;
            if (typeof (username) !== 'undefined') {
                i = followingUsers[username];

                if (i > -1) {
                    oneshot = true;
                } else {
                    i = 0;
                }
            }

            /* followingFollowings
            for (user in followingUsers) {
                var ctime = new Date().getTime() / 1000;

                if (typeof(users) === 'undefined' ||
                    ctime - this.followingsFollowings[user]["lastUpdate"] >= this.followingsFollowings[user]["updateInterval"]) {

                    loadFollowingFromDht(user, 1, [], 0, function (args, following, seqNum) {
                        if (following.indexOf(args.tf.user) > -1) {
                            if (args.tf.knownFollowers.indexOf(args.fu) < 0)
                                args.tf.knownFollowers.push(args.fu);
                        } else {
                            if (args.tf.notFollowers.indexOf(args.fu) < 0)
                                args.tf.notFollowers.push(args.fu);
                            var tmpi = args.tf.knownFollowers.indexOf(args.fu);
                            if (tmpi > -1)
                                args.tf.knownFollowers.splice(tmpi, 1);
                        }
                        $(".open-followers").attr("title", args.tf.knownFollowers.length.toString());

                        var ctime = new Date().getTime() / 1000;
                        if (typeof(args.tf.followingsFollowings[args.fu]) === 'undefined' ||
                            typeof(args.tf.followingsFollowings[args.fu]["following"]) === 'undefined') {
                            args.tf.followingsFollowings[args.fu] = {};
                            args.tf.followingsFollowings[args.fu]["lastUpdate"] = ctime;
                            args.tf.followingsFollowings[args.fu]["updateInterval"] = TwisterFollowing.minUpdateInterval;
                            args.tf.followingsFollowings[args.fu]["following"] = following;

                            args.tf.save();
                        } else {
                            var diff = [];
                            var ff = args.tf.followingsFollowings[args.fu]["following"];

                            for (var j = 0; j < following.length; j++) {
                                if (ff.indexOf(following[j]) === -1) {
                                    diff.push(following[j]);
                                    ff.push(following[j]);
                                }
                            }

                            if (diff.length > 0) {
                                args.tf.followingsFollowings[args.fu]["updateInterval"] = TwisterFollowing.minUpdateInterval;
                                args.tf.followingsFollowings[args.fu]["lastUpdate"] = ctime;
                                args.tf.save();
                            } else if (args.tf.followingsFollowings[args.fu]["updateInterval"] < TwisterFollowing.maxUpdateInterval) {
                                args.tf.followingsFollowings[args.fu]["updateInterval"] *= 2;
                            }
                        }
                    }, {"tf": this, "fu": user});
                }
            }*/
        }
    };

    // load followingUsers from localStorage
    function loadFollowingFromStorage() {
        var ns = $.initNamespaceStorage(defaultScreenName);
        if (ns.localStorage.isSet("followingUsers")) {
            followingUsers = ns.localStorage.get("followingUsers");
        }
        if (ns.localStorage.isSet("isFollowPublic")) {
            isFollowPublic = ns.localStorage.get("isFollowPublic");
        }
        if (ns.localStorage.get("followingSeqNum") > followingSeqNum) {
            followingSeqNum = ns.localStorage.get("followingSeqNum");
        }
        if (ns.localStorage.isSet("lastLoadFromDhtTime")) {
            lastLoadFromDhtTime = ns.localStorage.get("lastLoadFromDhtTime");
        }
        // follow ourselves
        ///if(followingUsers.indexOf(defaultScreenName) < 0) {
        ////    followingUsers.push(defaultScreenName);
        ///}
    }

    // save list of following to localStorage
    function saveFollowingToStorage() {
        var ns = $.initNamespaceStorage(defaultScreenName);
        ns.localStorage.set("followingUsers", followingUsers);
        ns.localStorage.set("isFollowPublic", isFollowPublic);
        ns.localStorage.set("followingSeqNum", followingSeqNum);
        ns.localStorage.set("lastLoadFromDhtTime", lastLoadFromDhtTime);
    }

    // get the witness of specified user from dht resources
    // callback is called as: doneCb(doneArg, witness, seqNum)
    function getWitnessFromDht(username, doneCb, doneArg) {
        var seqNum;
        globals.dhtget(username, "witness", "s",
            function (args, witness, rawdata) {
                if (rawdata) {
                    seqNum = parseInt(rawdata[0].p.seq, 10);
                }

                if (args.doneCb) {
                    args.doneCb(args.doneArg, witness, seqNum);
                }
            }, {
                doneCb: doneCb,
                doneArg: doneArg
            });
    }

    /*
    // load public list of following users from dht resources
    // "following1", "following2" etc.
    // it will stop loading when resource is empty
    // callback is called as: doneCb(doneArg, followingList, seqNum)
    function loadFollowingFromDht(username, pageNumber, followingList, seqNum, doneCb, doneArg) {
        if( !pageNumber ) pageNumber = 1;

        dhtget( username, "following" + pageNumber, "s",
               function(args, following, rawdata) {
                   if( rawdata ) {
                       var seq = parseInt(rawdata[0]["p"]["seq"]);
                       if( seq > args.seqNum ) args.seqNum = seq;
                   }

                   if( following ) {
                       for( var i = 0; i < following.length; i++ ) {
                           if( args.followingList.indexOf(following[i]) < 0 ) {
                               args.followingList.push(following[i]);
                           }
                        }
                   }

                   if( following && following.length && args.pageNumber < _maxFollowingPages) {
                       loadFollowingFromDht(username, args.pageNumber,
                                            args.followingList, args.seqNum,
                                            args.doneCb, args.doneArg);
                   } else {
                       if( args.doneCb )
                           args.doneCb(args.doneArg, args.followingList, args.seqNum);
                   }
               }, {pageNumber:pageNumber+1, followingList:followingList, seqNum:seqNum,
                   doneCb:doneCb, doneArg:doneArg});
    }

    // get number of following from dht and set item.text()
    function getNumFollowing( username, item ) {
        loadFollowingFromDht( username, 1, [], 0,
                              function(args, following, seqNum) {
                                 item.text( following.length );
                             }, null);
    }
    */

    /*
    function loadFollowingIntoList( username, html_list ) {
        loadFollowingFromDht( username, 1, [], 0,
            function(args, following, seqNum) {
                html_list.html("");
                $.each(following, function(i, following_user){
                    var following_user_li = $( "#following-by-user-template" ).children().clone(true);

                    // link follower to profile page
                    $(following_user_li.children()[0]).attr("data-screen-name", following_user);
                    $(following_user_li.children()[0]).attr("href", $.MAL.userUrl(following_user));

                    following_user_li.find(".following-screen-name b").text(following_user);
                    getAvatar( following_user, following_user_li.find(".mini-profile-photo") );
                    var $followingName = following_user_li.find(".mini-following-name");
                    $followingName.text(following_user);
                    getFullname( following_user, $followingName );

                    html_list.append( following_user_li );
                });
            }, null);
    }
    */
    
    // update json rpc with current list of following
    function updateFollowing(cbFunc, cbArg) {
        var toBeFollowed = [],
            theirWitnesses = [],
            user;

        for (user in followingUsers) {
            if (followingUsers.hasOwnProperty(user) && typeof user.witness !== 'undefined') {
                toBeFollowed.push(user);
                theirWitnesses.push(user.witness);
            }
        }
        globals.twisterRpc("follow", [defaultScreenName, toBeFollowed, theirWitnesses],
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
    }

    // load following list from localStorage /*and then from the dht resource*/
    function loadFollowing(cbFunc, cbArg) {
        loadFollowingFromStorage();
        updateFollowing();

        var curTime = new Date().getTime() / 1000;

        // optimization to avoid costly dht lookup everytime the home is loaded
        /*if( curTime > _lastLoadFromDhtTime + 3600*24 ||
            document.URL.indexOf("following") >= 0 ) {
            var numFollow = followingUsers.length;
            loadFollowingFromDht( defaultScreenName, 1, [], _followingSeqNum,
                                  function(args, following, seqNum) {
                                     var curTime = new Date().getTime() / 1000;
                                     _lastLoadFromDhtTime = curTime;

                                     for( var i = 0; i < following.length; i++ ) {
                                         if( followingUsers.indexOf(following[i]) < 0 ) {
                                             followingUsers.push(following[i]);
                                         }
                                         _isFollowPublic[following[i]] = true;
                                      }

                                     if( args.numFollow != followingUsers.length ||
                                         seqNum != _followingSeqNum ) {
                                         _followingSeqNum = seqNum;
                                         // new following loaded from dht
                                         saveFollowingToStorage();
                                         updateFollowing();
                                     }

                                     if( args.cbFunc )
                                         args.cbFunc(args.cbArg);
                                 }, {numFollow:numFollow, cbFunc:cbFunc, cbArg:cbArg} );
        } else {*/
        if (cbFunc) {
            cbFunc(cbArg);
        }
        /*}*/
    }

    // save list of following to dht resource. each page ("following1", following2"...)
    // constains up to _followsPerPage elements. alternatively we might keep track
    // of total strings size to optimize the maximum storage (8kb in node.cpp, but 4kb is
    // probably a good target).
    /*function saveFollowingToDht() {
        var following = [];
        var pageNumber = 1;
        for( var i = 0; i < followingUsers.length; i++ ) {
            if( followingUsers[i] in _isFollowPublic &&
                _isFollowPublic[followingUsers[i]] ) {
                following.push(followingUsers[i]);
            }
            if( following.length == _followsPerPage || i == followingUsers.length-1) {
                dhtput( defaultScreenName, "following" + pageNumber, "s",
                       following, defaultScreenName, _followingSeqNum+1 );
                pageNumber++;
                following = [];
            }
        }
        dhtput( defaultScreenName, "following" + pageNumber, "s",
               following, defaultScreenName, _followingSeqNum+1 );

        _followingSeqNum++;
    }*/

    // save following to local storage, dht and json rpc
    function saveFollowing(cbFunc, cbArg) {
        saveFollowingToStorage();
        //saveFollowingToDht();
        updateFollowing(cbFunc, cbArg);
    }

    function writeWitnessToLocal(userObj, witness, seqNum) {
        userObj.witness = witness;
        userObj.seqNum = seqNum;
    }
    
    // follow a new single user.
    // it is safe to call this even if username is already in followingUsers.
    // may also be used to set/clear publicFollow.
    function follow(user, publicFollow, cbFunc, cbArg) {
        if (typeof followingUsers[user] === 'undefined') {
            followingUsers[user] = {};
        }
        getWitnessFromDht(user, writeWitnessToLocal, followingUsers[user]);
        if (publicFollow === undefined || publicFollow) {
            isFollowPublic[user] = true;
        } else {
            delete isFollowPublic[user];
        }
        saveFollowing(cbFunc, cbArg);
    }

    // unfollow a single user
    /*function unfollow(user, cbFunc, cbArg) {
        var i = followingUsers.indexOf(user);
        if( i >= 0 ) {
            followingUsers.splice(i,1);
        }
        delete _isFollowPublic[user];
        saveFollowing();

        twisterRpc("unfollow", [defaultScreenName,[user]],
                   function(args, ret) {
                       if( args.cbFunc )
                           args.cbFunc(args.cbArg, true);
                   }, {cbFunc:cbFunc, cbArg:cbArg},
                   function(args, ret) {
                       console.log("ajax error:" + ret);
                       if( args.cbFunc )
                           args.cbFunc(args.cbArg, false);
                   }, {cbFunc:cbFunc, cbArg:cbArg});
    }*/

    /*
    // check if public following
    function isPublicFollowing(user) {
        if (typeof followingUsers[user] === 'undefined') {
            return false;
        }
        if ((isFollowPublic.hasOwnProperty(user)) && isFollowPublic[user] === true) {
            return true;
        } else {
            return false;
        }
    }
    */

    /*
    // check if following list is empty
    function followingEmptyOrMyself() {
        if ((($.isEmptyObject(followingUsers)) ||
                (Object.keys(followingUsers).length === 1)) && (typeof followingUsers[defaultScreenName] !== 'undefined')) {
            return true;
        } else {
            return false;
        }
    }
    */

    /*
    function pickRandomElement(obj) {
        var result,
            count = 0,
            el;
        for (el in obj) {
            if (obj.hasOwnProperty(el)) {
                count += 1;
                if (Math.random() < 1 / count) {
                    result = el;
                }
            }
        }
        return result;
    }
    */

    /*
    // randomly choose a user we follow, get "following1" from him and them
    // choose a suggestion from their list. this function could be way better, but
    // that's about the simplest we may get to start with.
    function getRandomFollowSuggestion(cbFunc, cbArg) {
        var user,
            suggested,
            j;

        if (followingEmptyOrMyself()) {
            cbFunc(cbArg, null, null);
            return;
        }

        user = pickRandomElement(followingUsers);

        if (user === defaultScreenName ||
                typeof (twisterFollowingO.followingsFollowings[user]) === 'undefined') {
            setTimeout(getRandomFollowSuggestion, 500, cbFunc, cbArg);
            return;
        }

        if (user !== 'undefined') {
            suggested = false;
            for (j = parseInt(Math.random() * twisterFollowingO.followingsFollowings[user].following.length, 10); j < twisterFollowingO.followingsFollowings[user].following.length; j += 1) {
                if (typeof followingUsers[twisterFollowingO.followingsFollowings[user].following[j]] === 'undefined' &&
                        followSuggestions.indexOf(twisterFollowingO.followingsFollowings[user].following[j]) < 0) {
                    cbFunc(cbArg, twisterFollowingO.followingsFollowings[user].following[j], user);
                    followSuggestions.push(twisterFollowingO.followingsFollowings[user].following[j]);
                    suggested = true;
                    break;
                }
            }
            if (!suggested) {
                cbFunc(cbArg, null, null);
            }
        } else {
            cbFunc(cbArg, null, null);
        }
    }
    */

    /*
    function whoFollows(username) {
        var list = [],
            following;

        for (following in twisterFollowingO.followingsFollowings) {
            if (twisterFollowingO.followingsFollowings.hasOwnProperty(following) && twisterFollowingO.followingsFollowings[following].following.indexOf(username) > -1) {
                list.push(following);
            }
        }
        return list;
    }
    */

    /*
    function fillWhoFollows(list, item, offset, size) {
        var i,
            follower_link;
        for (i = offset; i < offset + size; i += 1) {
            follower_link = $('<a class="mini-follower-link"></a>');

            // link follower to profile page
            follower_link.attr("data-screen-name", list[i]);
            follower_link.attr("href", $.MAL.userUrl(list[i]));
            follower_link.text(list[i]);
            follower_link.on("click", openProfileModal);
            getFullname(list[i], follower_link);

            item.append(follower_link);
        }
    }
    */

    /*
    function getWhoFollows(username, item) {
        if (!defaultScreenName || typeof (defaultScreenName) === 'undefined')
            return;

        var list = whoFollows(username);

        fillWhoFollows(list, item, 0, (list.length > 5 ? 5 : list.length));

        if (list.length > 5) {
            var more_link = $('<a class="show-more-followers">' + polyglot.t('show_more_count', {
                'count': list.length - 5
            }) + '</a>');
            more_link.on('click', function () {
                fillWhoFollows(list, item, 5, list.length - 5);

                var $this = $(this);
                $this.remove();

                $this.text(polyglot.t('hide'));
                $this.unbind('click');
                $this.bind('click', function () {
                    item.html('');
                    getWhoFollows(username, item);
                });

                item.append($this);
            });
            item.append(more_link);
        }
    }
    */

    /*
    // adds following users to the interface (following.html)
    function showFollowingUsers() {
        var $notFollowing = $(".not-following-any");
        if (followingEmptyOrMyself()) {
            $notFollowing.show();
        } else {
            $notFollowing.hide();
        }

        var $followingList = $(".following-list");
        var $template = $("#following-user-template").detach();

        $followingList.empty();
        $followingList.append($template);

        for (user in followingUsers) {
            var resItem = $template.clone(true);
            resItem.removeAttr('id');
            resItem.show();
            resItem.find(".mini-profile-info").attr("data-screen-name", user);
            resItem.find(".following-screen-name").text(user);
            resItem.find("a.open-profile-modal").attr("href", $.MAL.userUrl(user));
            resItem.find("a.unfollow").attr("href", $.MAL.unfollowUrl(user));
            resItem.find("a.direct-messages-with-user").attr("href", $.MAL.dmchatUrl(user));
            resItem.find(".public-following").prop("checked", isPublicFollowing(user));
            getAvatar(user, resItem.find(".mini-profile-photo"));
            getFullname(user, resItem.find(".mini-profile-name"));
            if (user == defaultScreenName) {
                resItem.find("button").hide();
            }

            resItem.appendTo($followingList);
        }
        $.MAL.followingListLoaded();
    }
    */

    /*
    function processSuggestion(arg, suggestion, followedBy) {
        var dashboard = $(".follow-suggestions");
        if (suggestion) {
            var item = $("#follow-suggestion-template").clone(true);
            item.removeAttr("id");

            item.find(".twister-user-info").attr("data-screen-name", suggestion);

            item.find(".twister-user-name").attr("href", $.MAL.userUrl(suggestion));
            item.find(".twister-by-user-name").attr("href", $.MAL.userUrl(followedBy));
            item.find(".twister-user-tag").text("@" + suggestion);

            getAvatar(suggestion, item.find(".twister-user-photo"));

            //getFullname(suggestion,item.find(".twister-user"));
            var $spanFollowedBy = item.find(".followed-by");
            $spanFollowedBy.text(followedBy);
            getFullname(followedBy, $spanFollowedBy);

            item.find('.twister-user-remove').bind("click", function () {
                item.remove();
                getRandomFollowSuggestion(processSuggestion);
            });

            dashboard.append(item);
        }
    }
    */

    /*
    function closeSearchDialog() {
        var $this = $(".userMenu-search-field"); //$( this );
        $(this).siblings().slideUp("fast");
        removeUsersFromDhtgetQueue(_lastSearchUsersResults);
        _lastSearchUsersResults = [];
    }
    */

    /*
    function userSearchKeypress(event) {
        var partialName = $(".userMenu-search-field").val().toLowerCase();
        var searchResults = $(".search-results");

        if (partialName.substr(0, 1) == '#') {

            if (searchResults.is(":visible"))
                searchResults.slideUp("fast");

            if (event.which == 13)
                openHashtagModalFromSearch(partialName.substr(1));

            return;
        }

        if (partialName.substr(0, 1) == '@') {
            partialName = partialName.substr(1);
        }

        //var partialName = item.val();

        if (!partialName.length) {
            closeSearchDialog();
        } else {
            if (_searchKeypressTimer !== undefined)
                clearTimeout(_searchKeypressTimer);

            if (_searchingPartialUsers.length) {
                _searchingPartialUsers = partialName;
            } else {
                _searchKeypressTimer = setTimeout(function () {
                    _searchKeypressTimer = undefined;
                    searchPartialUsername(partialName);
                }, 600);
            }
        }
    }
    */

    /*
    function searchPartialUsername(partialName) {
        _searchingPartialUsers = partialName;
        twisterRpc("listusernamespartial", [partialName, 10],
            function (partialName, ret) {
                processDropdownUserResults(partialName, ret)
            }, partialName,
            function (cbArg, ret) {
                console.log("ajax error:" + ret);
            }, {});
    }
    */

    /*
    function processDropdownUserResults(partialName, results) {

        if (partialName != _searchingPartialUsers) {
            searchPartialUsername(_searchingPartialUsers);
            return;
        }

        removeUsersFromDhtgetQueue(_lastSearchUsersResults);
        _lastSearchUsersResults = results;

        var typeaheadAccounts = $(".userMenu-search-profiles");
        var template = $("#search-profile-template").detach();

        typeaheadAccounts.empty();
        typeaheadAccounts.append(template);

        if (results.length) {
            for (var i = 0; i < results.length; i++) {
                if (results[i] == defaultScreenName)
                    continue;

                var resItem = template.clone(true);
                resItem.removeAttr('id');
                resItem.show();
                resItem.find(".mini-profile-info").attr("data-screen-name", results[i]);
                resItem.find(".mini-screen-name b").text(results[i]);
                resItem.find("a.open-profile-modal").attr("href", $.MAL.userUrl(results[i]));
                getAvatar(results[i], resItem.find(".mini-profile-photo"));
                getFullname(results[i], resItem.find(".mini-profile-name"));
                resItem.appendTo(typeaheadAccounts);
            }

            $.MAL.searchUserListLoaded();
        } else {
            closeSearchDialog();
        }
        _searchingPartialUsers = "";
    }
    */

    /*
    function userClickFollow(e) {
        e.stopPropagation();
        e.preventDefault();

        var $this = $(this);
        var $userInfo = $this.closest("[data-screen-name]");
        var username = $userInfo.attr("data-screen-name");

        if (!defaultScreenName) {
            alert(polyglot.t("You have to log in to follow users."));
            return;
        }

        follow(username, true, function () {
            // delay reload so dhtput may do it's job
            window.setTimeout("location.reload();", 500);
        });
    }
    */

    /*
    function initUserSearch() {
        var $userSearchField = $(".userMenu-search-field");
        $userSearchField.keyup(userSearchKeypress);
        $userSearchField.bind("click", userSearchKeypress);
        $userSearchField.clickoutside(closeSearchDialog);

        $("button.follow").bind("click", userClickFollow);
    }
    */

    /*
    function followingListUnfollow(e) {
        e.stopPropagation();
        e.preventDefault();

        var $this = $(this);
        var username = $this.closest(".mini-profile-info").attr("data-screen-name");

        unfollow(username, function () {
            showFollowingUsers();
        });
    }
    */

    /*
    function followingListPublicCheckbox(e) {
        e.stopPropagation();

        var $this = $(this);
        var username = $this.closest(".mini-profile-info").attr("data-screen-name");
        var public = false;
        $this.toggleClass("private");
        if ($this.hasClass("private")) {
            $this.text(polyglot.t("Private"));
        } else {
            $this.text(polyglot.t("Public"));
            public = true;
        }

        follow(username, public);
    }
    */

    /*
    function requestSwarmProgress() {
        twisterRpc("getlasthave", [defaultScreenName],
            function (args, ret) {
                processSwarmProgressPartial(ret);
            }, null,
            function (args, ret) {
                console.log("ajax error:" + ret);
            }, null);
    }
    */

    /*
    function processSwarmProgressPartial(lastHaves) {
        if (defaultScreenName in lastHaves) {
            incLastPostId(lastHaves[defaultScreenName]);
        }

        twisterRpc("getnumpieces", [defaultScreenName],
            function (args, ret) {
                processSwarmProgressFinal(args.lastHaves, ret);
            }, {
                lastHaves: lastHaves
            },
            function (args, ret) {
                console.log("ajax error:" + ret);
            }, null);
    }
    */

    /*
    function processSwarmProgressFinal(lastHaves, numPieces) {
        for (var user in lastHaves) {
            if (lastHaves.hasOwnProperty(user) && numPieces.hasOwnProperty(user)) {
                var $userDiv = $(".mini-profile-info[data-screen-name='" + user + "']");
                if ($userDiv.length) {
                    var $status = $userDiv.find(".swarm-status");
                    $status.text(polyglot.t("download_posts_status", {
                        portion: numPieces[user] + "/" + (lastHaves[user] + 1)
                    }));
                    $status.fadeIn();
                }
            }
        }
        window.setTimeout("requestSwarmProgress();", 2000);
    }
    */

    function followingChangedUser() {
        followingUsers = {};
        isFollowPublic = {};
        followingSeqNum = 0;
        followSuggestions = [];
        lastLoadFromDhtTime = 0;
    }

    /*
    function initInterfaceFollowing() {
        initInterfaceCommon();
        initUserSearch();
        initInterfaceDirectMsg();

        $("button.unfollow").bind("click", followingListUnfollow);
        $(".public-following").bind("click", followingListPublicCheckbox);

        $(".mentions-from-user").bind("click", openMentionsModal);

        initUser(function () {
            if (!defaultScreenName) {
                alert(polyglot.t("username_undefined"));
                $.MAL.goLogin();
                return;
            }
            checkNetworkStatusAndAskRedirect();

            $(".postboard-loading").fadeIn();
            loadFollowing(function (args) {
                showFollowingUsers();
                requestSwarmProgress();

                twisterFollowingO = TwisterFollowing(defaultScreenName);
            });
            initMentionsCount();
            initDMsCount();
        });
    }
    */
}(this, jQuery));