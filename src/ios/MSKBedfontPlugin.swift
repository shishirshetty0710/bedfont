//
//  MSKBedfontPlugin.swift
//
//  Created by Shishir Shetty on 2023-10-02.
//
import Foundation
import SmokerlyzerSDK



var smokerlyzerBluetooth = SmokerlyzerBluetooth()



@objc(MSKBedfontPlugin)
class MSKBedfontPlugin: CDVPlugin, ConnectionObserver {
    
     let BEDFONT_EVENT_RECOVERYCHANGE = "OnRecoveryChangeEvent"
    
     let BEDFONT_EVENT_SCANSTATECHANGE = "OnScanStateChangeEvent"
    
     let BEDFONT_EVENT_CONNECTIONCHANGE = "OnConnectionChangeEvent"
    
     let BEDFONT_EVENT_CONNECTINGCHANGE = "OnCOnnectingChangeEvent"
    
     let BEDFONT_EVENT_BUTTONNAMECHANGE = "OnButtonNameChangeEvent"
    
     let BEDFONT_EVENT_CONNECT_RESULT = "OnConnectResultEvent"
    
     let BEDFONT_EVENT_SCAN_RESULT = "OnScanResultEvent"
    
     let BEDFONT_EVENT_DEVICE_USAGE = "onDeviceUsageEvent"
    
     let BEDFONT_EVENT_DEVICE_FIRMWARE = "onDeviceFirmwareEvent"
    
     let BEDFONT_EVENT_DEVICE_SERIALNUMBER = "onDeviceSerialNumberEvent"
    
    
    
     let SUCCESS = "SUCCESS"
     let SUCCESS_NEEDS_RECOVERY = "SUCCESS_NEEDS_RECOVERY"
     let ZEROING = "ZEROING"
     let ERROR_FAILED_TO_FINALIZE = "ERROR_FAILED_TO_FINALIZE"
     let ERROR_FAILED_TO_CONNECT = "ERROR_FAILED_TO_CONNECT"
     let ERROR_SCAN_FAILED = "ERROR_SCAN_FAILED"
    
     let DEVICE_NOT_CONNECTED = "DEVICE_NOT_CONNECTED"
    
    
    var STATE_DISCONNECT = true
    var STATE_SCAN_AND_CONNECT = false
    
    var initialized = false
    
    var sensor: PeripheralIdentifier?
    var isConnectedText: String = "Disconnected"
    
    var isEnabled: Bool = false
    
    //var myCommandDelegate: CDVCommandDelegate?
    

    override func pluginInitialize() {
        super.pluginInitialize()

        // Initialize myCommandDelegate with self.commandDelegate during plugin initialization
        //myCommandDelegate = self.commandDelegate
    }
    
    @objc(initialize:)func initialize(command : CDVInvokedUrlCommand) {
        
        if(!initialized) {
            smokerlyzerBluetooth = SmokerlyzerBluetooth()
            smokerlyzerBluetooth.register(connectionObserver: self)
            
            initialized = true
            let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        } else {
            let result = CDVPluginResult.init(status: CDVCommandStatus_OK, messageAs: "Already Initialized!")
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }
    
    @objc(dispose:)func dispose(command : CDVInvokedUrlCommand) {
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(getStatus:)func getStatus(command : CDVInvokedUrlCommand) {
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.getIsConnected { result in
                if(result) {
                    let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                } else {
                    let errorMessage = "Device is not connected"
                    let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: errorMessage)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            }
        }
        
    }
    
    @objc(performScanning:)func performScanning(command : CDVInvokedUrlCommand) {
        
        self.perform_Scanning(commandDelegate: self.commandDelegate)
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(performDisconnection:)func performDisconnection(command : CDVInvokedUrlCommand) {
        
        self.perform_Disconnection(commandDelegate: self.commandDelegate)
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(testNorecovery:)func testNorecovery(command : CDVInvokedUrlCommand) {
        
        self.perform_TestNorecovery(commandDelegate: self.commandDelegate)
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(getDeviceFirmware:)func getDeviceFirmware(command : CDVInvokedUrlCommand) {
        
        self.get_DeviceFirmware(commandDelegate: self.commandDelegate)
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(getDeviceSerialNumber:)func getDeviceSerialNumber(command : CDVInvokedUrlCommand) {
        
        self.get_DeviceSerialNumber(commandDelegate: self.commandDelegate)
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(getDeviceBattery:)func getDeviceBattery(command : CDVInvokedUrlCommand) {
        
        self.get_DeviceBattery(commandDelegate: self.commandDelegate)
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    
    func bluetoothAvailable(_ available: Bool) {
        //log(message: "Bluetooth available: \(available)")
    }

    func connected(to peripheral: PeripheralIdentifier) {
        //log(message: "[connection observer] detected connect event")
        //sensor = peripheral
        //isConnectedText = "Connected"
        self.sendStateChangeEvents(commandDelegate: self.commandDelegate, boolval: true)
    }

    func disconnected(from peripheral: PeripheralIdentifier) {
        //log(message: "[connection observer] detected disconnect event")
        //isConnectedText = "Disconnected"
        self.sendStateChangeEvents(commandDelegate: self.commandDelegate, boolval: false)
    }
    
    
    
    func perform_Scanning(commandDelegate: CDVCommandDelegate) {
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.scanAndConnect(connected: {update in
                    switch update {
                            case .success(let peripheralId):
                                //self.log(message: "Successfully connected to " + peripheralId.name)
                                //self.isConnectedText = "Connected"
                                self.sendScanningEvents(commandDelegate: commandDelegate, connectResult: "SUCCESS", logMessage: "Finalized connection. Device is READY")
                            case .successNeedsRecovery(let peripheralId):
                                //self.log(message: "Connected to " + peripheralId.name + ". Recovery is needed before starting breath test.")
                                //self.isConnectedText = "Connected"
                                self.sendScanningEvents(commandDelegate: commandDelegate, connectResult: "SUCCESS_NEEDS_RECOVERY", logMessage: "Finalized connection. Recovery function needs to be run on the sensor")
                            case .zeroing:
                                //self.log(message: "Device is zeroing, please wait")
                                self.sendScanningEvents(commandDelegate: commandDelegate, connectResult: "ZEROING", logMessage: "Zeroing the sensor, please wait...")
                            case .failure(let error):
                                if let error = error as? BluejayError {
                                    switch error{
                                    case .scanFailed:
                                        //self.log(message: "Scanning failed to pick up a device")
                                        self.sendScanningEvents(commandDelegate: commandDelegate, connectResult: "ERROR_SCAN_FAILED", logMessage: "Failed to find device")
                                    case .connectionTimedOut:
                                        //self.log(message: "Failed to connect to device")
                                        self.sendScanningEvents(commandDelegate: commandDelegate, connectResult: "ERROR_FAILED_TO_CONNECT", logMessage: "Failed to connect to device")
                                    default:
                                        //self.log(message: "Error: " + error.localizedDescription)
                                        self.sendScanningEvents(commandDelegate: commandDelegate, connectResult: "ERROR_SCAN_FAILED", logMessage: "Failed to find device")
                                    }
                                }
                        //self.isConnectedText = "Disconnected"
                    }
                                                })
                }
    }
   
    
    func perform_Disconnection(commandDelegate: CDVCommandDelegate) {
        self.sendStateChangeEvents(commandDelegate: commandDelegate, boolval: false)
        self.isEnabled = false
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.disconnect(force: true)
        }
    }
    
    func perform_TestNorecovery(commandDelegate: CDVCommandDelegate) {
        if smokerlyzerBluetooth != nil {
            
            smokerlyzerBluetooth.startBreathTestNoRecovery {result in
                switch result {
                case .success(let ppmResult):
                    self.sendScanningResults(commandDelegate: commandDelegate, statusName: "PPM value is " + ppmResult.latest.description, ppm: ppmResult.latest, isSuccessful: true)
                case .failure(let error):
                    self.sendScanningResults(commandDelegate: commandDelegate, statusName: "Error: " + error.localizedDescription, ppm: -1, isSuccessful: false)
                }
            }
        }
        
    }
    func get_DeviceFirmware(commandDelegate: CDVCommandDelegate) {
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.getFirmwareVersion(callback: { result in
                switch result {
                case .success(let firmware):
                    //self.log(message: "Firmware version: " + firmware.version)
                    self.sendDeviceDetails(commandDelegate: commandDelegate, eventName: "onDeviceFirmwareEvent", deviceParam: firmware.version)
                case .failure(let error):
                    //self.log(message: "Error: " + error.localizedDescription)
                    self.sendDeviceDetails(commandDelegate: commandDelegate, eventName: "onDeviceFirmwareEvent", deviceParam: "Error: " + error.localizedDescription)
                }
            })
        }
    }
    
    func get_DeviceSerialNumber(commandDelegate: CDVCommandDelegate) {
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.getSerialNumber(callback: { result in
                switch result {
                case .success(let serial):
                    //self.log(message: "Serial number: " + serial.serial)
                    self.sendDeviceDetails(commandDelegate: commandDelegate, eventName: "onDeviceSerialNumberEvent", deviceParam: serial.serial)
                case .failure(let error):
                    //self.log(message: "Error: " + error.localizedDescription)
                    self.sendDeviceDetails(commandDelegate: commandDelegate, eventName: "onDeviceSerialNumberEvent", deviceParam: "Error: " + error.localizedDescription)
                }
            })
        }
    }
    
    func get_DeviceBattery(commandDelegate: CDVCommandDelegate) {
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.getBatteryReading(callback: { result in
                switch result {
                case .success(let battery):
                    //self.log(message: "Serial number: " + serial.serial)
                    self.sendDeviceDetails(commandDelegate: commandDelegate, eventName: "onDeviceBatteryEvent", deviceParam: String(battery.volts))
                case .failure(let error):
                    //self.log(message: "Error: " + error.localizedDescription)
                    self.sendDeviceDetails(commandDelegate: commandDelegate, eventName: "onDeviceBatteryEvent", deviceParam: "Error: " + error.localizedDescription)
                }
            })
        }
    }
    
    func sendStateChangeEvents(commandDelegate: CDVCommandDelegate, boolval: Bool) {
        let eventData: [String: Any] = [
            "changeState": boolval
        ]
        self.fireEvent(commandDelegate: commandDelegate, eventName: "OnButtonNameChangeEvent", eventData: eventData )
    }
    
    func sendScanningEvents(commandDelegate: CDVCommandDelegate,connectResult: String, logMessage: String) {
        let eventData: [String: Any] = [
            "connectResult": connectResult,
            "logMessage": logMessage
        ]
        self.fireEvent(commandDelegate: commandDelegate, eventName: "OnConnectResultEvent", eventData: eventData)
    }
    
    func sendScanningResults(commandDelegate: CDVCommandDelegate, statusName: String, ppm: Int, isSuccessful: Bool) {
        let eventData: [String: Any] = [
            "statusName": statusName,
            "ppm": ppm,
            "isSuccessful": isSuccessful
        ]
        self.fireEvent(commandDelegate: commandDelegate, eventName: "OnScanResultEvent", eventData: eventData)
    }
    
    func sendDeviceDetails(commandDelegate: CDVCommandDelegate, eventName: String, deviceParam: String) {
        let eventData: [String: Any] = [
            "deviceDetail": deviceParam
        ]
        
        self.fireEvent(commandDelegate: commandDelegate, eventName: eventName, eventData: eventData)
    }
    
    func fireEvent(commandDelegate: CDVCommandDelegate, eventName: String, eventData: [String: Any]) {
        
        do {
            // Convert the dictionary to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: eventData, options: [])

            // Print the JSON data as a string (for demonstration purposes)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                
                let jsCode = "cordova.fireDocumentEvent('" + eventName + "'," + jsonString + ")"
                commandDelegate.evalJs(jsCode)
            }
        } catch {

        }
        
    }
}


//extension MSKBedfontPlugin: ConnectionObserver {
//    func bluetoothAvailable(_ available: Bool) {
//        //log(message: "Bluetooth available: \(available)")
//    }
//
//    func connected(to peripheral: PeripheralIdentifier) {
//        //log(message: "[connection observer] detected connect event")
//        //sensor = peripheral
//        //isConnectedText = "Connected"
//        self.sendStateChangeEvents(commandDelegate: self.commandDelegate, boolval: true)
//    }
//
//    func disconnected(from peripheral: PeripheralIdentifier) {
//        //log(message: "[connection observer] detected disconnect event")
//        //isConnectedText = "Disconnected"
//        self.sendStateChangeEvents(commandDelegate: self.commandDelegate, boolval: false)
//    }
//}
