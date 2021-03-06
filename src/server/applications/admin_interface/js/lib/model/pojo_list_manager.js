// Generated by CoffeeScript 1.8.0
(function() {
  var POJOListManager,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  POJOListManager = (function(_super) {
    __extends(POJOListManager, _super);

    function POJOListManager(TypeofItems, idProperty) {
      this.TypeofItems = TypeofItems;
      this.idProperty = idProperty != null ? idProperty : 'id';
      this.items = [];
    }

    POJOListManager.prototype.add = function(item) {
      var listItem;
      if (typeof this.TypeofItems === "function") {
        listItem = this.find(item);
        if (!listItem) {
          listItem = new this.TypeofItems(item);
          this.items.push(listItem);
        }
      } else {
        listItem = this.find(item[this.idProperty]);
        if (!listItem) {
          listItem = item;
          this.items.push(listItem);
        }
      }
      return listItem;
    };

    return POJOListManager;

  })(APIListManager);

  this.POJOListManager = POJOListManager;

}).call(this);
