var EventEmitter = require('events').EventEmitter,
    ko           = require('vt-node-lib').ko;

function ChatRoom (name) {
    this.name = name;
    this.users = ko.observableArray();
    this.messages = ko.observableArray();
    this.messages().toString = function () {
        return this.join('\n');
    };
}

ChatRoom.prototype = {
    postMessage : function (username, message) {
        this.emit('newMessage', username, message);
        this.messages.push('[' + username + '] ' + message);
    },

    join : function (user) {
        this.users.push(user);
    },

    leave : function (user) {
        this.users.remove(user);
    }
};
ChatRoom.prototype.__proto__ = new EventEmitter();

module.exports = ChatRoom;
