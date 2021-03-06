###
enter script of master module
###

path           = require('path')
async          = require('async')
config         = require('./config')

#require('webkit-devtools-agent').start()

require('ofe').call()
require('../server/profiler')

class Runner
    constructor: (argv, postConstruct) ->
        async.auto({
            'config' : (callback) ->
                config.newMasterConfig(argv, callback)
            ,
            'database' : ['config', (callback, results)->
                DBInterface = require('../server/database_interface')
                new DBInterface(results.config.databaseConfig, callback)
            ],
            'permissionManager' :['database', (callback, results)->
                PermissionManager  = require('../server/permission_manager')
                new PermissionManager(results.database,callback)
            ],
            'loadUserConfig' : ['database', (callback, results)->
                results.config.loadUserConfig(results.database, callback)
            ],
            'uuidService' : ['loadUserConfig', (callback, results)->
                UuidService = require('../server/uuid_service')
                new UuidService(results, callback)
            ],
            'workerManager' : ['loadUserConfig', 'rmiService',
                                (callback,results) ->
                                    require('./worker_manager')(results,callback)

            ],
            'appManager' : [ 'permissionManager','workerManager', 'uuidService', 
                            (callback, results) ->
                                require('./app_manager')(results,callback)

            ],
            'proxyServer' : ['loadUserConfig','workerManager',
                            (callback, results) ->
                                if results.config.enableProxy
                                    console.log 'Proxy enabled.'
                                    require('./http_proxy')(results, callback)
                                else
                                    callback null,null                                
            ],
            'rmiService' : ['loadUserConfig',
                            (callback, results) =>
                                RmiService = require('../server/rmi_service')
                                new RmiService(results.config, callback)
            ]
            },(err, results) ->
                if err?
                    console.log('Initialization error, exiting....')
                    console.log(err)
                    console.log(err.stack)
                    if postConstruct?
                        postConstruct err
                    else
                        process.exit(1)
                else
                    rmiService = results.rmiService
                    rmiService.registerObject('workerManager', results.workerManager)
                    rmiService.registerObject('config', results.config)
                    rmiService.registerObject('appManager', results.appManager)
                    console.log 'Master started......'
                    if postConstruct?
                        postConstruct null
                    # notify parent process if it is a child process
                    process.send?({type : 'ready'})
                    process.on 'uncaughtException', (err) ->
                        console.log("Master Node Uncaught Exception")
                        console.log(err)
                        console.log(err.stack)
                    # monitoring resource usage
                    require('../server/sys_mon').createSysMon({
                        id : 'master'
                        interval : 5000
                        printTime : true
                    })
        )
            
if require.main is module
    new Runner(null)


module.exports = Runner

