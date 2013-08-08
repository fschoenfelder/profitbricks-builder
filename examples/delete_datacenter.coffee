debug = require('debug')('profitbricks-builder/examples')

profitBricksJobBuilder = require '../src/profitbricks_jobbuilder'
profitBricksApi = require '../src/profitbricks_api'

helper = require './sample_helper'

testDeleteDataCenterByName = ->
    debug "testDeleteDataCenter"
    getPBBuilder (pbBuilder) ->
        dcName = 'dc_test01'
        debug "about to delete datacenters with name #{dcName}"
        pbBuilder.getAllDataCenters()
            .selectOneDataCenter({dataCenterName: dcName})
            .deleteDataCenters()
            .waitUntilDataCenterIsDead()
            .execute (err, ctx) ->
                if err?
                    debug "datacenter delete failed: #{err}"
                else
                    debug "datacenter delete succeed"
                debug "context is: #{helper.beautify(ctx)}"


testDeleteDataCenterByName()


testDeleteDataCenterByNamePattern = ->
    debug "testDeleteDataCenter"
    getPBBuilder (pbBuilder) ->
        dcName = 'dc_test01'
        debug "about to delete datacenters with name #{dcName}"
        pbBuilder.getAllDataCenters()
            .filterDataCenters({dataCenterName: dcName})
            .deleteDataCenters()
            .execute (err, ctx) ->
                pbBuilder.waitUntilDataCenterIsDead(pbBuilder.getFirstDataCenterID())
                    .execute (err, ctx) ->
                        if err?
                            debug "datacenter delete failed: #{err}"
                        else
                            debug "datacenter delete succeed"
                        debug "context is: #{helper.beautify(ctx)}"

