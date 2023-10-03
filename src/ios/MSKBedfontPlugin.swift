//
//  MSKBedfontPlugin.swift
//
//  Created by Shishir Shetty on 2023-10-02.
//
import Foundation
import SmokerlyzerSDK
import Cordova



var smokerlyzerBluetooth = SmokerlyzerBluetooth()

@objc(MSKBedfontPlugin)
class MSKBedfontPlugin: CDVPlugin {
    
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
    
    @objc(performScanning:)func performScanning(command : CDVInvokedUrlCommand) {
        
        self.perform_Scanning()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(performDisconnection:)func performDisconnection(command : CDVInvokedUrlCommand) {
        
        self.perform_Disconnection()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(testNorecovery:)func testNorecovery(command : CDVInvokedUrlCommand) {
        
        self.perform_TestNorecovery()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(getDeviceFirmware:)func getDeviceFirmware(command : CDVInvokedUrlCommand) {
        
        self.get_DeviceFirmware()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(getDeviceSerialNumber:)func getDeviceSerialNumber(command : CDVInvokedUrlCommand) {
        
        self.get_DeviceSerialNumber()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    
    
    func perform_Scanning() {
        if smokerlyzerBluetooth != nil {
            let didScanStart = smokerlyzerBluetooth.scanForPeripheral(
                stopOnFirstResult: false,
                onDiscovery: {single, list in
                },
                onStopped: {_, error in
                    if let error = error {
                        //self.log(message: "Scan error: " + error.localizedDescription)
                        self.sendStateChangeEvents(eventName: self.BEDFONT_EVENT_SCANSTATECHANGE, boolval: false)
                    } else {
                        self.sendStateChangeEvents(eventName: self.BEDFONT_EVENT_SCANSTATECHANGE, boolval: false)
                        //self.log(message: "Scan stopped.")
                    }
                }
            )
            if didScanStart {
                self.sendStateChangeEvents(eventName: self.BEDFONT_EVENT_SCANSTATECHANGE, boolval: true)
                //self.log(message: "Scan was allowed to start.")
                self.performConnect()
            }
        }
    }
    
    
    func performConnect() {
        self.isConnectedText = "Connecting"
        let scanStarted = smokerlyzerBluetooth.scanForPeripheral(
            onDiscovery: { scan, _ in
                //self.log(message: "Peripheral found, connecting...")
                self.sendScanningEvents(connectResult: "ZEROING", logMessage: "Zeroing the sensor, please wait...")
                smokerlyzerBluetooth.connectToPeripheral(peripheral: scan.peripheralIdentifier, connected: {result in
                    switch result {
                    case .success(let peripheralId):
                        //self.log(message: "Successfully connected to " + peripheralId.name)
                        self.isConnectedText = "Connected"
                        self.sendScanningEvents(connectResult: "SUCCESS", logMessage: "Successfully connected to " + peripheralId.name)
                        self.sendStateChangeEvents(eventName: self.BEDFONT_EVENT_BUTTONNAMECHANGE, boolval: true)
                    case .failure(let error):
                        //self.log(message: "Failed to connect with error: \(error.localizedDescription)")
                        self.isConnectedText = "Disconnected"
                        self.sendScanningEvents(connectResult: "ERROR_FAILED_TO_CONNECT", logMessage: "Failed to connect with error: \(error.localizedDescription)")
                        self.sendStateChangeEvents(eventName: self.BEDFONT_EVENT_BUTTONNAMECHANGE, boolval: false)
                    }
                })
            },
            onStopped: { _, error in
                if let error = error {
                    //self.log(message: "Scan stopped with error: " + error.localizedDescription)
                }
            }
        )
        //self.log(message: "Scan (with intent to connect) started? " + scanStarted.description)
        
    }
    
    func perform_Disconnection() {
        self.sendStateChangeEvents(eventName: self.BEDFONT_EVENT_BUTTONNAMECHANGE, boolval: false)
        self.isEnabled = false
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.disconnectFromPeripheral()
        }
    }
    
    func perform_TestNorecovery() {
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.getCoppm(callback: {result in
                switch result {
                case .success(let ppm):
                    //self.log(message: "PPM value is " + String(ppm.reading))
                    self.sendScanningResults(statusName: "PPM value is " + String(ppm.reading), ppm: ppm.reading, isSuccessful: true)
                case .failure(let error):
                    //self.log(message: "Error: " + error.localizedDescription)
                    self.sendScanningResults(statusName: "Error: " + error.localizedDescription, ppm: -1, isSuccessful: false)
                }
            })
        }
        
    }
    func get_DeviceFirmware() {
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.getFirmwareVersion(callback: { result in
                switch result {
                case .success(let firmware):
                    //self.log(message: "Firmware version: " + firmware.version)
                    self.sendDeviceDetails(eventName: self.BEDFONT_EVENT_DEVICE_FIRMWARE, deviceParam: firmware.version)
                case .failure(let error):
                    //self.log(message: "Error: " + error.localizedDescription)
                    self.sendDeviceDetails(eventName: self.BEDFONT_EVENT_DEVICE_FIRMWARE, deviceParam: "Error: " + error.localizedDescription)
                }
            })
        }
    }
    
    func get_DeviceSerialNumber() {
        if smokerlyzerBluetooth != nil {
            smokerlyzerBluetooth.getSerial(callback: { result in
                switch result {
                case .success(let serial):
                    //self.log(message: "Serial number: " + serial.serial)
                    self.sendDeviceDetails(eventName: self.BEDFONT_EVENT_DEVICE_SERIALNUMBER, deviceParam: serial.serial)
                case .failure(let error):
                    //self.log(message: "Error: " + error.localizedDescription)
                    self.sendDeviceDetails(eventName: self.BEDFONT_EVENT_DEVICE_SERIALNUMBER, deviceParam: "Error: " + error.localizedDescription)
                }
            })
        }
    }
    
    func sendStateChangeEvents(eventName: String, boolval: Bool) {
        let eventData: [String: Any] = [
            "changeState": boolval
        ]
        self.fireEvent(eventName: eventName, eventData: eventData )
    }
    
    func sendScanningEvents(connectResult: String, logMessage: String) {
        let eventData: [String: Any] = [
            "connectResult": connectResult,
            "logMessage": logMessage
        ]
        self.fireEvent(eventName: self.BEDFONT_EVENT_SCAN_RESULT, eventData: eventData)
    }
    
    func sendScanningResults(statusName: String, ppm: Int, isSuccessful: Bool) {
        let eventData: [String: Any] = [
            "statusName": statusName,
            "ppm": ppm,
            "isSuccessful": isSuccessful
        ]
        self.fireEvent(eventName: self.BEDFONT_EVENT_CONNECT_RESULT, eventData: eventData)
    }
    
    func sendDeviceDetails(eventName: String, deviceParam: String) {
        let eventData: [String: Any] = [
            "deviceDetail": deviceParam
        ]
        
        self.fireEvent(eventName: eventName, eventData: eventData)
    }
    
    func fireEvent(eventName: String, eventData: [String: Any]) {
        
        do {
            // Convert the dictionary to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: eventData, options: [])
            
            // Print the JSON data as a string (for demonstration purposes)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let jsCode = "cordova.fireDocumentEvent('\(eventName)', \(jsonString));"
                self.commandDelegate!.evalJs(jsCode)
            }
        } catch {
            
        }
        
    }
}


extension MSKBedfontPlugin: ConnectionObserver {
    func bluetoothAvailable(_ available: Bool) {
        //log(message: "Bluetooth available: \(available)")
    }

    func connected(to peripheral: PeripheralIdentifier) {
        //log(message: "[connection observer] detected connect event")
        sensor = peripheral
        isConnectedText = "Connected"
        self.sendStateChangeEvents(eventName: self.BEDFONT_EVENT_BUTTONNAMECHANGE, boolval: true)
    }

    func disconnected(from peripheral: PeripheralIdentifier) {
        //log(message: "[connection observer] detected disconnect event")
        isConnectedText = "Disconnected"
        self.sendStateChangeEvents(eventName: self.BEDFONT_EVENT_BUTTONNAMECHANGE, boolval: false)
    }
}
