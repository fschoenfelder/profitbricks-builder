debug = require('debug')('profitbricks-builder/examples')

profitBricksJobBuilder = require '../src/profitbricks_jobbuilder'
profitBricksApi = require '../src/profitbricks_api'

helper = require './sample_helper'

createDataCenterWithServer = ->
    debug "createDataCenterWithServer"
    helper.getPBBuilder (pbBuilder) ->
        dcName = 'dc_test01'
        serverName = 'server_test01'
        debug "about to create datacenter '#{dcName}' with one server '#{serverName}'"
        pbBuilder
            .createDataCenter({dataCenterName: dcName})
            .createServer({serverName: serverName, 'cores': "1", 'ram': "256", 'lanId': 1, 'internetAccess': true})
            .waitUntilDataCenterIsAvailable()
            .waitUntilServerIsRunning()
            .execute (err, ctx) ->
                if err?
                    debug "datacenter create failed: #{err}"
                else
                    debug "datacenter create succeed"
                debug "context is: #{helper.beautify(ctx)}"

createDataCenterWithServerStorageAndFirewallRules = ->
    debug "createDataCenterWithServerStorageAndFirewallRules"
    helper.getPBBuilder (pbBuilder) ->
        dcName = 'dc_test01'
        serverName = 'server_test01'
        storageName = 'storage_test01'
        debug "about to create datacenter '#{dcName}' with one server '#{serverName}'"
        pbBuilder
            .createDataCenter({dataCenterName: dcName})
            .createServer({serverName: serverName, 'cores': "1", 'ram': "256", 'lanId': 1, 'internetAccess': true})
            .waitUntilDataCenterIsAvailable()
            .getDataCenterDetails()
            .selectOneServer({serverName: serverName})
            .getAllImages()
            .selectOneImage({
                imageName: "Ubuntu-12.04-LTS-server-amd64-06.21.13.img", region: "EUROPE" })
            .filterStorages({
                storageName: storageName})
            .deleteStorages()
            .createStorage({
                storageName: storageName
                size: '50'})
            .connectStorageToServer()
            .waitUntilDataCenterIsAvailable()
            .selectOneNic({
                lanId: "1" })
            .addFirewallRulesToNic([{protocol: "TCP", portRangeStart: 22, portRangeEnd: 22}, {protocol: "TCP", portRangeStart: 8000, portRangeEnd: 9000}])
            .activateFirewalls()
            .waitUntilServerIsRunning()
            .execute (err, ctx) ->
                if err?
                    debug "datacenter create failed: #{err}"
                else
                    debug "datacenter create succeed"
                debug "context is: #{helper.beautify(ctx)}"


createDataCenterWithServerAndFirewallRulesContextSample = ->
    debug "createDataCenterWithServerAndFirewallRulesContextSample"
    helper.getPBBuilder (pbBuilder) ->
        dcName = 'dc_test02'
        serverName = 'server_test02'
        debug "about to create datacenter '#{dcName}' with one server '#{serverName}'"

        pbBuilder.createDataCenter({dataCenterName: dcName})
        pbBuilder.createServer({serverName: serverName, 'cores': "1", 'ram': "256", 'lanId': 1, 'internetAccess': true})
        pbBuilder.execute (err, ctx) ->
            debug "about to get details"
            debug "err: #{err}"
            debug "ctx: #{helper.beautify(ctx)}"
            pbBuilder.getDataCenterDetails()
            pbBuilder.selectOneServer({serverId: ctx.server.serverId})
            pbBuilder.execute (err, ctx) ->
                debug "about to set firewall rules"
                debug "err: #{err}"
                debug "ctx: #{helper.beautify(ctx)}"
                pbBuilder.waitUntilDataCenterIsAvailable()
                pbBuilder.selectOneNic({lanId: "1"})
                pbBuilder.addFirewallRulesToNic([{protocol: "TCP", portRangeStart: 22, portRangeEnd: 22}, {protocol: "TCP", portRangeStart: 8000, portRangeEnd: 9000}])
                pbBuilder.activateFirewalls()
                pbBuilder.execute (err, ctx) ->
                    if err?
                        debug "datacenter create failed: #{err}"
                    else
                        debug "datacenter create succeed"
                    debug "context is: #{helper.beautify(ctx)}"



createDataCenterWithServerStorageAndFirewallRules()
