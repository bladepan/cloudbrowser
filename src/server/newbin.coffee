Server              = require('./index')
FS                  = require('fs')
Util                = require('util')

serverConfig = {}

if FS.existsSync "server_config.json"
    serverConfig = JSON.parse FS.readFileSync "server_config.json"

Opts = require('nomnom')
    .option 'deployment',
        flag    : true
        help    : "Start the server in deployment mode"
    .option 'debug',
        flag    : true
        help    : "Show the configuration parameters."
    .option 'noLogs',
        full    : 'disable-logging'
        flag    : true
        help    : "Disable all logging to files."
    .option 'debugServer',
        full    : 'debug-server'
        flag    : true
        help    : "Enable the debug server."
    .option 'compression',
        help    : "Enable protocol compression."
    .option 'compressJS',
        full : 'compress-js'
        help : "Pass socket.io and client engine through uglify and gzip."
    .option 'knockout',
        flag    : true
        help    : "Enable server-side knockout.js bindings."
    .option 'strict',
        flag    : true
        help    : "Enable strict mode - uncaught exceptions exit the program."
    .option 'resourceProxy',
        full    : 'resource-proxy'
        help    : "Enable ResourceProxy."
    .option 'monitorTraffic',
        full    : 'monitor-traffic'
        help    : "Monitor/log traffic to/from socket.io clients."
    .option 'traceProtocol',
        full    : 'trace-protocol'
        help    : "Log protocol messages to browserid-rpc.log."
    .option 'multiProcess',
        full    : 'multi-process'
        help    : "Run each browser in its own process (can't be used with shared global state)."
    .option 'useRouter',
        full    : 'router'
        help    : "Use a front-end router process with each app server in its own process."
    .option 'port',
        help    : "Starting port to use."
    .option 'traceMem',
        full    : 'trace-mem'
        flag    : true
        help    : "Trace memory usage."
    .option 'adminInterface',
        full    : 'admin-interface'
        help    : "Enable the admin interface."
    .option 'simulateLatency',
        full    : 'simulate-latency'
        help    : "Simulate latency for clients in ms (if not given assign uniform randomly in 20-120 ms range."
    .parse()

for own k,v of Opts
    serverConfig[k] = v

if serverConfig.deployment
    console.log "Server started in deployment mode"
else
    paths = []
    #List of all the unmatched positional args (the path names)
    for item in Opts._
        paths.push item
    server = new Server(serverConfig, paths)
    server.once 'ready', ->
        console.log 'Server started in local mode'
