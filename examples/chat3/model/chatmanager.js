// Generated by CoffeeScript 1.6.3
(function() {
  var ChatManager, ChatRoom, EventEmitter, User,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ChatRoom = require('./chatroom');

  User = require('./user');

  EventEmitter = require('events').EventEmitter;

  ChatManager = (function(_super) {
    __extends(ChatManager, _super);

    function ChatManager(rooms, users) {
      this.rooms = [];
      this.users = [];
      if (rooms) {
        this.loadRooms(rooms);
      }
      if (users) {
        this.loadUsers(users);
      }
    }

    ChatManager.prototype.loadRooms = function(rooms) {
      var room, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = rooms.length; _i < _len; _i++) {
        room = rooms[_i];
        _results.push(this.createRoom(room.name, room.messages));
      }
      return _results;
    };

    ChatManager.prototype.loadUsers = function(users) {
      var chatUser, roomName, user, _i, _j, _len, _len1, _ref, _results;
      _results = [];
      for (_i = 0, _len = users.length; _i < _len; _i++) {
        user = users[_i];
        chatUser = this.addUser(user.name);
        _ref = user.otherRooms;
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          roomName = _ref[_j];
          chatUser.addToOtherRooms(this.findRoom(roomName));
        }
        chatUser.roomsToBeJoined = user.joinedRooms;
        _results.push(chatUser.activateRoom(this.findRoom(user.currentRoom)));
      }
      return _results;
    };

    ChatManager.prototype.findUser = function(userName) {
      var user, _i, _len, _ref;
      _ref = this.users;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        user = _ref[_i];
        if (user.getName() === userName) {
          return user;
        }
      }
    };

    ChatManager.prototype.addUser = function(userName, eventHandler) {
      var room, roomName, user, _i, _j, _len, _len1, _ref, _ref1;
      user = this.findUser(userName);
      if (!user) {
        user = new User(userName, eventHandler);
        _ref = this.getRooms();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          room = _ref[_i];
          user.addToOtherRooms(room);
        }
        this.users.push(user);
      } else {
        user.setEventHandler(eventHandler);
        if (user.roomsToBeJoined != null) {
          _ref1 = user.roomsToBeJoined;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            roomName = _ref1[_j];
            this.addUserToRoom(user, this.findRoom(roomName));
          }
        }
      }
      return user;
    };

    ChatManager.prototype.findRoom = function(roomName) {
      var room, _i, _len, _ref;
      _ref = this.rooms;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        room = _ref[_i];
        if (room.getName() === roomName) {
          return room;
        }
      }
    };

    ChatManager.prototype.createRoom = function(name, messages) {
      var room;
      room = this.findRoom(name);
      if (!room) {
        room = new ChatRoom(name, messages);
        this.rooms.push(room);
      }
      return [null, room];
    };

    ChatManager.prototype.addUserToRoom = function(user, room) {
      user.join(room);
      return room.add(user);
    };

    ChatManager.prototype.removeUserFromRoom = function(user, room) {
      user.leave(room);
      return room.remove(user);
    };

    ChatManager.prototype.getRooms = function() {
      return this.rooms;
    };

    ChatManager.prototype.removeRoom = function(room) {
      var idx;
      idx = this.rooms.indexOf(room);
      if (idx !== -1) {
        room.close();
        return this.rooms.splice(room, 1);
      }
    };

    ChatManager.prototype.getSerializableInfo = function() {
      var room, rooms, user, users, _i, _j, _len, _len1, _ref, _ref1;
      rooms = [];
      users = [];
      _ref = this.rooms;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        room = _ref[_i];
        rooms.push(room.getSerializableInfo());
      }
      _ref1 = this.users;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        user = _ref1[_j];
        users.push(user.getSerializableInfo());
      }
      return {
        rooms: rooms,
        users: users
      };
    };

    return ChatManager;

  })(EventEmitter);

  module.exports = ChatManager;

}).call(this);
