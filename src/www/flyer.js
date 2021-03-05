var cordova = require('cordova');


function Flyer() {
  this.show = function (params, success, error) {
    return new Promise(function (resolve, reject) {
      cordova.exec(success || resolve, error || reject, 'NativeView', 'show', [params]);
    });
  };
};

module.exports = new Flyer();

