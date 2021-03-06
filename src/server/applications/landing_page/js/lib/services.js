// Generated by CoffeeScript 1.8.0
(function() {
  var helpers;

  helpers = angular.module('CBLandingPage.services', []);

  helpers.service('cb-mail', function() {
    var s;
    s = {
      send: function(options) {
        var callback, from, mountPoint, msg, sharedObj, sub, to, url;
        from = options.from, to = options.to, sharedObj = options.sharedObj, url = options.url, mountPoint = options.mountPoint, callback = options.callback;
        sub = "CloudBrowser - " + from + " shared " + sharedObj + " with you.";
        msg = ("Hi " + to + "<br>To view it, visit <a href='" + url + "'>") + ("" + mountPoint + "</a> and login to your existing account") + " or use your google ID to login if you do not have an" + " account already.";
        return cloudbrowser.util.sendEmail({
          to: to,
          html: msg,
          subject: sub,
          callback: callback
        });
      }
    };
    return s;
  });

  helpers.service('cb-format', function() {
    var months;
    months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return this.date = function(date) {
      var day, month, year;
      if (!date instanceof Date) {
        return null;
      }
      month = months[date.getMonth()];
      day = date.getDate();
      year = date.getFullYear();

      /*
      hours       = date.getHours()
      timeSuffix  = if hours < 12 then 'am' else 'pm'
      hours       = hours % 12
      hours       = if hours then hours else 12
      minutes     = date.getMinutes()
      minutes     = if minutes > 10 then minutes else '0' + minutes
      time        = hours + ":" + minutes + " " + timeSuffix
      date        = day + " " + month + " " + year + " (" + time + ")"
       */
      date = day + " " + month + " " + year;
      return date;
    };
  });

}).call(this);
