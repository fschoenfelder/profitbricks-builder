debug = require('debug')('profitbricks-builder/examples')

profitBricksJobBuilder = require '../src/profitbricks_jobbuilder'
profitBricksApi = require '../src/profitbricks_api'

module.exports.credentials = credentials = null
try
    credentials = require './credentials'
catch err
    console.log "credentials are missing: #{err}"
    throw err

module.exports.getPBBuilder = getPBBuilder = (cb) ->
    debug "getPBBuilder"
    pbApi = profitBricksApi()
    pbApi.init credentials.pb_url, credentials.pb_user, credentials.pb_pwd, ->
        pbBuilder = profitBricksJobBuilder(pbApi)
        cb(pbBuilder)

module.exports.beautify = beautify = (obj) ->
    JSON.stringify(obj, null, "\t")
