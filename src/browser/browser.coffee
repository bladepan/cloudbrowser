assert         = require('assert')
path           = require('path')
URL            = require('url')
TestClient     = require('./test_client')
DOM            = require('../dom')
ResourceProxy  = require('./resource_proxy')
EventProcessor = require('./event_processor')
EventEmitter   = require('events').EventEmitter
ClientAPI      = require('./client_api')

class Browser extends EventEmitter
    constructor : (browserID, url) ->
        @id = browserID
        @window = null
        @resources = null
        @dom = new DOM(this)
        @events = new EventProcessor(this)
        # These are the RPC functions we expose to clients over Socket.IO.
        @clientAPI = new ClientAPI(this)

        # The DOM can emit 'pagechange' when Location is set and we need to
        # load a new page.
        @dom.on('pagechange', (url) => @load(url))
        # Array of clients waiting for page to load.
        @connQ = []
        # Array of currently connected DNode clients.
        @clients = []
        @load(url) if url?

    close : () ->
        for client in @clients
            client.disconnect()

    # Note: this function returns before the page is loaded.  Listen on the
    # window's load event if you need to.
    load : (url) ->
        console.log "Loading: #{url}"
        @pauseClientUpdates()
        @window.close if @window?
        @resources = new ResourceProxy(url)
        @window = @dom.createWindow()
        # TODO TODO: also need to not process client events from now until the
        # new page loads.
        @window.location = url
        # We know the event won't fire until a later tick since it has to make
        # an http request.
        @window.addEventListener 'load', () =>
            @resumeClientUpdates()
            @emit('load')
            process.nextTick(() => @emit('afterload'))

    pauseClientUpdates : () ->
        @dom.removeAllListeners('DOMUpdate')
        @dom.removeAllListeners('DOMPropertyUpdate')
        @dom.removeAllListeners('tagDocument')
        @events.removeAllListeners('addEventListener')

    resumeClientUpdates : () ->
        @syncAllClients()
        # Each advice function emits the DOMUpdate or DOMPropertyUpdate 
        # event, which we want to echo to all connected clients.
        @dom.on 'DOMUpdate', (params) =>
            @broadcastUpdate('DOMUpdate', params)
        @dom.on 'DOMPropertyUpdate', (params) =>
            @broadcastUpdate('DOMPropertyUpdate', params)
        @dom.on 'tagDocument', (params) =>
            @broadcastUpdate('tagDocument', params)
        @events.on 'addEventListener', (params) =>
            @broadcastUpdate('addEventListener', params)

    syncAllClients : () ->
        if @clients.length == 0 && @connQ.length == 0
            return
        @clients = @clients.concat(@connQ)
        @connQ = []
        snapshot =
            nodes : @dom.getSnapshot()
            events : @events.getSnapshot()
        for client in @clients
            client.emit('loadFromSnapshot', snapshot)

    # method - either 'DOMUpdate' or 'DOMPropertyUpdate'.
    # params - the scrubbed params object.
    broadcastUpdate : (method, params) =>
        for client in @clients
            client.emit(method, params)

    addClient : (client) ->
        # Sets up mapping between client events and our RPC API methods.
        @clientAPI.initClient(client)
        if !@window.document? || @window.document.readyState == 'loading'
            @connQ.push(client)
            return
        snapshot =
            nodes : @dom.getSnapshot()
            events : @events.getSnapshot()
        client.emit('loadFromSnapshot', snapshot)
        @clients.push(client)

    removeClient : (client) ->
        @clients = (c for c in @clients when c != client)

    # For testing purposes, return an emulated client for this browser.
    createTestClient : () ->
        if !process.env.TESTS_RUNNING
            throw new Error('Called createTestClient but not running tests.')
        return new TestClient(@id, @dom)

    # When TESTS_RUNNING, clients expose a testDone method via DNode.
    # testDone triggers the client to emit 'testDone' on its TestClient,
    # which the unit tests listen to to know that they can begin probing
    # the client DOM.
    testDone : () ->
        for client in @clients
            client.emit('testDone')

module.exports = Browser
