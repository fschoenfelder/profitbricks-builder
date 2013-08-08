debug = require('debug')('profitbricks-builder/examples')

profitBricksJobBuilder = require '../src/profitbricks_jobbuilder'
profitBricksApi = require '../src/profitbricks_api'

helper = require './sample_helper'

testDeleteDataCenterByName = ->
    debug "testDeleteDataCenterByName"
    helper.getPBBuilder (pbBuilder) ->
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


testDeleteDataCenterByNamePattern = ->
    debug "testDeleteDataCenterByNamePattern"
    helper.getPBBuilder (pbBuilder) ->
        dcName = 'dc_test01'
        debug "about to delete datacenters with name #{dcName}"
        pbBuilder
            .getAllDataCenters()
            .filterDataCenters({dataCenterName: dcName})
            .deleteDataCenters()
            .execute (err, ctx) ->
                if pbBuilder.getFirstDataCenterID()
                    pbBuilder.waitUntilDataCenterIsDead(pbBuilder.getFirstDataCenterID())
                pbBuilder.execute (err, ctx) ->
                    if err?
                        debug "datacenter delete failed: #{err}"
                    else
                        debug "datacenter delete succeed"
                    debug "context is: #{helper.beautify(ctx)}"


testDeleteDataCenterByNamePattern()
