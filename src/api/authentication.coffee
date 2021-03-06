Crypto                 = require("crypto")
Async                  = require("async")
cloudbrowserError      = require("../shared/cloudbrowser_error")
{LocalStrategy
, GoogleStrategy}      = require("./authentication_strategies")
{hashPassword
, getParentMountPoint} = require("./utils")

class Authentication

    constructor : (options) ->
        {bserver, cbCtx, app} = options
        localStrategy  = new LocalStrategy(app, bserver, cbCtx)
        googleStrategy = new GoogleStrategy(app, bserver)

        ###*
            Sends a password reset link to the user to the email
            registered with the application.
            @method sendResetLink
            @param {String} user
            @param {booleanCallback} callback
            @instance
            @memberOf Authentication
        ###
        @sendResetLink = (user, callback) ->
            if typeof user isnt "string"
                return callback?(cloudbrowserError('PARAM_MISSING', '- user'))

            appUrl = app.getAppUrl()
            token  = null

            Async.waterfall [
                (next) ->
                    app.findUser(user, next)
                (userRec, next) ->
                    if userRec then Crypto.randomBytes(32, next)
                    else next(cloudbrowserError('USER_NOT_REGISTERED'))
                (token, next) ->
                    token = token.toString('hex')
                    app.addResetMarkerToUser
                        user     : user
                        token    : token
                        callback : next
                (next) ->
                    esc_email = encodeURIComponent(user)
                    pwdResetLink = app.pwdRestApp.getAppUrl()+"?resettoken=#{token}&resetuser=#{esc_email}"

                    subject   = "Link to reset your CloudBrowser password"
                    message   = "You have requested to change your password."      +
                                " If you want to continue click <a href="          +
                                "\"#{pwdResetLink}\""    +
                                ">reset</a>. If you have"  +
                                " not requested a change in password then take no" +
                                " action."
                    cbCtx.util.sendEmail
                        to       : user
                        html     : message
                        subject  : subject
                        callback : next
            ], callback
            return

        # TODO : Add a configuration in app_config that allows only one user to connect to some
        # VB types at a time.
        ###*
            Resets the password.     
            A boolean is passed as an argument to indicate success/failure.
            @method resetPassword
            @param {String}          password The new plaintext password provided by the user.
            @param {booleanCallback} callback     
            @instance
            @memberOf Authentication
        ###
        @resetPassword = (password, callback) ->
            sessionManager = bserver.server.sessionManager
            session = null

            Async.waterfall [
                (next) ->
                    bserver.getFirstSession(next)
                (sess, next) ->
                    session = sess
                    hashPassword({password : password}, next)
                (result, next) ->
                    # Reset the key and salt for the corresponding user
                    app.resetUserPassword
                        email : sessionManager.findPropOnSession(session, 'resetuser')
                        token : sessionManager.findPropOnSession(session, 'resettoken')
                        salt  : result.salt.toString('hex')
                        key   : result.key.toString('hex')
                        callback : next
            ], callback
            return

        ###*
            Logs out all connected clients from the current application.
            @method logout
            @instance
            @memberOf Authentication
        ###
        @logout = () ->
            bserver.redirect("#{app.mountPoint}/logout")
            return

        ###*
            Returns an instance of local strategy for authentication
            @method getLocalStrategy
            @return {LocalStrategy} 
            @instance
            @memberOf Authentication
        ###
        @getLocalStrategy = () ->
            return localStrategy

        ###*
            Returns an instance of google strategy for authentication
            @method getGoogleStrategy
            @return {GoogleStrategy} 
            @instance
            @memberOf Authentication
        ###
        @getGoogleStrategy = () ->
            return googleStrategy

module.exports = Authentication
