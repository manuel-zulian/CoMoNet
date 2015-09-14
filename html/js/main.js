/*globals $, angular*/
(function (globals) {
    'use strict';

    function comparePosts(postA, postB) {
        if (postA.userpost.time < postB.userpost.time) {
            return -1;
        } else {
            return 1;
        }
    }

    function compareMsgs(msgA, msgB) {
        if (msgA.time < msgB.time) {
            return -1;
        } else {
            return 1;
        }
    }

    var main = angular.module('main', ['ui.bootstrap', 'ngRoute']);

    main.config(['$routeProvider',
        function ($routeProvider) {
            $routeProvider
                .when('/', {
                    templateUrl: 'dashboard.html',
                    controller: 'DashboardController'
                })
                .when('/producer/:name', {
                    templateUrl: 'producer.html',
                    controller: 'ProducerController'
                })
                .when('/ordinazioni', {
                    templateUrl: 'ordinazioni.html',
                    controller: 'OrdinazioniController'
                })
                .otherwise({
                    redirectTo: '/'
                });
        }]);

    main.factory('main_state', function () {
        return {
            s: {
                current_user: undefined
            }
        };
    });

    main.factory('rpcQuery', function ($q, main_state) {
        return {
            dhtget: function (user, resource, type) {
                var deferred = $q.defer();
                globals.dhtget(user, resource, type, function (req, value, rawJson) {
                    var bulk = {req: req, value: value, rawJson: rawJson};
                    deferred.resolve(bulk);
                });
                return deferred.promise;
            },
            getposts: function (user) {
                var deferred = $q.defer();
                globals.getposts(user, function (req, posts) {
                    deferred.resolve(posts);
                });
                return deferred.promise;
            },
            getstructure: function () {
                var deferred = $q.defer();
                globals.getstructure(function (structure) {
                    deferred.resolve(structure);
                });
                return deferred.promise;
            }
        };
    });

    main.controller('MainController', function (main_state, $scope, $modal, rpcQuery) {
        /*var modalInstance = $modal.open({
            templateUrl: 'myModalContent.html',
            controller: 'ModalInstanceCtrl',
            backdrop: 'static',
            resolve: {
                items: function () {
                    return $scope.items;
                }
            }
        });*/
        if (main_state.s.current_user === undefined) {

/*            modalInstance.result.then(function (selectedItem) {
                main_state.s.current_user = selectedItem;
                $scope.$broadcast("userChanged");
            }, function () {
                // error occurred
                var error;
            });*/
        }


    });

    main.controller('ModalInstanceCtrl', function ($scope, $modalInstance, items) {
        $scope.items = ['utente1', 'utente2', 'utente3'];
        $scope.selected = {
            item: $scope.items[0]
        };

        $scope.ok = function () {
            $modalInstance.close($scope.selected.item);
        };
    });

    main.controller('NavigationController', function ($scope, main_state) {
        $scope.isAdmin = false;

        $scope.$on("userChanged", function () {
            // TODO: ovviamente questa è solo una simulazione bisogna controllare che sia admin sul serio
            if (main_state.s.current_user === 'utente1' || main_state.s.current_user === 'utente2') {
                $scope.isAdmin = true;
            } else {
                $scope.isAdmin = false;
            }
            $scope.current_user = main_state.s.current_user;
        });
    });

    main.controller('ProducerController', function ($scope, main_state, $routeParams, rpcQuery, $interval) {
        $scope.main_state = main_state.s;
        $scope.columnswidth = 3;

        var fillPosts = function (posts) {
                $scope.posts = [];
                posts.forEach(function(item){
                    var post = {};
                    var temp = item.userpost.msg.split("#");
                    var temp2 = temp[0].split(":");
                    post.text = temp2[1].replace("_", " ");
                    var temp3 = temp[1].split(":");
                    post.img = temp3[1].replace(/^"|"$/, "");
                    $scope.posts.push(post);
                });
                //$scope.posts = posts;
            },
            send = function (dmsg) {
                globals.dhtput($routeParams.name, "dmgs", "m", dmsg, main_state.s.current_user, 0);
            },
            reloadFeed = function () {
                rpcQuery.getposts($routeParams.name).then(fillPosts);
            },
            tick = function () {
                if (main_state.s.current_user !== undefined) {
                    globals.getlasthave(main_state.s.current_user, reloadFeed);
                } else {
                    // should ask for login
                    var no_operation;
                }
            };

        reloadFeed();
        $interval(tick, 1000);
    });

    main.controller('DashboardController', function ($scope, main_state, $routeParams, rpcQuery, $interval) {
        var fillProducers = function (bulk) {
            var producersArray = bulk.value;
            $scope.producers = producersArray;
        };

        rpcQuery.getstructure().then(function (structure) {
            $scope.rows = structure.rows;
            $scope.columnswidth = 12 / structure.columns;
            $scope.producers = structure.order;
        });
    });

    main.controller('OrdinazioniController', function ($scope, main_state, $interval, rpcQuery) {
        $scope.ordinazioni = [];
        $scope.main_state = main_state.s;
        var fillOrdinazioni = function (bulk) {
                var i,
                    rawJson = bulk.rawJson,
                    ordinazioni = [];
                for (i = 0; i < rawJson.length; i += 1) {
                    rawJson[i].p.author = rawJson[i].sig_user;
                    ordinazioni.push(rawJson[i].p);
                }
                ordinazioni.sort(compareMsgs);
                $scope.ordinazioni = ordinazioni;
            },
            tick = function () {
                if (main_state.s.current_user !== undefined) {
                    rpcQuery.dhtget(main_state.s.current_user, "dmgs", "m").then(fillOrdinazioni);
                } else {
                    // should ask for login
                    var no_operation;
                }
            };
        $interval(tick, 7000);
    });

}(this));