var exec = require('cordova/exec');

module.exports = {

    init: function(success, error) {
        exec(success, error, 'MSKBedfontPlugin', 'init');
    },
    dispose: function(success, error) {
        exec(success, error, 'MSKBedfontPlugin', 'dispose');
    },
    performScanning: function(success, error) {
        exec(success, error, 'MSKBedfontPlugin', 'performScanning');
    },
    performDisconnection: function(success, error) {
        exec(success, error, 'MSKBedfontPlugin', 'performDisconnection');
    },
    testNorecovery: function(success, error) {
        exec(success, error, 'MSKBedfontPlugin', 'testNorecovery');
    },
    getDeviceUsage: function(success, error) {
        exec(success, error, 'MSKBedfontPlugin', 'getDeviceUsage');
    },
    getDeviceFirmware: function(success, error) {
        exec(success, error, 'MSKBedfontPlugin', 'getDeviceFirmware');
    },
    getDeviceSerialNumber: function(success, error) {
        exec(success, error, 'MSKBedfontPlugin', 'getDeviceSerialNumber');
    }

}