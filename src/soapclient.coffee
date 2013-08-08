soap = require 'soap'
debug = require('debug')('rplan.tools.jenkins.bootstrap.soapclient')

class SoapClient
    constructor: (@url, @security) ->

    init: (cb) ->
        soap.createClient @url, (err, client) =>
            if(err?)
                cb(err)
            else
                @client = client
                @client.setSecurity(@security)
                cb(err)
        undefined

    describe: ->
        @client.describe()

    invoke: (func, args, cb) ->
        @client[func] args, (err, result) =>
            debug @client.lastRequest
            cb(err, result)
        undefined

    invokeJustLog: (func, args, cb) ->
        debug func, args
        cb(null)
        undefined

module.exports.newBasicAuth =  (url, user, pwd) ->
    new SoapClient(url, new soap.BasicAuthSecurity(user, pwd))
