# Std library
# Third party
debug = require('debug') 'profitbricks-builder/examples'

# Local dep
helper = require './sample_helper'

debug 'playground about todo something'

getAllImages = ->
    helper.getPBBuilder (pbBuilder) ->
        pbBuilder
            .getAllImages()
            .execute (err, ctx) ->
                if err?
                    debug "playground failed with err: #{err}"
                else
                    debug 'playground succeed'
                console.log "ctx is #{helper.beautify ctx}"


getAllDataCenters = ->
    helper.getPBBuilder (pbBuilder) ->
        pbBuilder
            .getAllDataCenters()
            .execute (err, ctx) ->
                if err?
                    debug "playground failed with err: #{err}"
                else
                    debug 'playground succeed'
                console.log "ctx is #{helper.beautify ctx}"

getAllDataCenters()