soap = require 'soap'

debug = require('debug') 'profitbricks-builder/soapclient'

class SoapClient
    constructor: (@url, @security) ->

    init: (callback) ->
        soap.createClient @url, (err, client) =>
            if err?
                callback err
            else
                @client = client
                @client.setSecurity @security
                callback err
        undefined

    describe: ->
        @client.describe()

    invoke: (func, args, callback) ->
        @client[func] args, (err, result) =>
            debug @client.lastRequest
            callback err, result
        undefined

    invokeJustLog: (func, args, callback) ->
        debug func, args
        callback null
        undefined

module.exports.newBasicAuth =  (url, user, pwd) ->
    new SoapClient url, new soap.BasicAuthSecurity(user, pwd)
