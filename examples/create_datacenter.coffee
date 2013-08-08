debug = require('debug')('profitbricks-builder/examples')

profitBricksJobBuilder = require '../src/profitbricks_jobbuilder'
profitBricksApi = require '../src/profitbricks_api'

helper = require './sample_helper'

createDataCenterWithFirewallRules = ->
    debug "createDataCenterWithFirewallRules"
    helper.getPBBuilder (pbBuilder) ->
        dcName = 'dc_test01'
        serverName = 'server_test01'
        debug "about to create datacenter '#{dcName}' with one server '#{serverName}'"
        pbBuilder
            .createDataCenter({dataCenterName: dcName})
            .createServer({serverName: serverName, 'cores': "1", 'ram': "256", 'lanId': 1, 'internetAccess': true})
            .getDataCenterDetails()
            .selectOneServer({serverName: serverName})
            .waitUntilDataCenterIsAvailable()
            .selectOneNic({lanId: "1"})
            .addFirewallRulesToNic([
                {protocol: "TCP", portRangeStart: 22, portRangeEnd: 22}
                {protocol: "TCP", portRangeStart: 8000, portRangeEnd: 9000}])
                #pbBuilder.waitUntilDataCenterIsAvailable()
            .activateFirewalls()
            .execute (err, ctx) ->
                if err?
                    debug "datacenter create failed: #{err}"
                else
                    debug "datacenter create succeed"
                debug "context is: #{helper.beautify(ctx)}"


createDataCenterWithFirewallRules()

createDataCenterWithFirewallRulesContextSample = ->
    debug "createDataCenterWithFirewallRulesContextSample"
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
                pbBuilder.addFirewallRulesToNic([
                {protocol: "TCP", portRangeStart: 22, portRangeEnd: 22}
                {protocol: "TCP", portRangeStart: 8000, portRangeEnd: 9000}])
                pbBuilder.activateFirewalls()
                pbBuilder.execute (err, ctx) ->
                    if err?
                        debug "datacenter create failed: #{err}"
                    else
                        debug "datacenter create succeed"
                    debug "context is: #{helper.beautify(ctx)}"



