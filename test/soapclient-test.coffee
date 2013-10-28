# Std library
# Third party
expect = require('chai').expect
debug = require('debug') 'profitbricks-builder/test'
# Local dep
SoapClient = require '../src/soapclient'


soapClient = null

describe "soapClient", ->
    before (done) ->
        soapClient = SoapClient
            .newBasicAuth "#{__dirname}/api_profitbricks_com_1_2.wsdl"
        done()

    it "init with file wsdl describe", (done) ->
        soapClient.init (err) ->
            expect(err).to.be.null
            description = soapClient.describe()
            expect(description).to.be.an "Object"
            expect(description).to.be.not.empty
            debug "#{soapClient.url} describe output is " +
                "#{JSON.stringify description}"
            servicePort = description.ProfitbricksApiService
                .ProfitbricksApiServicePort
            expect(servicePort).to.be.an "Object"
            expect(servicePort).to.be.not.empty

            expect(servicePort.getAllDataCenters).to.be.not.empty
            expect(servicePort.getServer).to.be.not.empty
            expect(servicePort.getSchnulliBulli).to.be.undefined
            done()

    it "invokeJustLog() should not fail", (done) ->
        soapClient.init (err) ->
            soapClient.invokeJustLog "testFunc", {testArgs:""}, (err) ->
                expect(err).to.be.null
                done()

#    it "local invoke getAllDataCenters should fail", (done) ->
#        soapClient.init (err) ->
#            soapClient.invoke "getAllDataCenters", {}, (err, result) ->
#                expect(result.statusCode).to.be.equal(401)
#                done()
