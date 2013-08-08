async = require 'async'
{_} = require 'underscore'

debug = require('debug')('profitbricks-builder')

SoapClient = require('./soapclient')

class ProfitBricksApi

    WAIT_CYCLE = 10000

    constructor: () ->
        @url = null
        @soapClient = null


    init: (url, user, pwd, cb) ->
        @url = url
        @soapClient = SoapClient.newBasicAuth(url, user, pwd)
        @soapClient.init (err) ->
            if err?
                debug "soapClient initialized with error '#{err}'"
            else
                debug "soapClient initialized"
            cb(err)


    describe: (cb) ->
        cb(null, @soapClient.describe())


    getAllDataCenters: (cb) ->
        @soapClient.invoke "getAllDataCenters", {}, (err, results) ->
            if results?.return?.length > 0
                debug "found #{results.return.length} datacenter(s)"
                cb(err, results.return)
            else
                debug "no datacenters found"
                cb(err, [])


    getDataCenter: (config, cb) ->
        @soapClient.invoke "getDataCenter", {dataCenterId: config.dataCenterId}, (err, result) ->
            # debug "getDataCenter returned with error: #{err}, result: #{result?.return?[0]}"
            cb(err, result?.return?[0])


    deleteDataCenter: (dataCenter, cb) ->
        debug "about to delete dataCenter '#{firstItem(dataCenter.dataCenterName)}' with id '#{firstItem(dataCenter.dataCenterId)}'"
        @soapClient.invoke "deleteDataCenter", {dataCenterId: firstItem(dataCenter.dataCenterId)}, (err, result) ->
            debug "dataCenter deleted '#{firstItem(dataCenter.dataCenterName)}' with id '#{firstItem(dataCenter.dataCenterId)}', error: #{err}, result: #{result}"
            cb(err, result?.return?[0])


    deleteDataCenters: (dataCenters, cb) ->
        async.each(dataCenters, (dataCenter, fcb) =>
            @deleteDataCenter dataCenter, (err) ->
                if err?
                    cb(err)
                else
                    fcb()
        , cb)


    createDataCenter: (config, cb) ->
        debug "about to create datacenter #{JSON.stringify(config)}"
        @soapClient.invoke "createDataCenter", config, (err, result) ->
            # debug "getDataCenter returned with error: #{err}, result: #{result?.return?[0]}"
            cb(err, result?.return?[0])


    getAllImages: (cb) ->
        @soapClient.invoke "getAllImages", {}, (err, results) ->
            debug "found #{results?.return?.length} images"
            if results?.return?.length > 0
                cb(err, results.return)
            else
                cb(err, [])


    getStorage: (storage, cb) ->
        @soapClient.invoke "getStorage", {storageId: storage.storageId}, (err, result) ->
            debug "getStorage returned with error: #{err}, result: #{result?.return?[0]}"
            cb(err, result?.return?[0])


    createStorage: (storageConfig, cb) ->
        debug "about to create storage storageConfig #{JSON.stringify(storageConfig)}"
        @soapClient.invoke "createStorage", {arg0: storageConfig}, (err, result) ->
            storage = result?.return?[0]
            debug "create storage returned with error: #{err}, result: #{JSON.stringify(storage)}"
            cb(err, storage)


    connectStorageToServer: (config, cb) ->
        config.busType = if config.busType then config.busType.toUpperCase()
        debug "about to connect storage #{JSON.stringify(config)}"
        @soapClient.invoke "connectStorageToServer", {arg0: config}, (err, result) ->
            debug "storage connected with id #{config.storageId}, error: #{err}, result: #{JSON.stringify(result)}"
            cb(err)


    disconnectStorages: (server, objPattern, cb) ->
        connectedStorages = wrapList(server.connectedStorages)
        storagesToDisconnect = filterItemsSync(connectedStorages, objPattern)
        debug "found #{storagesToDisconnect.length} connected storage to disconnect"

        async.filter(storagesToDisconnect, (storage, fcb) =>
            debug "about to disconnect storage '#{storage.storageName}' with id #{storage.storageId}"
            @soapClient.invoke "disconnectStorageFromServer", {storageId : storage.storageId, serverId : server.serverId}, (err, result) ->
                debug "storage disconnected '#{storage.storageName}' with id #{storage.storageId}, error: #{err}, result: #{result}"
                fcb(true)
        , (results) ->  cb(null, results))


    deleteStorages: (storages, cb) ->
        async.each(storages, (storage, fcb) =>
            debug "about to delete storage '#{storage.storageName}' with id #{storage.storageId}"
            @soapClient.invoke "deleteStorage", {storageId: storage.storageId}, (err, result) ->
                debug "storage deleted '#{storage.storageName}' with id #{storage.storageId}, error: #{err}, result: #{result}"
                if err?
                    cb(err)
                else
                    fcb()
        , cb)


    getServer: (server, cb) ->
        @soapClient.invoke "getServer", {serverId: server.serverId}, (err, result) ->
            cb(err, result?.return?[0])


    createServer: (serverConfig, cb) ->
        debug "about to create server with config #{JSON.stringify(serverConfig)}"
        @soapClient.invoke "createServer", {arg0: serverConfig}, (err, result) ->
            server = result?.return?[0]
            debug "create server returned with error: #{err}, result: #{JSON.stringify(server)}"
            cb(err, server)


    deleteServers: (servers, cb) ->
        async.each(servers, (server, fcb) =>
            debug "about to delete server '#{server.serverName}' with id #{server.serverId}"
            @soapClient.invoke "deleteServer", {serverId: server.serverId}, (err, result) ->
                debug "server deleted '#{server.serverName}' with id: '#{server.serverId}', err: '#{err}'"
                if err?
                    cb(err)
                else
                    fcb()
        , cb)



    addFirewallRuleToNic: (rule, nic, cb) ->
        @soapClient.invoke "addFirewallRulesToNic", {request: rule, nicId: nic.nicId}, (err, result) ->
            nic = result?.return?[0]
            cb(err, nic)


    activateFirewalls: (firewallId, cb) ->
        @soapClient.invoke "activateFirewalls",  {firewallIds: firewallId}, (err) ->
            cb(err)


    rebootServer: (server, cb) ->
        debug "about to reboot server #{server.serverName}, #{server.serverId}"
        @getServer server, (err, result) =>
            if result.provisioningState is "AVAILABLE" and result.virtualMachineState is "RUNNING"
                @soapClient.invoke "rebootServer", {serverId : server.serverId}, (err, result) ->
                    debug "rebooted server #{server.serverName}, error: #{err}, result: #{JSON.stringify(result)}"
                    cb(err)
            else
                cb("server is not in the mood for a reboot: #{JSON.stringify(result)}")


    waitUntilDataCenterIsAvailable: (dataCenter, cb) ->
        test = (fcb) =>
            @getDataCenter dataCenter, (err, dcItem) ->
                # debug "datecenter is #{JSON.stringify(dcItem)}"
                debug "wait until dataCenter #{dcItem.dataCenterName} is AVAILABLE, currentstate is #{dcItem.provisioningState}, id is #{dcItem.dataCenterId}"
                if dcItem.provisioningState is "AVAILABLE"
                    fcb("ready")
                else
                    setTimeout(fcb, WAIT_CYCLE)

        forever(test, (msg) -> cb(null, msg))


    waitUntilDataCenterIsDead: (dataCenter, cb) ->
        test = (fcb) =>
            @getDataCenter dataCenter, (err, dcItem) ->
                # debug "datacenter is #{JSON.stringify(dcItem)}"
                debug "wait until dataCenter #{dcItem?.dataCenterId} is DEAD"
                if err?
                    fcb("ready")
                else
                    setTimeout(fcb, WAIT_CYCLE)

        forever(test, (msg) -> cb(null, msg))


    waitUntilServerIsRunning: (server, cb) ->
        test = (fcb) =>
            @getServer server, (err, serverItem) ->
                if err?
                    fcb(err)
                    return

                debug "wait until server #{serverItem.serverName} is RUNNING, currentstate is #{serverItem.virtualMachineState}, id is #{serverItem.serverId}"
                if serverItem.virtualMachineState is "RUNNING"
                    fcb("ready")
                else
                    setTimeout(fcb, WAIT_CYCLE)

        forever(test, (msg) -> cb(null, msg))



    filterItems: (objList, objPattern, cb) ->
        cb(null, filterItemsSync(objList, objPattern))



filterItemsSync = (objList, objPattern) ->
    list = wrapList(objList)
    foundItems = _.filter list, (item) ->
        _.every objPattern, (pattern, key) ->
            value = if (item[key] instanceof Array) then item[key][0] else item[key]
            value is pattern

    debug "#{foundItems.length} item(s) found that match pattern: #{JSON.stringify(objPattern)}"
    foundItems


wrapList = (list) ->
    if _.isArray(list)
        return list
    else if list?
        return [list]
    else
        return []


forever = (fn, callback) ->
    next = (err) ->
        if (err)
            return callback(err)
        else
            fn(next)
    next();


firstItem = (value) ->
    if _.isArray(value)
        value[0]
    else
        value


module.exports = ->
    new ProfitBricksApi()