(function() {
  var Chat3, Util;

  Chat3 = angular.module("Chat3", []);

  Util = require('util');

  Chat3.controller("ChatCtrl", function($scope) {
    var addRoom, chatManager, chatUser, findRoom, getLastActiveRoom, lastActiveRoom, room, _i, _j, _len, _len2, _ref, _ref2;
    $scope.joinedRooms = [];
    $scope.otherRooms = [];
    $scope.username = CloudBrowser.app.getCreator().getEmail();
    $scope.activeRoom = null;
    $scope.roomName = null;
    $scope.currentMessage = "";
    $scope.selectedRoom = null;
    $scope.showCreateForm = false;
    $scope.showJoinForm = false;
    lastActiveRoom = null;
    $scope.safeApply = function(fn) {
      var phase;
      phase = this.$root.$$phase;
      if (phase === '$apply' || phase === '$digest') {
        if (fn) return fn();
      } else {
        return this.$apply(fn);
      }
    };
    findRoom = function(name, roomList) {
      var room;
      room = $.grep(roomList, function(element, index) {
        return element.name === name;
      });
      if (room.length) {
        return room[0];
      } else {
        return null;
      }
    };
    addRoom = function(room, roomList, setupListeners) {
      if (!findRoom(room.name, roomList)) {
        $scope.safeApply(function() {
          return roomList.push(room);
        });
        if (setupListeners) {
          return room.on("NewMessage", function(message) {
            return $scope.safeApply(function() {
              return room.messages;
            });
          });
        }
      }
    };
    getLastActiveRoom = function() {
      if (lastActiveRoom) {
        return lastActiveRoom;
      } else if ($scope.joinedRooms.length) {
        return $scope.joinedRooms[$scope.joinedRooms.length - 1];
      } else {
        return null;
      }
    };
    chatManager = vt.shared.chats;
    chatManager.on("NewRoom", function(room) {
      return setTimeout(function() {
        if (!findRoom(room.name, $scope.joinedRooms)) {
          return $scope.safeApply(function() {
            return addRoom(room, $scope.otherRooms, false);
          });
        }
      }, 100);
    });
    _ref = chatManager.getAllRooms();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      room = _ref[_i];
      if (!findRoom(room.name, $scope.joinedRooms)) {
        addRoom(room, $scope.otherRooms, false);
      }
    }
    chatUser = vt.local.user;
    chatUser.setUserDetails(CloudBrowser.app.getCreator().toJson());
    chatUser.on("JoinedRoom", function(room) {
      addRoom(room, $scope.joinedRooms, true);
      $scope.safeApply(function() {
        return $scope.otherRooms = $.grep($scope.otherRooms, function(element, index) {
          return element.name !== room.name;
        });
      });
      return $scope.activate(room);
    });
    chatUser.on("LeftRoom", function(name) {
      $scope.safeApply(function() {
        return $scope.joinedRooms = $.grep($scope.joinedRooms, function(element, index) {
          return element.name !== name;
        });
      });
      addRoom(chatManager.getRoom(name), $scope.otherRooms, false);
      lastActiveRoom = null;
      return $scope.safeApply(function() {
        return $scope.activeRoom = getLastActiveRoom();
      });
    });
    _ref2 = chatUser.getAllRooms();
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      room = _ref2[_j];
      addRoom(room, $scope.joinedRooms, true);
      $scope.activate(room);
    }
    $scope.joinRoom = function() {
      chatManager.getRoom($scope.selectedRoom.name).join(chatUser);
      $scope.selectedRoom = null;
      return $scope.toggleForm('join');
    };
    $scope.leaveRoom = function(room) {
      return room.leave(chatUser);
    };
    $scope.createRoom = function() {
      room = chatManager.createRoom($scope.roomName);
      room.join(chatUser);
      $scope.roomName = null;
      $scope.activate(room);
      return $scope.toggleForm('create');
    };
    $scope.postMessage = function() {
      if ($scope.activeRoom) {
        $scope.activeRoom.postMessage($scope.username, $scope.currentMessage);
        return $scope.currentMessage = "";
      }
    };
    $scope.toggleForm = function(type) {
      if (type === "create") {
        return $scope.showCreateForm = !$scope.showCreateForm;
      } else if (type === "join") {
        return $scope.showJoinForm = !$scope.showJoinForm;
      }
    };
    return $scope.activate = function(room) {
      lastActiveRoom = $scope.activeRoom;
      return $scope.activeRoom = room;
    };
  });

  Chat3.directive('enterSubmit', function() {
    var directive;
    directive = {
      restrict: 'A',
      link: function(scope, element, attrs) {
        var submit;
        submit = false;
        return $(element).on({
          keydown: function(e) {
            submit = false;
            if (e.which === 13 && !e.shiftKey) {
              submit = true;
              return e.preventDefault();
            }
          },
          keyup: function() {
            if (submit) {
              scope.$eval(attrs.enterSubmit);
              return scope.$digest();
            }
          }
        });
      }
    };
    return directive;
  });

}).call(this);
