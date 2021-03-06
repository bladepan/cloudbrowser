// Generated by CoffeeScript 1.6.3
(function() {
  var CBHomePage;

  CBHomePage = angular.module("CBHomePage", []);

  CBHomePage.controller("MainCtrl", function($scope) {
    var App, currentBrowser, server;
    server = cloudbrowser.serverConfig;
    currentBrowser = cloudbrowser.currentBrowser;
    $scope.safeApply = function(fn) {
      var phase;
      phase = this.$root.$$phase;
      if (phase === '$apply' || phase === '$digest') {
        if (fn) {
          return fn();
        }
      } else {
        return this.$apply(fn);
      }
    };
    $scope.leftClick = function(url) {
      return currentBrowser.redirect(url);
    };
    $scope.apps = [];
    App = (function() {
      function App() {}

      App.add = function(appConfig) {
        var app, _i, _len, _ref;
        _ref = $scope.apps;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          app = _ref[_i];
          if (app.api.getMountPoint() === appConfig.getMountPoint()) {
            return;
          }
        }
        app = {
          api: appConfig,
          url: appConfig.getUrl(),
          name: appConfig.getName(),
          mountPoint: appConfig.getMountPoint(),
          description: appConfig.getDescription()
        };
        return $scope.apps.push(app);
      };

      App.remove = function(mountPoint) {
        var app, idx, _i, _len, _ref;
        _ref = $scope.apps;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          app = _ref[_i];
          if (!(app.api.getMountPoint() === mountPoint)) {
            continue;
          }
          idx = $scope.apps.indexOf(app);
          return $scope.apps.splice(idx, 1);
        }
      };

      return App;

    })();
    server.listApps(['public'], function(err, apps) {
      if (err) {
        return $scope.safeApply(function() {
          return $scope.error = err.message;
        });
      } else {
        return $scope.safeApply(function() {
          var app, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = apps.length; _i < _len; _i++) {
            app = apps[_i];
            _results.push(App.add(app));
          }
          return _results;
        });
      }
    });
    server.addEventListener('madePublic', function(appConfig) {
      return $scope.safeApply(function() {
        return App.add(appConfig);
      });
    });
    server.addEventListener('addApp', function(appConfig) {
      return $scope.safeApply(function() {
        return App.add(appConfig);
      });
    });
    server.addEventListener('mount', function(appConfig) {
      return $scope.safeApply(function() {
        return App.add(appConfig);
      });
    });
    server.addEventListener('madePrivate', function(mountPoint) {
      return $scope.safeApply(function() {
        return App.remove(mountPoint);
      });
    });
    server.addEventListener('removeApp', function(mountPoint) {
      return $scope.safeApply(function() {
        return App.remove(mountPoint);
      });
    });
    return server.addEventListener('disable', function(mountPoint) {
      return $scope.safeApply(function() {
        return App.remove(mountPoint);
      });
    });
  });

}).call(this);
