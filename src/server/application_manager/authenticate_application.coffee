Path = require('path')

lodash = require('lodash')
async = require('async')
routes = require('./routes')
BaseApplication = require('./base_application')
AppConfig = require('./app_config')

class AuthApp extends BaseApplication
    constructor: (masterApp, @parentApp) ->
        @baseMountPoint = @parentApp.mountPoint
        super(masterApp, @parentApp.server)
        @checkNotAuth = lodash.bind(@_checkNotAuth, this)
        @checkAuth = lodash.bind(@_checkAuth, this)
        @isAuthorized = lodash.bind(@_isAuthorized, this)
        @logoutHandler = lodash.bind(@_logoutHandler, this)
        @activateHandler = lodash.bind(@_activateHandler, this)
        @deactivateHandler = lodash.bind(@_deactivateHandler, this)


    mount : () ->
        # authorized user do not need to be authorized again
        @_mount(@mountPoint, @checkNotAuth,
            @mountPointHandler)
        @_mount(routes.concatRoute(@mountPoint,routes.browserRoute),
            @checkNotAuth,
            @serveVirtualBrowserHandler)
        @_mount(routes.concatRoute(@mountPoint, routes.resourceRoute),
            @checkNotAuth,
            @serveResourceHandler)
        @_mount(routes.concatRoute(@mountPoint, routes.componentRoute),
            @checkNotAuth,
            @serveComponentHandler)
        @mounted = true

    mountParent : () ->
        # authenticate root url
        @_mount(@baseMountPoint,
            @checkAuth,
            @parentApp.mountPointHandler
        )
        # authenticate virtual browser
        @_mount(routes.concatRoute(@baseMountPoint, routes.browserRoute),
            @checkAuth,
            @isAuthorized,
            @parentApp.serveVirtualBrowserHandler)
        @_mount(routes.concatRoute(@baseMountPoint, routes.resourceRoute),
            @checkAuth,
            @parentApp.serveResourceHandler)
        @_mount(routes.concatRoute(@baseMountPoint, routes.componentRoute),
            @checkAuth,
            @parentApp.serveComponentHandler)
        # handle logout, activate and deactivate
        @_mount(routes.concatRoute(@baseMountPoint, '/logout'),
            @logoutHandler)
        @_mount(routes.concatRoute(@baseMountPoint,'/activate/:token'),
            @activateHandler)
        @_mount(routes.concatRoute(@baseMountPoint, '/deactivate/:token'),
            @deactivateHandler)
        # handle appInstance requests
        @_mount(routes.concatRoute(@baseMountPoint,'/a/:appInstanceID'),
            @parentApp.serveAppInstanceHandler)


    _logoutHandler : (req, res, next) ->
        @sessionManager.terminateAppSession(req.session, @baseMountPoint)
        routes.redirect(res, @baseMountPoint)

    _setDefaultUser : (req)->
        # authentication disabled
        if not @parentApp.isAuthConfigured() and not @sessionManager.findAppUserID(req.session, @baseMountPoint)
            @sessionManager.addAppUserID(req.session, @baseMountPoint, @server.config.defaultUser)

    _checkAuth : (req, res, next) ->
        @_setDefaultUser(req)
        if @sessionManager.findAppUserID(req.session, @baseMountPoint)
            next()
        else
            if req.params.browserID? and not req.params.resourceID?
                # Setting the url to be redirected to after successful
                # authentication
                @sessionManager.setPropOnSession(req.session, 'redirectto', req.url)
            routes.redirect(res, @mountPoint)

    # Middleware to reroute authenticated users when they request for
    # the authentication_interface
    _checkNotAuth : (req, res, next) ->
        @_setDefaultUser(req)
        # If user is already logged in then redirect to application
        if not @sessionManager.findAppUserID(req.session, @baseMountPoint)
            next()
        else routes.redirect(res, @baseMountPoint)

    # Middleware that authorizes access to browsers
    _isAuthorized : (req, res, next) ->
        @_setDefaultUser(req)
        user = @sessionManager.findAppUserID(req.session, @baseMountPoint)
        appInstanceID = req.params.appInstanceID
        appInstance = @parentApp.appInstanceManager.find(appInstanceID)
        browserID = req.params.browserID
        if appInstance? and browserID?
            browser = appInstance.findBrowser(browserID)
            if browser.getUserPrevilege?(user)?
                return next()

        if appInstance?.getUserPrevilege(user)?
            return next()
        else
            res.send('Permission Denied', 403)

    _activateHandler: (req, res, next) ->
        @parentApp.activateUser req.params.token, (err) =>
            if err then res.send(err.message, 400)
            else res.render('activate.jade', {url : @mountPoint})

    _deactivateHandler: (req, res, next) ->
        @parentApp.deactivateUser(req.params.token, () ->
            res.render('deactivate.jade'))

    isAuthApp : () ->
        return true

module.exports = AuthApp




