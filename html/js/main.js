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
                    templateUrl: 'producers.html',
                    controller: 'ProducersController'
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
            s : {
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
            }
        };
    });
    
    main.controller('MainController', ['main_state', '$scope', '$modal', function (main_state, $scope, $modal) {
        var modalInstance = $modal.open({
                templateUrl: 'myModalContent.html',
                controller: 'ModalInstanceCtrl',
                backdrop: 'static',
                resolve: {
                    items: function () {
                        return $scope.items;
                    }
                }
            });
        if (main_state.s.current_user === undefined) {
            
            modalInstance.result.then(function (selectedItem) {
                main_state.s.current_user = selectedItem;
                $scope.$broadcast("userChanged");
            }, function () {
                // error occurred
                var error;
            });
        }
        
        
        
    }]);
    
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
        });
    });
    
    main.controller('ProducersController', function ($scope, rpcQuery) {
        var fillProducers = function (bulk) {
            var producersArray = bulk.value;
            $scope.producers = producersArray;
        };
        rpcQuery.dhtget("utente1", "home", "s").then(fillProducers);
    });
    
    main.controller('ProducerController', function ($scope, main_state, $routeParams, rpcQuery, $interval) {
        $scope.main_state = main_state.s;
        
        var fillPosts = function (posts) {
            $scope.posts = posts;
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
        $scope.buy = function (text) {
            send(text);
        };
    });
    
    main.controller('FeedController', function ($scope, main_state, $interval, rpcQuery) {
        $scope.main_state = main_state.s;
        var addMiniPost = function (posts) {
            $scope.main_state.miniposts = $scope.main_state.miniposts.concat(posts);
            $scope.main_state.miniposts.sort(comparePosts);
        },
            reloadFeed = function () {
                var i;
                for (i = 0; i < main_state.s.following.length; i += 1) {
                    rpcQuery.getposts(main_state.s.following[i]).then(addMiniPost);
                }
                while (main_state.s.miniposts.length) {
                    main_state.s.miniposts.pop();
                }
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
        $scope.$watch($scope.main_state.following, reloadFeed);
        $interval(tick, 1000);
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