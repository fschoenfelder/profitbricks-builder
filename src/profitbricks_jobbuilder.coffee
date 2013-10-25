# Std library
fs = require 'fs'
# Third party
_ = require 'underscore'
async = require 'async'
debug = require('debug')('profitbricks-builder/profitbricks_jobbuilder')
# Local dep


## export ##

module.exports = (pbApi) ->
    new ProfitBricksJobBuilder(pbApi)

class ProfitBricksJobBuilder
    #default configurations
    CREATE_SERVER_DEFAULTS =
        cores: 1
        ram: 512,
        internetAccess: true

    CREATE_STORAGE_DEFAULTS =
        size: 50

    CREATE_CONNECTION_DEFAULTS =
        busType: 'VIRTIO'

    # default context keys
    DATACENTERS_CTX_KEY = 'datacenters'
    DATACENTER_CTX_KEY = 'datacenter'
    IMAGES_CTX_KEY = 'images'
    IMAGE_CTX_KEY = 'image'
    SERVERS_CTX_KEY = 'servers'
    SERVER_CTX_KEY = 'server'
    STORAGES_CTX_KEY = 'storages'
    STORAGE_CTX_KEY = 'storage'
    NICS_CTX_KEY = 'server.nics'
    NIC_CTX_KEY = 'nic'
    FIREWALL_CTX_KEY = 'firewall'

    constructor: (@pbApi, @jobs = []) ->

    logDescribeSoapClient: ->
        @jobs.push (ctx, cb) =>
            @pbApi.describe (err, result) =>
                debug "#{@pbApi.url} wsdl is: " +
                    "#{JSON.stringify(result, null, "\t")}"
                cb err, ctx
        return this


    getAllDataCenters: (dataCentersCtxKey = DATACENTERS_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            @pbApi.getAllDataCenters (err, datacenters) ->
                setContextInnerKey ctx, dataCentersCtxKey, datacenters
                cb err, ctx
        return this

    getDataCenterDetails: (id = null, dataCenterCtxKey = DATACENTER_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            if id?
                dcID = id
            else
                dcID = _firstItem getContextInnerKey(
                    ctx, dataCenterCtxKey).dataCenterId
            @pbApi.getDataCenter
                dataCenterId: dcID,
                (err, detailedDatacenter) ->
                    setContextInnerKey ctx,
                        dataCenterCtxKey,
                        detailedDatacenter
                    debug "datacenter found " +
                        "#{JSON.stringify(detailedDatacenter)}"
                    cb err, ctx
        return this


    deleteDataCenter: (id = null, dataCenterCtxKey = DATACENTER_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            if id?
                dcID = id
            else
                dcID = _firstItem getContextInnerKey(ctx,
                    dataCenterCtxKey).dataCenterId
            @pbApi.deleteDataCenter {dataCenterId: dcID}, (err) ->
                cb(err, ctx)
        return this

    deleteDataCenters: (dataCentersCtxKey = DATACENTERS_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            @pbApi.deleteDataCenters getContextInnerKey(ctx,
                dataCentersCtxKey),
                (err) ->
                    cb err, ctx
        return this


    createDataCenter: (dataCenterConfig,
        dataCenterCtxKey = DATACENTER_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            @pbApi.createDataCenter dataCenterConfig,
                (err, newDataCenter) ->
                    debug "datacenter created with err: #{err}, " +
                        "response: #{JSON.stringify(newDataCenter)}"
                    setContextInnerKey ctx,
                        dataCenterCtxKey,
                        overRideObject dataCenterConfig, newDataCenter
                    cb(err, ctx)
        return this


    createServer: (serverConfig, dataCenterCtxKey = DATACENTER_CTX_KEY,
        serverCtxKey = SERVER_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            config = overRideObject {}, CREATE_SERVER_DEFAULTS
            config = overRideObject config, serverConfig
            config.dataCenterId = _firstItem getContextInnerKey(ctx,
                dataCenterCtxKey).dataCenterId
            @pbApi.createServer config, (err, newServer) ->
                debug "server created with err: #{err}, " +
                    "response: #{JSON.stringify(newServer)}"
                setContextInnerKey ctx,
                    serverCtxKey,
                    overRideObject config, newServer
                cb err, ctx
        return this

    getServerDetails: (id = null, serverCtxKey = SERVER_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            if id?
                sID = id
            else
                sID = _firstItem getContextInnerKey(ctx,
                    serverCtxKey).serverId
            @pbApi.getServer {serverId: sID}, (err, detailedServer) ->
                setContextInnerKey ctx, serverCtxKey, detailedServer
                debug "server found #{JSON.stringify(detailedServer)}"
                cb err, ctx
        return this


    getAllImages: (imagesCtxKey = IMAGES_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            @pbApi.getAllImages (err, images) ->
                setContextInnerKey ctx, imagesCtxKey, images
                cb err, ctx
        return this


    createStorage: (storageConfig,
        dataCenterCtxKey = DATACENTER_CTX_KEY,
        imageCtxKey = IMAGE_CTX_KEY,
        storageCtxKey = STORAGE_CTX_KEY) ->

        @jobs.push (ctx, cb) =>
            config = overRideObject {}, CREATE_STORAGE_DEFAULTS
            config = overRideObject config, storageConfig
            config.dataCenterId = _firstItem getContextInnerKey(ctx,
                dataCenterCtxKey).dataCenterId
            config.mountImageId = _firstItem getContextInnerKey(ctx,
                imageCtxKey).imageId
            @pbApi.createStorage  config, (err, newStorage) ->
                debug "storrage created with err: #{err}, response: " +
                    "#{JSON.stringify(newStorage)}"
                setContextInnerKey ctx,
                    storageCtxKey,
                    overRideObject(config, newStorage)
                cb err, ctx
        return this

    connectStorageToServer: (connectionConfig,
        serverCtxKey = SERVER_CTX_KEY,
        storageCtxKey = STORAGE_CTX_KEY) ->
        
        @jobs.push (ctx, cb) =>
            config = overRideObject {}, CREATE_CONNECTION_DEFAULTS
            config = overRideObject config, connectionConfig
            config.storageId = _firstItem getContextInnerKey(ctx,
                storageCtxKey).storageId
            config.serverId = _firstItem getContextInnerKey(ctx,
                serverCtxKey).serverId
            @pbApi.connectStorageToServer config, (err) ->
                cb err, ctx
        return this


    deleteStorages: (storagesCtxKey = STORAGES_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            @pbApi.deleteStorages getContextInnerKey(ctx,
                storagesCtxKey),
                (err) ->
                    cb err, ctx
        return this

    addFirewallRulesToNic: (rules, nicCtxKey = NIC_CTX_KEY) ->
        for rule in rules
            do (rule) =>
                @jobs.push (ctx, cb) =>
                    @pbApi.addFirewallRuleToNic rule,
                        getContextInnerKey ctx, nicCtxKey,
                        (err, firewall) ->
                            setContextInnerKey ctx, FIREWALL_CTX_KEY, firewall
                            cb err, ctx
        return this

    activateFirewalls: ->
        @jobs.push (ctx, cb) =>
            firewallId = _firstItem getContextInnerKey(ctx,
                FIREWALL_CTX_KEY).firewallId
            @pbApi.activateFirewalls firewallId, (err) ->
                cb err, ctx
        return this

    filter: (patternObj, ctxKey, ctxListKey) ->
        @jobs.push (ctx, cb) =>
            @pbApi.filterItems getContextInnerKey(ctx, ctxListKey),
                patternObj,
                (err, filteredItems) ->
                    setContextInnerKey ctx, ctxKey, filteredItems
                    cb(err, ctx)
        return this

    filterStorages: (patternObj) ->
        return @filter patternObj,
            STORAGES_CTX_KEY,
            "#{DATACENTER_CTX_KEY}.storages"

    filterServers: (patternObj) ->
        return @filter patternObj,
            SERVERS_CTX_KEY,
            "#{DATACENTER_CTX_KEY}.servers"

    filterDataCenters: (patternObj) ->
        return @filter patternObj,
            DATACENTERS_CTX_KEY,
            "#{DATACENTERS_CTX_KEY}"


    selectOne: (patternObj, ctxKey, ctxListKey) ->
        @jobs.push (ctx, cb) =>
            @pbApi.filterItems getContextInnerKey(ctx, ctxListKey),
                patternObj,
                (err, filteredItems) ->
                    item = expectOne filteredItems
                    if not item?
                        cb "ERROR: expect one #{ctxKey} with pattern  " +
                            "#{JSON.stringify(patternObj)} but found " +
                            "#{filteredItems.length}"
                    else
                        debug "found one #{ctxKey} with values " +
                            "#{JSON.stringify(item)}"
                        setContextInnerKey(ctx, ctxKey, item)
                        cb err, ctx
        return this

    selectOneDataCenter: (patternObj) ->
        return @selectOne patternObj, DATACENTER_CTX_KEY, DATACENTERS_CTX_KEY

    selectOneServer: (patternObj) ->
        return @selectOne patternObj,
            SERVER_CTX_KEY,
            "#{DATACENTER_CTX_KEY}.servers"

    selectOneImage: (patternObj) ->
        return @selectOne patternObj, IMAGE_CTX_KEY, IMAGES_CTX_KEY

    selectOneNic: (patternObj) ->
        return @selectOne patternObj, NIC_CTX_KEY, NICS_CTX_KEY


    waitUntilDataCenterIsAvailable: (dataCenterCtxKey = DATACENTER_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            dcID = _firstItem getContextInnerKey(ctx,
                dataCenterCtxKey).dataCenterId
            @pbApi.waitUntilDataCenterIsAvailable {dataCenterId: dcID},
                (err) ->
                    cb err, ctx
        return this

    waitUntilDataCenterIsDead: (dcID = null,
        dataCenterCtxKey = DATACENTER_CTX_KEY) ->
        
        @jobs.push (ctx, cb) =>
            if not dcID?
                dcID = _firstItem getContextInnerKey(ctx,
                    dataCenterCtxKey)?.dataCenterId
            @pbApi.waitUntilDataCenterIsDead {dataCenterId: dcID}, (err) ->
                cb err, ctx
        return this


    waitUntilServerIsRunning: (serverCtxKey = SERVER_CTX_KEY) ->
        @jobs.push (ctx, cb) =>
            serverID = _firstItem getContextInnerKey(ctx,
                serverCtxKey).serverId
            @pbApi.waitUntilServerIsRunning {serverId: serverID}, (err) ->
                cb err, ctx
        return this

    log: (ctxKey) ->
        @jobs.push (ctx, cb) ->
            debug JSON.stringify getContextInnerKey(ctx, ctxKey), null, '\t'
            cb null, ctx
        return this


    execute: (cb) ->
        # reusing context is helpfull, in case of side effects just build a
        # new instance
        if not @ctx?
            @ctx = {}
        ctx = @ctx
        jobs = [
            (cb) ->
                cb null, ctx

        ].concat @jobs
        @jobs = [] # forget all jobs after execution
        async.waterfall jobs, (err, ctx) ->
            if(err?)
                debug "profitBricks jobs failed with error: #{err} and " +
                    "context: #{ctx}"
            else
                debug 'profitBricks jobs succeed'
            if _.isFunction cb
                cb err, ctx

    # public helper
    getContextItem: (key) ->
        getContextInnerKey @ctx, key

    getFirstContextItem: (key) ->
        _firstItem @getContextItem key

    getFirstDataCenterID: ->
        _firstItem _firstItem(@getContextItem 'datacenters')?.dataCenterId

    firstItem: (value) ->
        _firstItem value


## helpers ##
expectOne = (list) ->
    if list.length is 1 then list[0] else null

_firstItem = (value) ->
    if _.isArray value then value[0] else value

overRideObject = (obj, values) ->

    for key, value of values
        obj[key] = value if value?
    obj

getContextInnerKey = (ctx, innerKey) ->
    ctx = ctx[key] for key in innerKey.split '.' when ctx
    ctx

setContextInnerKey = (ctx, innerKey, value) ->
    keyList = innerKey.split '.'
    lastKey = keyList.splice -1
    for key in keyList
        if _.isObject ctx[key]
            ctx = ctx[key]
        else if not ctx[key]?
            ctx[key] = {}
            ctx = ctx[key]
        else
            ctx = null
    ctx?[lastKey] = value




