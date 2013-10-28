# Std library

# Third party
fs = require 'fs'
debug = require('debug') 'profitbricks-builder/test'
{expect, assert} = require 'chai'

# Local dep
profitBricksJobBuilder = require '../src/profitbricks_jobbuilder'
profitBricksApi = require '../src/profitbricks_api'

pbApi = null
pbBuilder = null

describe 'profitBricksJobBuilder', ->
    beforeEach (done) ->
        pbApi = profitBricksApi()
        pbApi.soapClient = new SoapClientMock {}
        pbBuilder = profitBricksJobBuilder pbApi
        done()

    it 'lookup server job queue', (done) ->
        # mock
        pbApi.soapClient.mock('getAllDataCenters')
            .returns([
                dataCenterName: 'dc1'
                dataCenterId: '1'
            ,
                dataCenterName: 'dc2'
                dataCenterId: '2'])
            .expects (args) ->
                expect(args).to.be.empty

        server01 =
            serverName: 's1'
            serverId: 11
            virtualMachineState: 'RUNNING'
            
        detailedDataCenter =
            dataCenterName: 'dc1'
            dataCenterId: '1'
            provisioningState: 'AVAILABLE'
            servers: [server01, {serverName: 's2', serverId: 12}]

        pbApi.soapClient.mock('getDataCenter')
            .returns([detailedDataCenter])
            .expects (args) ->
                expect(args).to.be.deep.equal {dataCenterId: '1'}

        pbApi.soapClient.mock('getServer')
            .returns([server01])
            .expects (args) ->
                expect(args).to.be.deep.equal {serverId: 11}

        # execute
        pbBuilder
            .getAllDataCenters()
            .selectOneDataCenter(
                dataCenterName: 'dc1')
            .getDataCenterDetails()
            .selectOneServer(
                serverName: 's1')
            .waitUntilDataCenterIsAvailable()
            .waitUntilServerIsRunning()
            .execute (err, ctx) ->
                expect(err).to.be.null
                expect(ctx.datacenter).to.deep.equal detailedDataCenter
                expect(ctx.server).to.deep.equal server01
                expect(pbBuilder.getFirstDataCenterID()).to.be.not.empty
                expect(pbBuilder.getFirstDataCenterID()).to.be.equal '1'
                done()

    it 'recreate storage job queue', (done) ->
        # mock
        server01 =
            serverName: 's1',
            serverId: 11,
            virtualMachineState: 'RUNNING'
        detailedDataCenter =
            dataCenterName: 'dc1',
            dataCenterId: 42,
            provisioningState: 'AVAILABLE'
            servers: [server01, {serverName: 's2', serverId: 12}]
            storages: [
                storageName:'storage01'
                storageId: 'st01ID'
            ,
                storageName:'devStorage'
                storageId: 'st02ID'
            ]

        pbApi.soapClient.mock('getDataCenter')
            .returns([detailedDataCenter])
            .expects (args) ->
                expect(args).to.be.deep.equal {dataCenterId: 42}

        pbApi.soapClient.mock('getServer')
            .returns([server01])
            .expects (args) ->
                expect(args).to.be.deep.equal {serverId: 11}

        pbApi.soapClient.mock('getAllImages')
            .returns([
                imageName: 'image.vmdk',
                imageId: 'img1ID'
            ,
                imageName: 'ubuntu.vmdk',
                imageId: 'img2ID'])
            .expects (args) ->
                expect(args).to.be.empty

        pbApi.soapClient.mock('deleteStorage')
            .expects (args) ->
                expect(args).to.be.deep.equal {storageId: 'st02ID'}

        storage01 =  {
            storageName: 'newDevStorage'
            size: '50'
            dataCenterId: 42
            mountImageId: 'img2ID'
        }
        pbApi.soapClient.mock('createStorage')
            .returns([{storageId: 'stNewID'}])
            .expects (args) ->
                expect(args).to.be.deep.equal { request: storage01 }

        pbApi.soapClient.mock('connectStorageToServer')
            .expects (args) ->
                expect(args).to.be.deep.equal
                    request:
                        storageId: 'stNewID'
                        serverId: 11
                        busType: 'VIRTIO'

        # execute
        pbBuilder
            .getDataCenterDetails(42)
            .log('datacenter')
            .logDescribeSoapClient()
            .getAllImages()
            .selectOneImage(
                imageName: 'ubuntu.vmdk')
            .selectOneServer(
                serverName: 's1')
            .filterStorages(
                storageName: 'devStorage')
            .deleteStorages()
            .createStorage(
                storageName: 'newDevStorage'
                size: '50')
            .connectStorageToServer()
            .waitUntilDataCenterIsAvailable()
            .waitUntilServerIsRunning()
            .execute (err, ctx) ->
                expect(err).to.be.null
                expect(ctx.storage.storageId).to.equal 'stNewID'
                done()

    it 'using manuell keys', (done) ->
        pbApi.soapClient.mock('getAllDataCenters')
            .returns([
                dataCenterName: 'dc1'
                dataCenterId: 'dc1ID'])
            .expects (args) ->
                expect(args).to.be.empty

        pbApi.soapClient.mock('getDataCenter')
            .returns([
                dataCenterName: 'dc1'
                dataCenterId: 'dc1ID'])
            .expects (args) ->
                expect(args).to.be.deep.equal {dataCenterId: 'dc1ID'}

        pbBuilder
            .getAllDataCenters('my.AllDataCenterKey')
            .selectOne({dataCenterName: 'dc1'},
                'put.my.info.here',
                'my.AllDataCenterKey')
            .getDataCenterDetails(null, 'put.my.info.here')
            .execute (err, ctx) ->
                info = pbBuilder.getContextItem 'put.my.info.here'
                dataCenterName = pbBuilder
                    .getContextItem 'put.my.info.here.dataCenterName'
                firstDataCenterName = pbBuilder
                    .getFirstContextItem "put.my.info.here.dataCenterName"
                expect(err).to.be.null
                expect(ctx.put.my.info.here).to.be.not.empty
                expect(ctx.put.my.info.here.dataCenterName).to.be.equal 'dc1'
                expect(info).to.be.not.empty
                expect(info).to.be.a 'object'
                expect(dataCenterName).to.be.equal 'dc1'
                expect(firstDataCenterName).to.be.equal 'dc1'
                done()

    it 'delete datacenter', (done) ->
        pbApi.soapClient.mock('getAllDataCenters')
            .returns([
                dataCenterName: 'dc1'
                dataCenterId: 'dc1ID'
            ,
                dataCenterName: 'dc2'
                dataCenterId: 'dc2ID'])
            .expects (args) ->
                expect(args).to.be.empty

        pbApi.soapClient.mock('deleteDataCenter')
            .returns()
            .expects (args) ->
                expect(args).to.be.deep.equal {dataCenterId: 'dc2ID'}

        pbApi.soapClient.mock('getDataCenter')
            .returnsError('dataCenter not found')
            .expects (args) ->
                expect(args).to.be.deep.equal {dataCenterId: 'dc2ID'}

        pbBuilder
            .getAllDataCenters()
            .filterDataCenters(
                dataCenterName: 'dc2')
            .deleteDataCenters()
            .execute (err, pbContext) ->
                firstDataCenterID = pbContext.datacenters[0].dataCenterId
                expect(pbContext.datacenters.length).to.be.equal 1
                pbBuilder.waitUntilDataCenterIsDead firstDataCenterID
                pbBuilder.execute (err, ctx) ->
                    expect(err).to.be.null
                    pbBuilder
                        .getAllDataCenters()
                        .selectOneDataCenter(
                            dataCenterId: 'dc2ID')
                        .deleteDataCenter()
                        .execute (err, pbContext) ->
                            pbBuilder.waitUntilDataCenterIsDead()
                            pbBuilder.execute (err, ctx) ->
                                expect(err).to.be.null
                                done()

    it 'getContext()', (done) ->

        pbDatacenterInfo = JSON.parse fs.readFileSync "#{__dirname}/" +
            "prodfitbricks_datacenter.json"
        pbApi.soapClient.mock('getDataCenter')
            .returns([pbDatacenterInfo])
            .expects (args) ->
                expect(args).to.be.deep.equal {dataCenterId: 'dc1ID'}

        pbBuilder
            .getDataCenterDetails('dc1ID')
            .execute (err, ctx) ->
                datacenterServers = pbBuilder.
                    getContextItem 'datacenter.servers'
                firstDatacenterServer = pbBuilder
                    .getFirstContextItem 'datacenter.servers'
                expect(datacenterServers).to.be.not.empty
                expect(datacenterServers).to.have.length 2
                expect(pbBuilder.getContextItem('datacenter.fake')).to.be.empty
                expect(firstDatacenterServer).to.be.not.empty
                expect(firstDatacenterServer?.serverId).to.be.a 'string'
                done()




class SoapClientMock
    constructor: (@mocks = {}) ->

    describe: ->

    invoke: (func, args, callback) ->
        if not @mocks[func]?
            debug 'huhu'
        assert @mocks[func]?,
            "FAIL cause function #{func} not mocked in SoapClientMock"
        @mocks[func].evalExpectations args
        callback @mocks[func].returnError, @mocks[func].returnValue

    mock: (func) ->
        @mocks[func] = new FuncMock func


class FuncMock
    constructor: (@func) ->
        @returnValue = {return:[]}
        @returnError = null
        @expectFunc = null

    returns: (value) ->
        @returnValue = {return: value}
        return this

    returnsError: (value) ->
        @returnError = value
        return this

    expects: (@expectFunc) ->
        return this

    evalExpectations: (args) ->
        if @expectFunc?
            @expectFunc args
