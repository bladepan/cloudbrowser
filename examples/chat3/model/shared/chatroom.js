// Generated by CoffeeScript 1.6.3
(function() {
  var ChatRoom, EventEmitter,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  ChatRoom = (function(_super) {
    __extends(ChatRoom, _super);

    function ChatRoom(name) {
      this.name = name;
      this.users = [];
      this.messages = [];
    }

    ChatRoom.prototype.postMessage = function(user, message) {
      var formattedMessage;
      formattedMessage = "[" + (user.getName()) + "]: " + message;
      this.messages.push(formattedMessage);
      return this.emit('newMessage', message);
    };

    ChatRoom.prototype.add = function(user) {
      return this.users.push(user);
    };

    ChatRoom.prototype.remove = function(user) {
      var idx;
      idx = this.users.indexOf(user);
      if (idx !== -1) {
        return this.users.splice(idx, 1);
      }
    };

    ChatRoom.prototype.getMessages = function() {
      return this.messages;
    };

    ChatRoom.prototype.getUsers = function() {
      return this.users;
    };

    return ChatRoom;

  })(EventEmitter);

  module.exports = ChatRoom;

}).call(this);
