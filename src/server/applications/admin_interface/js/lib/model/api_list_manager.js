// Generated by CoffeeScript 1.8.0
(function() {
  var APIListManager, EventEmitter,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('events').EventEmitter;

  APIListManager = (function(_super) {
    __extends(APIListManager, _super);

    function APIListManager(TypeOfItems, format, idProperty, idMethod) {
      this.TypeOfItems = TypeOfItems;
      this.format = format;
      this.idProperty = idProperty != null ? idProperty : 'id';
      this.idMethod = idMethod != null ? idMethod : 'getID';
      this.items = [];
      this.removed = [];
      this.setMaxListeners(500);
    }

    APIListManager.prototype.find = function(id) {
      var item, _i, _len, _ref;
      _ref = this.items;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (item[this.idProperty] === id) {
          return item;
        }
      }
    };

    APIListManager.prototype.add = function(itemConfig) {
      var item;
      item = this.find(itemConfig[this.idMethod]());
      if (!item) {
        item = new this.TypeOfItems(itemConfig, this.format);
        this.items.push(item);
      }
      return item;
    };

    APIListManager.prototype.remove = function(item) {
      var idx;
      if (typeof item === "string") {
        item = this.find(item);
      }
      idx = this.items.indexOf(item);
      if (idx !== -1) {
        return this.items.splice(idx, 1)[0];
      } else {
        return null;
      }
    };

    return APIListManager;

  })(EventEmitter);

  this.APIListManager = APIListManager;

}).call(this);
