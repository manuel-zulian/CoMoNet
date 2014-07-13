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
                .otherwise({
                    redirectTo: '/'
                });
        }]);
    
    main.factory('main_state', function () {
        return {
            s : {
                current_user: undefined,
                following: [],
                producers: [],
                posts: [],
                miniposts: [],
                minimsgs: []
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
        $scope.main_state = main_state.s;
    });
    
    main.controller('ProducersController', function ($scope, rpcQuery) {
        var fillProducers = function (bulk) {
            var producersArray = bulk.value;
            $scope.producers = producersArray;
        };
        rpcQuery.dhtget("utente1", "home", "s").then(fillProducers);
    });
    
    main.controller('ProducerController', function ($scope, main_state, $routeParams, rpcQuery) {
        $scope.main_state = main_state.s;
        
        var fillPosts = function (posts) {
            $scope.main_state.posts = posts;
        },
            send = function (dmsg) {
                globals.dhtput($routeParams.name, "dmgs", "m", $scope.dmsg, main_state.s.current_user, 0);
            },
            isFollowing = function () {
                return (main_state.s.following.indexOf($routeParams.name) > -1);
            },
            follow = function () {
                $scope.main_state.following.push($routeParams.name);
                // reloadFeed(); TODO: add $watch in feedcontroller
            },
            unfollow = function () {
                var index;
                index = main_state.s.following.indexOf($routeParams.name);
                if (index > -1) {
                    $scope.main_state.following.splice(index, 1);
                }
                // reloadFeed(); TODO: add $watch in feedcontroller
            };
        
        rpcQuery.getposts($routeParams.name).then(fillPosts);
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
    
    main.controller('MessagesController', function ($scope, main_state, $interval, rpcQuery) {
        $scope.main_state = main_state.s;
        var addMiniMsgs = function (bulk) {
            var i,
                rawJson = bulk.rawJson;
            if (rawJson.length !== main_state.s.minimsgs.length) {
                while (main_state.s.minimsgs.length) {
                    main_state.s.minimsgs.pop();
                }
                for (i = 0; i < rawJson.length; i += 1) {
                    rawJson[i].p.author = rawJson[i].sig_user;
                    $scope.main_state.minimsgs.push(rawJson[i].p);
                }
                $scope.main_state.minimsgs.sort(compareMsgs);
            }
        },
            tick = function () {
                if (main_state.s.current_user !== undefined) {
                    rpcQuery.dhtget(main_state.s.current_user, "dmgs", "m").then(addMiniMsgs);
                } else {
                // should ask for login
                    var no_operation;
                }
            };
        $interval(tick, 7000);
    });
    
}(this));