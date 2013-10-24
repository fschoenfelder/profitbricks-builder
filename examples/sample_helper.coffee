# Std library
# Third party
debug = require('debug') 'profitbricks-builder/examples'

# Local dep
profitBricksApi = require('../src').pbapi
profitBricksJobBuilder = require('../src').pbbuilder

module.exports.credentials = credentials = null
try
    credentials = require './credentials'
catch err
    console.log "credentials are missing: #{err}"
    throw err

module.exports.getPBBuilder = getPBBuilder = (callback) ->
    debug 'getPBBuilder'
    pbApi = profitBricksApi()
    pbApi.init credentials.pb_url, credentials.pb_user, credentials.pb_pwd, ->
        pbBuilder = profitBricksJobBuilder pbApi
        callback pbBuilder

module.exports.beautify = beautify = (obj) ->
    JSON.stringify obj, null, '\t'
