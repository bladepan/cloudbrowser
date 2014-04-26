// Generated by CoffeeScript 1.6.3
(function() {
  var app, appConfig, curVB;

  app = angular.module('CBLandingPage.controllers.app', ['CBLandingPage.services', 'CBLandingPage.models']);

  curVB = cloudbrowser.currentBrowser;

  appConfig = cloudbrowser.parentAppConfig;

  app.run(function($rootScope) {
    $rootScope.safeApply = function(fn) {
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
    $rootScope.error = {};
    return $rootScope.setError = function(error) {
      return this.error.message = error.message;
    };
  });

  app.controller('AppCtrl', [
    '$scope', 'cb-appInstanceManager', 'cb-format', function($scope, appInstanceMgr, format) {
      var addAppInstanceConfig, k, name, path, v, _ref;
      $scope.templates = {
        header: "header.html",
        initial: "initial.html",
        browserTable: "browser_table.html",
        appInstanceTable: "app_instance_table.html",
        forms: {
          addCollaborator: "forms/add_collaborator.html"
        },
        messages: {
          error: "messages/error.html",
          success: "messages/success.html",
          confirmDelete: "messages/confirm_delete.html"
        },
        buttons: {
          create: "buttons/create.html",
          filter: "buttons/filter.html",
          showLink: "buttons/show_link.html",
          addBrowser: "buttons/add_browser.html",
          expandCollapse: "buttons/expand_collapse.html",
          shareAppInstance: "buttons/share_app_instance.html",
          removeAppInstance: "buttons/remove_app_instance.html"
        }
      };
      _ref = $scope.templates;
      for (name in _ref) {
        path = _ref[name];
        if (typeof path === "string") {
          $scope.templates[name] = "" + __dirname + "/partials/" + path;
        } else {
          for (k in path) {
            v = path[k];
            path[k] = "" + __dirname + "/partials/" + v;
          }
        }
      }
      $scope.addBrowser = function(browserConfig, appInstanceConfig) {
        return browserConfig.getUserPrevilege(function(err, result) {
          var appInstance, browser;
          if (err != null) {
            return $scope.setError(err);
          }
          if (!result) {
            return;
          }
          appInstance = appInstanceMgr.add(appInstanceConfig);
          browser = appInstance.browserMgr.add(browserConfig);
          appInstance.showOptions = true;
          appInstance.processing = false;
          return $scope.safeApply(function() {});
        });
      };
      $scope.removeBrowser = function(browserID) {
        var appInstance, _i, _len, _ref1;
        _ref1 = appInstanceMgr.items;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          appInstance = _ref1[_i];
          appInstance.browserMgr.remove(browserID);
        }
        return $scope.safeApply(function() {});
      };
      $scope.removeAppInstance = function(appInstanceID) {
        return appInstanceMgr.remove(appInstanceID);
      };
      $scope.description = appConfig.getDescription();
      $scope.mountPoint = appConfig.getMountPoint();
      $scope.name = appConfig.getName();
      $scope.appInstances = appInstanceMgr.items;
      $scope.user = curVB.getCreator();
      $scope.appInstanceName = appConfig.getAppInstanceName();
      $scope.filter = {
        browsers: 'all',
        appInstances: 'all'
      };
      $scope.logout = function() {
        return cloudbrowser.auth.logout();
      };
      $scope.create = function() {
        return appConfig.createAppInstance(function(err, appInstanceConfig) {
          return $scope.safeApply(function() {
            if (err) {
              return $scope.setError(err);
            } else {
              return addAppInstanceConfig(appInstanceConfig);
            }
          });
        });
      };
      appConfig.addEventListener('addAppInstance', function(appInstanceConfig) {
        return $scope.safeApply(function() {
          return appInstanceMgr.add(appInstanceConfig);
        });
      });
      appConfig.addEventListener('shareAppInstance', function(appInstanceConfig) {
        return $scope.safeApply(function() {
          return appInstanceMgr.add(appInstanceConfig);
        });
      });
      appConfig.addEventListener('removeAppInstance', function(appInstanceID) {
        return $scope.safeApply(function() {
          return $scope.removeAppInstance(appInstanceID);
        });
      });
      addAppInstanceConfig = function(appInstanceConfig) {
        appInstanceMgr.add(appInstanceConfig);
        appInstanceConfig.addEventListener('addBrowser', function(browserConfig) {
          return $scope.addBrowser(browserConfig, appInstanceConfig);
        });
        appInstanceConfig.addEventListener('shareBrowser', function(browserConfig) {
          return $scope.addBrowser(browserConfig, appInstanceConfig);
        });
        appInstanceConfig.addEventListener('removeBrowser', function(id) {
          return $scope.removeBrowser(id, appInstanceConfig);
        });
        return appInstanceConfig.getAllBrowsers(function(err, browserConfigs) {
          var browserConfig, _i, _len, _results;
          if (err != null) {
            $scope.setError(err);
          }
          _results = [];
          for (_i = 0, _len = browserConfigs.length; _i < _len; _i++) {
            browserConfig = browserConfigs[_i];
            _results.push($scope.addBrowser(browserConfig, appInstanceConfig));
          }
          return _results;
        });
      };
      return appConfig.getAppInstances(function(err, appInstanceConfigs) {
        return $scope.safeApply(function() {
          var appInstanceConfig, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = appInstanceConfigs.length; _i < _len; _i++) {
            appInstanceConfig = appInstanceConfigs[_i];
            _results.push(addAppInstanceConfig(appInstanceConfig));
          }
          return _results;
        });
      });
    }
  ]);

}).call(this);
