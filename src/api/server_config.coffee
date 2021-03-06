AppConfig = require('./application_config')
Async     = require('async')
cloudbrowserError   = require('../shared/cloudbrowser_error')

# Permission checks are included wherever possible and a note is made if
# missing. Details like name, id, url etc. are available to everybody.

###*
    API for server config instance (internal class).
    @class ServerConfig
    @param {Object}         options 
    @param {User}           options.userCtx The current user.
    @param {Cloudbrowser}   options.cbCtx   The cloudbrowser API object.
###
class ServerConfig
    constructor : (options) ->
        {cbServer, userCtx, cbCtx} = options

        ###*
            Returns the server domain.
            @method getDomain
            @return {String}
            @instance
            @memberOf ServerConfig
        ###
        @getDomain = () ->
            return cbServer.config.domain

        ###*
            Returns the server port
            @method getPort
            @return {Number}
            @instance
            @memberOf ServerConfig
        ###
        @getPort = () ->
            return cbServer.config.port

        ###*
            Returns the URL at which the CloudBrowser server is hosted.    
            @method getUrl
            @return {String} 
            @instance
            @memberOf ServerConfig
        ###
        @getUrl = () ->
            {domain, port} = cbServer.config
            return "http://#{domain}:#{port}"

        ###*
            Returns the list of apps mounted on CloudBrowser
            Can be filtered by user or privacy
            @method listApps
            @param {Object} options
            @param {appListCallback} options.callback
            @param {Array<String>} options.filters
            @return {Array<appObject>} 
            @instance
            @memberOf ServerConfig
        ###
        @listApps = (filters, callback)->
            if typeof callback isnt "function" then return
            if not filters instanceof Array
                callback(cloudbrowserError("PARAM_INVALID", "- filter"))
            
            permissionManager = cbServer.permissionManager
            appManager = cbServer.applicationManager
            appConfigs = []

            # Apps that the current user owns
            if filters.indexOf('perUser') isnt -1
                console.log "listApps for email #{JSON.stringify(userCtx)}"
                permissionManager.getAppPermRecs
                    user        : userCtx
                    permission  : 'own'
                    callback    : (err, appRecs) ->
                        return callback(err) if err
                        if appRecs?
                            for rec in appRecs
                                # TODO this should change to async call as well
                                app = appManager.find(rec.getMountPoint())
                                if filters.indexOf('public') isnt -1
                                    if not app.isAppPublic() then continue
                                if not app?
                                    console.log "empty app for #{rec.getMountPoint()}"
                                else
                                    appConfigs.push new AppConfig
                                        cbServer : cbServer
                                        userCtx : userCtx
                                        cbCtx   : cbCtx
                                        app     : app
                        callback(null, appConfigs)
            # Get all public apps
            else if filters.indexOf('public') isnt -1
                apps = appManager.get()
                for mountPoint, app of apps
                    if app.isAppPublic() and app.isMounted()
                        appConfigs.push new AppConfig
                            cbServer : cbServer
                            userCtx : userCtx
                            cbCtx   : cbCtx
                            app     : app
                # Callback for uniformity
                callback(null, appConfigs)

        ###*
            Registers a listener for an event on the server
            @method addEventListener
            @param {String} event
            @param {serverConfigEventCallback} callback
            @instance
            @memberOf ServerConfig
        ###
        @addEventListener = (event, callback) ->
            permissionManager = cbServer.permissionManager
            appManager = cbServer.applicationManager

            validEvents = [
                'mount'
                'disable'
                'madePublic'
                'madePrivate'
                'addApp'
                'removeApp'
            ]

            if typeof callback isnt "function" then return
            if validEvents.indexOf(event) is -1 then return
            listener = null
            switch event
                when "madePublic", "mount", "addApp"
                    listener =  (app) ->
                        callback new AppConfig
                            cbServer : cbServer
                            userCtx : userCtx
                            cbCtx   : cbCtx
                            app     : app
                when "madePrivate", "disable", "removeApp"
                    listener = (app) ->
                        callback(app.getMountPoint())

            if listener?
                cbCtx.addEventListener(appManager, event, listener)

        ###*
            Takes the gzipped tarball and loads it into the server
            as a cloudbrowser application
            @method addEventListener
            @param {String} buffer
            @param {appConfigCallback} callback
            @instance
            @memberOf ServerConfig
        ###
        @uploadAndCreateApp = (buffer, callback) ->
            appManager = cbServer.applicationManager
            appManager.uploadAppConfig(buffer, callback)
            return

module.exports = ServerConfig
