// Generated by CoffeeScript 1.6.3
(function() {
  var AUTH_FAIL, CBAuthentication, EMAIL_EMPTY, EMAIL_INVALID, EMAIL_IN_USE, EMAIL_RE, PASSWORD_EMPTY, RESET_SUCCESS, appConfig, auth, curBrowser, googleStrategy, localStrategy;

  CBAuthentication = angular.module("CBAuthentication", []);

  curBrowser = cloudbrowser.currentBrowser;

  auth = cloudbrowser.auth;

  appConfig = cloudbrowser.parentAppConfig;

  googleStrategy = auth.getGoogleStrategy();

  localStrategy = auth.getLocalStrategy();

  AUTH_FAIL = "Invalid credentials";

  EMAIL_EMPTY = "Please provide the Email ID";

  EMAIL_IN_USE = "Account with this Email ID already exists";

  EMAIL_INVALID = "Please provide a valid email ID";

  RESET_SUCCESS = "A password reset link has been sent to your email ID";

  PASSWORD_EMPTY = "Please provide the password";

  EMAIL_RE = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/;

  CBAuthentication.controller("LoginCtrl", function($scope) {
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
    $scope.email = null;
    $scope.password = null;
    $scope.emailError = null;
    $scope.passwordError = null;
    $scope.loginError = null;
    $scope.resetSuccessMsg = null;
    $scope.isDisabled = false;
    $scope.showEmailButton = false;
    $scope.$watch("email + password", function() {
      $scope.loginError = null;
      $scope.isDisabled = false;
      return $scope.resetSuccessMsg = null;
    });
    $scope.$watch("email", function() {
      return $scope.emailError = null;
    });
    $scope.$watch("password", function() {
      return $scope.passwordError = null;
    });
    $scope.googleLogin = function() {
      return googleStrategy.login();
    };
    $scope.login = function() {
      if (!$scope.email) {
        return $scope.emailError = EMAIL_EMPTY;
      } else if (!$scope.password) {
        return $scope.passwordError = PASSWORD_EMPTY;
      } else {
        $scope.isDisabled = true;
        return localStrategy.login({
          emailID: $scope.email,
          password: $scope.password,
          callback: function(err, success) {
            return $scope.safeApply(function() {
              if (err) {
                $scope.loginError = err.message;
              } else if (!success) {
                $scope.loginError = AUTH_FAIL;
              }
              return $scope.isDisabled = false;
            });
          }
        });
      }
    };
    return $scope.sendResetLink = function() {
      if (!($scope.email && EMAIL_RE.test($scope.email.toUpperCase()))) {
        return $scope.emailError = EMAIL_INVALID;
      } else {
        $scope.resetDisabled = true;
        return auth.sendResetLink($scope.email, function(err, success) {
          return $scope.safeApply(function() {
            if (err) {
              $scope.emailError = err.message;
            } else {
              $scope.resetSuccessMsg = RESET_SUCCESS;
            }
            return $scope.resetDisabled = false;
          });
        });
      }
    };
  });

  CBAuthentication.controller("SignupCtrl", function($scope) {
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
    $scope.email = null;
    $scope.password = null;
    $scope.vpassword = null;
    $scope.emailError = null;
    $scope.signupError = null;
    $scope.passwordError = null;
    $scope.successMessage = false;
    $scope.isDisabled = false;
    $scope.$watch("email", function(nval, oval) {
      $scope.emailError = null;
      $scope.signupError = null;
      $scope.isDisabled = false;
      $scope.successMessage = false;
      return appConfig.isLocalUser($scope.email, function(err, exists) {
        return $scope.safeApply(function() {
          if (err) {
            return ($scope.emailError = err.message);
          } else if (!exists) {
            return;
          }
          $scope.emailError = EMAIL_IN_USE;
          return $scope.isDisabled = true;
        });
      });
    });
    $scope.$watch("password+vpassword", function() {
      if (!$scope.emailError) {
        $scope.isDisabled = false;
      }
      $scope.signupError = null;
      return $scope.passwordError = null;
    });
    return $scope.signup = function() {
      $scope.isDisabled = true;
      if (!($scope.email && EMAIL_RE.test($scope.email.toUpperCase()))) {
        return $scope.emailError = EMAIL_INVALID;
      } else if (!$scope.password) {
        return $scope.passwordError = PASSWORD_EMPTY;
      } else {
        return localStrategy.signup({
          emailID: $scope.email,
          password: $scope.password,
          callback: function(err) {
            return $scope.safeApply(function() {
              if (err) {
                return $scope.signupError = err.message;
              } else {
                return $scope.successMessage = true;
              }
            });
          }
        });
      }
    };
  });

}).call(this);
