// Generated by CoffeeScript 1.6.3
(function() {
  var SoapClient, debug, soap;

  soap = require('soap');

  debug = require('debug')('profitbricks-builder/soapclient');

  SoapClient = (function() {
    function SoapClient(url, security) {
      this.url = url;
      this.security = security;
    }

    SoapClient.prototype.init = function(cb) {
      var _this = this;
      soap.createClient(this.url, function(err, client) {
        if ((err != null)) {
          return cb(err);
        } else {
          _this.client = client;
          _this.client.setSecurity(_this.security);
          return cb(err);
        }
      });
      return void 0;
    };

    SoapClient.prototype.describe = function() {
      return this.client.describe();
    };

    SoapClient.prototype.invoke = function(func, args, cb) {
      var _this = this;
      this.client[func](args, function(err, result) {
        debug(_this.client.lastRequest);
        return cb(err, result);
      });
      return void 0;
    };

    SoapClient.prototype.invokeJustLog = function(func, args, cb) {
      debug(func, args);
      cb(null);
      return void 0;
    };

    return SoapClient;

  })();

  module.exports.newBasicAuth = function(url, user, pwd) {
    return new SoapClient(url, new soap.BasicAuthSecurity(user, pwd));
  };

}).call(this);
