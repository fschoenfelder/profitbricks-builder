// Generated by CoffeeScript 1.6.3
(function() {
  var ProfitBricksApi, SoapClient, async, debug, filterItemsSync, firstItem, forever, wrapList, _;

  async = require('async');

  _ = require('underscore')._;

  debug = require('debug')('profitbricks-builder/profitbricks_api');

  SoapClient = require('./soapclient');

  ProfitBricksApi = (function() {
    var WAIT_CYCLE;

    WAIT_CYCLE = 10000;

    function ProfitBricksApi() {
      this.url = null;
      this.soapClient = null;
    }

    ProfitBricksApi.prototype.init = function(url, user, pwd, cb) {
      this.url = url;
      this.soapClient = SoapClient.newBasicAuth(url, user, pwd);
      return this.soapClient.init(function(err) {
        if (err != null) {
          debug("soapClient initialized with error '" + err + "'");
        } else {
          debug("soapClient initialized");
        }
        return cb(err);
      });
    };

    ProfitBricksApi.prototype.describe = function(cb) {
      return cb(null, this.soapClient.describe());
    };

    ProfitBricksApi.prototype.getAllDataCenters = function(cb) {
      return this.soapClient.invoke("getAllDataCenters", {}, function(err, results) {
        var _ref;
        if ((results != null ? (_ref = results["return"]) != null ? _ref.length : void 0 : void 0) > 0) {
          debug("found " + results["return"].length + " datacenter(s)");
          return cb(err, results["return"]);
        } else {
          debug("no datacenters found");
          return cb(err, []);
        }
      });
    };

    ProfitBricksApi.prototype.getDataCenter = function(config, cb) {
      return this.soapClient.invoke("getDataCenter", {
        dataCenterId: config.dataCenterId
      }, function(err, result) {
        var _ref;
        return cb(err, result != null ? (_ref = result["return"]) != null ? _ref[0] : void 0 : void 0);
      });
    };

    ProfitBricksApi.prototype.deleteDataCenter = function(dataCenter, cb) {
      debug("about to delete dataCenter '" + (firstItem(dataCenter.dataCenterName)) + "' with id '" + (firstItem(dataCenter.dataCenterId)) + "'");
      return this.soapClient.invoke("deleteDataCenter", {
        dataCenterId: firstItem(dataCenter.dataCenterId)
      }, function(err, result) {
        var _ref;
        debug("dataCenter deleted '" + (firstItem(dataCenter.dataCenterName)) + "' with id '" + (firstItem(dataCenter.dataCenterId)) + "', error: " + err + ", result: " + result);
        return cb(err, result != null ? (_ref = result["return"]) != null ? _ref[0] : void 0 : void 0);
      });
    };

    ProfitBricksApi.prototype.deleteDataCenters = function(dataCenters, cb) {
      var _this = this;
      return async.each(dataCenters, function(dataCenter, fcb) {
        return _this.deleteDataCenter(dataCenter, function(err) {
          if (err != null) {
            return cb(err);
          } else {
            return fcb();
          }
        });
      }, cb);
    };

    ProfitBricksApi.prototype.createDataCenter = function(config, cb) {
      debug("about to create datacenter " + (JSON.stringify(config)));
      return this.soapClient.invoke("createDataCenter", config, function(err, result) {
        var _ref;
        return cb(err, result != null ? (_ref = result["return"]) != null ? _ref[0] : void 0 : void 0);
      });
    };

    ProfitBricksApi.prototype.getAllImages = function(cb) {
      return this.soapClient.invoke("getAllImages", {}, function(err, results) {
        var _ref, _ref1;
        debug("found " + (results != null ? (_ref = results["return"]) != null ? _ref.length : void 0 : void 0) + " images");
        if ((results != null ? (_ref1 = results["return"]) != null ? _ref1.length : void 0 : void 0) > 0) {
          return cb(err, results["return"]);
        } else {
          return cb(err, []);
        }
      });
    };

    ProfitBricksApi.prototype.getStorage = function(storage, cb) {
      return this.soapClient.invoke("getStorage", {
        storageId: storage.storageId
      }, function(err, result) {
        var _ref, _ref1;
        debug("getStorage returned with error: " + err + ", result: " + (result != null ? (_ref = result["return"]) != null ? _ref[0] : void 0 : void 0));
        return cb(err, result != null ? (_ref1 = result["return"]) != null ? _ref1[0] : void 0 : void 0);
      });
    };

    ProfitBricksApi.prototype.createStorage = function(storageConfig, cb) {
      debug("about to create storage storageConfig " + (JSON.stringify(storageConfig)));
      return this.soapClient.invoke("createStorage", {
        request: storageConfig
      }, function(err, result) {
        var storage, _ref;
        storage = result != null ? (_ref = result["return"]) != null ? _ref[0] : void 0 : void 0;
        debug("create storage returned with error: " + err + ", result: " + (JSON.stringify(storage)));
        return cb(err, storage);
      });
    };

    ProfitBricksApi.prototype.connectStorageToServer = function(config, cb) {
      config.busType = config.busType ? config.busType.toUpperCase() : void 0;
      debug("about to connect storage " + (JSON.stringify(config)));
      return this.soapClient.invoke("connectStorageToServer", {
        request: config
      }, function(err, result) {
        debug("storage connected with id " + config.storageId + ", error: " + err + ", result: " + (JSON.stringify(result)));
        return cb(err);
      });
    };

    ProfitBricksApi.prototype.disconnectStorages = function(server, objPattern, cb) {
      var connectedStorages, storagesToDisconnect,
        _this = this;
      connectedStorages = wrapList(server.connectedStorages);
      storagesToDisconnect = filterItemsSync(connectedStorages, objPattern);
      debug("found " + storagesToDisconnect.length + " connected storage to disconnect");
      return async.filter(storagesToDisconnect, function(storage, fcb) {
        debug("about to disconnect storage '" + storage.storageName + "' with id " + storage.storageId);
        return _this.soapClient.invoke("disconnectStorageFromServer", {
          storageId: storage.storageId,
          serverId: server.serverId
        }, function(err, result) {
          debug("storage disconnected '" + storage.storageName + "' with id " + storage.storageId + ", error: " + err + ", result: " + result);
          return fcb(true);
        });
      }, function(results) {
        return cb(null, results);
      });
    };

    ProfitBricksApi.prototype.deleteStorages = function(storages, cb) {
      var _this = this;
      return async.each(storages, function(storage, fcb) {
        debug("about to delete storage '" + storage.storageName + "' with id " + storage.storageId);
        return _this.soapClient.invoke("deleteStorage", {
          storageId: storage.storageId
        }, function(err, result) {
          debug("storage deleted '" + storage.storageName + "' with id " + storage.storageId + ", error: " + err + ", result: " + result);
          if (err != null) {
            return cb(err);
          } else {
            return fcb();
          }
        });
      }, cb);
    };

    ProfitBricksApi.prototype.getServer = function(server, cb) {
      return this.soapClient.invoke("getServer", {
        serverId: server.serverId
      }, function(err, result) {
        var _ref;
        return cb(err, result != null ? (_ref = result["return"]) != null ? _ref[0] : void 0 : void 0);
      });
    };

    ProfitBricksApi.prototype.createServer = function(serverConfig, cb) {
      debug("about to create server with config " + (JSON.stringify(serverConfig)));
      return this.soapClient.invoke("createServer", {
        request: serverConfig
      }, function(err, result) {
        var server, _ref;
        server = result != null ? (_ref = result["return"]) != null ? _ref[0] : void 0 : void 0;
        debug("create server returned with error: " + err + ", result: " + (JSON.stringify(server)));
        return cb(err, server);
      });
    };

    ProfitBricksApi.prototype.deleteServers = function(servers, cb) {
      var _this = this;
      return async.each(servers, function(server, fcb) {
        debug("about to delete server '" + server.serverName + "' with id " + server.serverId);
        return _this.soapClient.invoke("deleteServer", {
          serverId: server.serverId
        }, function(err, result) {
          debug("server deleted '" + server.serverName + "' with id: '" + server.serverId + "', err: '" + err + "'");
          if (err != null) {
            return cb(err);
          } else {
            return fcb();
          }
        });
      }, cb);
    };

    ProfitBricksApi.prototype.addFirewallRuleToNic = function(rule, nic, cb) {
      return this.soapClient.invoke("addFirewallRulesToNic", {
        request: rule,
        nicId: nic.nicId
      }, function(err, result) {
        var _ref;
        nic = result != null ? (_ref = result["return"]) != null ? _ref[0] : void 0 : void 0;
        return cb(err, nic);
      });
    };

    ProfitBricksApi.prototype.activateFirewalls = function(firewallId, cb) {
      return this.soapClient.invoke("activateFirewalls", {
        firewallIds: firewallId
      }, function(err) {
        return cb(err);
      });
    };

    ProfitBricksApi.prototype.rebootServer = function(server, cb) {
      var _this = this;
      debug("about to reboot server " + server.serverName + ", " + server.serverId);
      return this.getServer(server, function(err, result) {
        if (result.provisioningState === "AVAILABLE" && result.virtualMachineState === "RUNNING") {
          return _this.soapClient.invoke("rebootServer", {
            serverId: server.serverId
          }, function(err, result) {
            debug("rebooted server " + server.serverName + ", error: " + err + ", result: " + (JSON.stringify(result)));
            return cb(err);
          });
        } else {
          return cb("server is not in the mood for a reboot: " + (JSON.stringify(result)));
        }
      });
    };

    ProfitBricksApi.prototype.waitUntilDataCenterIsAvailable = function(dataCenter, cb) {
      var test,
        _this = this;
      test = function(fcb) {
        return _this.getDataCenter(dataCenter, function(err, dcItem) {
          debug("wait until dataCenter " + dcItem.dataCenterName + " is AVAILABLE, currentstate is " + dcItem.provisioningState + ", id is " + dcItem.dataCenterId);
          if (dcItem.provisioningState === "AVAILABLE") {
            return fcb("ready");
          } else {
            return setTimeout(fcb, WAIT_CYCLE);
          }
        });
      };
      return forever(test, function(msg) {
        return cb(null, msg);
      });
    };

    ProfitBricksApi.prototype.waitUntilDataCenterIsDead = function(dataCenter, cb) {
      var test,
        _this = this;
      test = function(fcb) {
        return _this.getDataCenter(dataCenter, function(err, dcItem) {
          debug("wait until dataCenter " + ((dcItem != null ? dcItem.dataCenterId : void 0) || (dataCenter != null ? dataCenter.dataCenterId : void 0)) + " is DEAD");
          if (err != null) {
            return fcb("ready");
          } else {
            return setTimeout(fcb, WAIT_CYCLE);
          }
        });
      };
      return forever(test, function(msg) {
        return cb(null, msg);
      });
    };

    ProfitBricksApi.prototype.waitUntilServerIsRunning = function(server, cb) {
      var test,
        _this = this;
      test = function(fcb) {
        return _this.getServer(server, function(err, serverItem) {
          if (err != null) {
            fcb(err);
            return;
          }
          debug("wait until server " + serverItem.serverName + " is RUNNING, currentstate is " + serverItem.virtualMachineState + ", id is " + serverItem.serverId);
          if (serverItem.virtualMachineState === "RUNNING") {
            return fcb("ready");
          } else {
            return setTimeout(fcb, WAIT_CYCLE);
          }
        });
      };
      return forever(test, function(msg) {
        return cb(null, msg);
      });
    };

    ProfitBricksApi.prototype.filterItems = function(objList, objPattern, cb) {
      return cb(null, filterItemsSync(objList, objPattern));
    };

    return ProfitBricksApi;

  })();

  filterItemsSync = function(objList, objPattern) {
    var foundItems, list;
    list = wrapList(objList);
    foundItems = _.filter(list, function(item) {
      return _.every(objPattern, function(pattern, key) {
        var value;
        value = item[key] instanceof Array ? item[key][0] : item[key];
        return value === pattern;
      });
    });
    debug("" + foundItems.length + " item(s) found that match pattern: " + (JSON.stringify(objPattern)));
    return foundItems;
  };

  wrapList = function(list) {
    if (_.isArray(list)) {
      return list;
    } else if (list != null) {
      return [list];
    } else {
      return [];
    }
  };

  forever = function(fn, callback) {
    var next;
    next = function(err) {
      if (err) {
        return callback(err);
      } else {
        return fn(next);
      }
    };
    return next();
  };

  firstItem = function(value) {
    if (_.isArray(value)) {
      return value[0];
    } else {
      return value;
    }
  };

  module.exports = function() {
    return new ProfitBricksApi();
  };

}).call(this);
