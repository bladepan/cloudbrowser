Mongo      = require('mongodb')
Express    = require('express')
Async      = require('async')
MongoStore = require('connect-mongo')(Express)

# TODO : Use Mongoose

class DatabaseInterface
    #dbConfig is of type config.DatabaseConfig
    constructor : (dbConfig, callback) ->
        @appCollection = 'applications'
        @adminCollection  = 'admin_interface.users'
        # Ensures unique database for every user of the system
        # but will use the same database for multiple instances
        # of cloudbrowser run by the same user
        dbName = "UID#{process.getuid()}-#{dbConfig.dbName}"
        @dbClient = new Mongo.Db(dbName,
            new Mongo.Server("127.0.0.1", 27017, options:{auto_reconnect:true}))
        Async.series([
                        (next) =>
                            @dbClient.open (err, pClient) ->
                                next(err)
                        ,
                        (next) =>
                            @mongoStore = new MongoStore(
                                {db:"#{dbName}_sessions"}, 
                                (collection) ->
                                    next(null)
                                )

                    ], 
                    (err, results) =>
                        callback(err, this)
        )
        
    findAdminUser : (searchKey,callback) ->
        @findUser(searchKey,@adminCollection,callback)

    addAdminUser : (users,callback) ->
        @addUser(users,@adminCollection,callback)

    findUser : (searchKey, collectionName, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(collectionName, next)
            (collection, next) ->
                collection.findOne(searchKey, next)
        ], callback

    addUser : (users, collectionName, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(collectionName, next)
            (collection, next) ->
                collection.insert(users, next)
        ], (err, userRecs) ->
            if err then callback(err)
            # If an array of users was provided to be added
            # return the array of records added
            if users instanceof Array then callback(null, userRecs)
            else callback(null, userRecs[0])

    getUsers : (collectionName, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(collectionName, next)
            (collection, next) ->
                collection.find({}, next)
            (cursor, next) ->
                cursor.toArray(next)
        ], callback

    updateUser : (searchKey, collectionName, newObj, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(collectionName, next)
            (collection, next) ->
                collection.update(searchKey, newObj, {w:1}, next)
        ], callback

    removeFromUser : (searchKey, collectionName, removedInfo, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(collectionName, next)
            (collection, next) ->
                collection.update(searchKey, {$pull:removedInfo}, {w:1}, next)
        ], callback

    setUser : (searchKey, collectionName, updatedInfo, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(collectionName, next)
            (collection, next) ->
                collection.update(searchKey, {$set:updatedInfo}, {w:1, upsert:true}, next)
        ], callback

    unsetUser : (searchKey, collectionName, updatedInfo, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(collectionName, next)
            (collection, next) ->
                collection.update(searchKey, {$unset:updatedInfo}, {w:1}, next)
        ], callback

    removeUser : (searchKey, collectionName, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(collectionName, next)
            (collection, next) ->
                collection.remove(searchKey, next)
        ], callback

    getSession : (sessionID, callback) ->
        @mongoStore.get(sessionID, callback)

    setSession : (sessionID, session, callback) ->
        @mongoStore.set(sessionID, session, callback)

    findApp : (searchKey, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(@appCollection, next)
            (collection, next) ->
                collection.findOne(searchKey, next)
        ], callback

    addApp : (app, callback) ->
        Async.waterfall [
            (next) =>
                @findApp(app, next)
            (appRec, next) =>
                # Bypass the waterfall
                if appRec then callback(null, appRec)
                else @dbClient.collection(@appCollection, next)
            (collection, next) ->
                collection.insert(app, next)
        ], callback

    setApp : (searchKey, updatedInfo, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(@appCollection, next)
            (collection, next) ->
                collection.update(searchKey, {$set:updatedInfo}, {w:1, upsert:true}, next)
        ], callback

    removeApp : (searchKey, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(@appCollection, next)
            (collection, next) ->
                collection.remove(searchKey, next)
        ], callback

    getApps : (callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(@appCollection, next)
            (collection, next) ->
                collection.find({}, next)
            (cursor, next) ->
                cursor.toArray(next)
        ], callback

    addIndex : (collectionName, index, callback) ->
        Async.waterfall [
            (next) =>
                @dbClient.collection(collectionName, next)
            (collection, next) ->
                collection.ensureIndex(index, {unique:true}, next)
        ], callback

module.exports = DatabaseInterface
