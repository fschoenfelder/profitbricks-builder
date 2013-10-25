# Std library
# Third party
async = require 'async'
debug = require('debug') 'profitbricks-builder/profitbricks_api'
{_} = require 'underscore'

# Local dep
SoapClient = require './soapclient'

class ProfitBricksApi

    WAIT_CYCLE = 10000
    constructor: ->
        @url = null
        @soapClient = null

    init: (url, user, pwd, callback) ->
        @url = url
        @soapClient = SoapClient.newBasicAuth url, user, pwd
        @soapClient.init (err) ->
            if err?
                debug "soapClient initialized with error '#{err}'"
            else
                debug 'soapClient initialized'
            callback err


    describe: (callback) ->
        callback null, @soapClient.describe()


    getAllDataCenters: (callback) ->
        @soapClient.invoke 'getAllDataCenters', {}, (err, results) ->
            if results?.return?.length > 0
                debug "found #{results.return.length} datacenter(s)"
                callback err, results.return
            else
                debug 'no datacenters found'
                callback err, []


    getDataCenter: (config, callback) ->
        @soapClient.invoke 'getDataCenter',
            dataCenterId: config.dataCenterId,
            (err, result) ->
                # debug "getDataCenter returned with error: #{err}, " +
                # "result: #{result?.return?[0]}"
                callback err, result?.return?[0]

    deleteDataCenter: (dataCenter, callback) ->
        debug "about to delete dataCenter " +
            "'#{firstItem(dataCenter.dataCenterName)}' with id " +
            "'#{firstItem(dataCenter.dataCenterId)}'"
        @soapClient.invoke 'deleteDataCenter',
            dataCenterId: firstItem dataCenter.dataCenterId,
            (err, result) ->
                debug "dataCenter deleted " +
                    "'#{firstItem(dataCenter.dataCenterName)}' with id " +
                    "'#{firstItem(dataCenter.dataCenterId)}', error: #{err}," +
                    " result: #{result}"
            callback err, result?.return?[0]


    deleteDataCenters: (dataCenters, callback) ->
        async.each dataCenters, (dataCenter, fcallback) =>
            @deleteDataCenter dataCenter, (err) ->
                if err? then callback err else fcallback()
        , callback


    createDataCenter: (config, callback) ->
        debug "about to create datacenter #{JSON.stringify(config)}"
        @soapClient.invoke 'createDataCenter', config, (err, result) ->
            # debug "getDataCenter returned with error: #{err}, " +
            # "result: #{result?.return?[0]}"
            callback err, result?.return?[0]

    getAllImages: (callback) ->
        @soapClient.invoke 'getAllImages', {}, (err, results) ->
            debug "found #{results?.return?.length} images"
            if results?.return?.length > 0
                callback err, results.return
            else
                callback err, []


    getStorage: (storage, callback) ->
        @soapClient.invoke 'getStorage',
            storageId: storage.storageId,
            (err, result) ->
                debug "getStorage returned with error: #{err}, " +
                    "result: #{result?.return?[0]}"
                callback err, result?.return?[0]


    createStorage: (storageConfig, callback) ->
        debug "about to create storage storageConfig " +
            "#{JSON.stringify(storageConfig)}"
        @soapClient.invoke 'createStorage',
            request: storageConfig,
            (err, result) ->
                storage = result?.return?[0]
                debug "create storage returned with error: #{err}, " +
                    "result: #{JSON.stringify(storage)}"
                callback err, storage


    connectStorageToServer: (config, callback) ->
        config.busType = if config.busType then config.busType.toUpperCase()
        debug "about to connect storage #{JSON.stringify(config)}"
        @soapClient.invoke 'connectStorageToServer',
            request: config,
            (err, result) ->
                debug "storage connected with id #{config.storageId}, " +
                    "error: #{err}, result: #{JSON.stringify(result)}"
            callback err

    disconnectStorages: (server, objPattern, callback) ->
        connectedStorages = wrapList server.connectedStorages
        storagesToDisconnect = filterItemsSync connectedStorages, objPattern
        debug "found #{storagesToDisconnect.length} connected storage to " +
            "disconnect"

        async.filter storagesToDisconnect, (storage, fcallback) =>
            debug "about to disconnect storage '#{storage.storageName}' with" +
                " id #{storage.storageId}"
            @soapClient.invoke 'disconnectStorageFromServer',
                storageId : storage.storageId
                serverId : server.serverId,
                (err, result) ->
                    debug "storage disconnected '#{storage.storageName}' " +
                        "with id #{storage.storageId}, error: #{err}, " +
                        "result: #{result}"
                    fcallback true
        , (results) ->  callback null, results


    deleteStorages: (storages, callback) ->
        async.each storages, (storage, fcallback) =>
            debug "about to delete storage '#{storage.storageName}' with " +
                "id #{storage.storageId}"
            @soapClient.invoke 'deleteStorage',
                storageId: storage.storageId,
                (err, result) ->
                    debug "storage deleted '#{storage.storageName}' with " +
                        "id #{storage.storageId}, error: #{err}, " +
                        "result: #{result}"
                    if err? then callback err else fcallback()
        , callback


    getServer: (server, callback) ->
        @soapClient.invoke 'getServer',
            serverId: server.serverId,
            (err, result) ->
                callback err, result?.return?[0]


    createServer: (serverConfig, callback) ->
        debug "about to create server with config " +
            "#{JSON.stringify(serverConfig)}"
        @soapClient.invoke 'createServer',
            request: serverConfig,
            (err, result) ->
                server = result?.return?[0]
                debug "create server returned with error: #{err}, " +
                    "result: #{JSON.stringify(server)}"
                callback err, server

    deleteServers: (servers, callback) ->
        async.each servers, (server, fcallback) =>
            debug "about to delete server '#{server.serverName}' with " +
                "id #{server.serverId}"
            @soapClient.invoke 'deleteServer',
                serverId: server.serverId,
                (err, result) ->
                    debug "server deleted '#{server.serverName}' with id: " +
                        "'#{server.serverId}', err: '#{err}'"
                    if err? then callback err else fcallback()
        , callback

    addFirewallRuleToNic: (rule, nic, callback) ->
        @soapClient.invoke 'addFirewallRulesToNic',
            request: rule
            nicId: nic.nicId,
            (err, result) ->
                nic = result?.return?[0]
                callback err, nic

    activateFirewalls: (firewallId, callback) ->
        @soapClient.invoke 'activateFirewalls',
            firewallIds: firewallId,
            (err) ->
                callback err

    rebootServer: (server, callback) ->
        debug "about to reboot server #{server.serverName}, #{server.serverId}"
        @getServer server, (err, result) =>
            if result.provisioningState is 'AVAILABLE' and
                    result.virtualMachineState is 'RUNNING'
                @soapClient.invoke 'rebootServer',
                    serverId : server.serverId,
                    (err, result) ->
                        debug "rebooted server #{server.serverName}, error: " +
                            "#{err}, result: #{JSON.stringify(result)}"
                        callback err
            else
                callback "server is not in the mood for a reboot: " +
                    "#{JSON.stringify(result)}"

    waitUntilDataCenterIsAvailable: (dataCenter, callback) ->
        test = (fcallback) =>
            @getDataCenter dataCenter, (err, dcItem) ->
                # debug "datecenter is #{JSON.stringify(dcItem)}"
                debug "wait until dataCenter #{dcItem.dataCenterName} is " +
                    "AVAILABLE, currentstate is #{dcItem.provisioningState}," +
                    " id is #{dcItem.dataCenterId}"
                if dcItem.provisioningState is 'AVAILABLE'
                    fcallback 'ready'
                else
                    setTimeout fcallback, WAIT_CYCLE

        forever test, (msg) -> callback null, msg

    waitUntilDataCenterIsDead: (dataCenter, callback) ->
        test = (fcallback) =>
            @getDataCenter dataCenter, (err, dcItem) ->
                # debug "datacenter is #{JSON.stringify(dcItem)}"
                debug "wait until dataCenter " +
                    "#{dcItem?.dataCenterId or dataCenter?.dataCenterId} " +
                    "is DEAD"
                if err?
                    fcallback 'ready'
                else
                    setTimeout fcallback, WAIT_CYCLE

        forever test, (msg) -> callback null, msg

    waitUntilServerIsRunning: (server, callback) ->
        test = (fcallback) =>
            @getServer server, (err, serverItem) ->
                return fcallback err if err?

                debug "wait until server #{serverItem.serverName} is RUNNING" +
                    ", currentstate is #{serverItem.virtualMachineState}, id" +
                    " is #{serverItem.serverId}"
                if serverItem.virtualMachineState is 'RUNNING'
                    fcallback 'ready'
                else
                    setTimeout fcallback, WAIT_CYCLE

        forever test, (msg) -> callback null, msg

    filterItems: (objList, objPattern, callback) ->
        callback null, filterItemsSync(objList, objPattern)

filterItemsSync = (objList, objPattern) ->
    list = wrapList objList
    foundItems = _.filter list, (item) ->
        _.every objPattern, (pattern, key) ->
            value = if item[key] instanceof Array then item[key][0]
            else item[key]
            return value is pattern

    debug "#{foundItems.length} item(s) found that match pattern: " +
        "#{JSON.stringify(objPattern)}"
    return foundItems


wrapList = (list) ->
    if _.isArray list
        return list
    else if list?
        return [list]
    else
        return []

forever = (fn, callback) ->
    next = (err) ->
        if err then callback err else fn next
    next()

firstItem = (value) ->
    if _.isArray(value) then value[0] else value

module.exports = ->
    new ProfitBricksApi()