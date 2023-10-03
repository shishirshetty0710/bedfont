//
//  MSKBedfontPlugin.swift
//
//  Created by Shishir Shetty on 2023-10-02.
//
import Foundation
import SmokerlyzerSDK

@objc(MSKBedfontPlugin)
class MSKBedfontPlugin: CDVPlugin {
    
     let BEDFONT_EVENT_RECOVERYCHANGE = "BEDFONT_EVENT_RECOVERYCHANGE"
    
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
    
    var smokerlyzerBluetooth: Any? = nil
    
    var sensor: PeripheralIdentifier?
    var isConnectedText: String = "Disconnected"
    
    var isEnabled: Bool = false
    
    
    @objc(init:)func initialize(command : CDVInvokedUrlCommand) {
        
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
        
        perform_Scanning()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(performDisconnection:)func performDisconnection(command : CDVInvokedUrlCommand) {
        
        perform_Disconnection()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(testNorecovery:)func testNorecovery(command : CDVInvokedUrlCommand) {
        
        perform_TestNorecovery()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(getDeviceFirmware:)func getDeviceFirmware(command : CDVInvokedUrlCommand) {
        
        get_DeviceFirmware()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    @objc(getDeviceSerialNumber:)func getDeviceSerialNumber(command : CDVInvokedUrlCommand) {
        
        get_DeviceSerialNumber()
        let result = CDVPluginResult.init(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    
    
    func perform_Scanning() {
        if smokerlyzerBluetooth != nil {
            let didScanStart = smokerlyzerBluetooth.scanForPeripheral(
                stopOnFirstResult: false,
                onStopped: {_, error in
                    if let error = error {
                        //self.log(message: "Scan error: " + error.localizedDescription)
                        sendStateChangeEvents(BEDFONT_EVENT_SCANSTATECHANGE, false)
                    } else {
                        sendStateChangeEvents(BEDFONT_EVENT_SCANSTATECHANGE, false)
                        //self.log(message: "Scan stopped.")
                    }
                }
            )
            if didScanStart {
                sendStateChangeEvents(BEDFONT_EVENT_SCANSTATECHANGE, true)
                //self.log(message: "Scan was allowed to start.")
                performConnect()
            }
        }
    }
    
    
    func performConnect() {
        self.isConnectedText = "Connecting"
        let scanStarted = smokerlyzerBluetooth.scanForPeripheral(
            onDiscovery: { scan, _ in
                //self.log(message: "Peripheral found, connecting...")
                sendScanningEvents("ZEROING","Zeroing the sensor, please wait...")
                smokerlyzerBluetooth.connectToPeripheral(peripheral: scan.peripheralIdentifier, connected: {result in
                    switch result {
                    case .success(let peripheralId):
                        //self.log(message: "Successfully connected to " + peripheralId.name)
                        self.isConnectedText = "Connected"
                        sendScanningEvents("SUCCESS", "Successfully connected to " + peripheralId.name)
                        sendStateChangeEvents(BEDFONT_EVENT_BUTTONNAMECHANGE, true)
                    case .failure(let error):
                        //self.log(message: "Failed to connect with error: \(error.localizedDescription)")
                        self.isConnectedText = "Disconnected"
                        sendScanningEvents("ERROR_FAILED_TO_CONNECT", "Failed to connect with error: \(error.localizedDescription)")
                        sendStateChangeEvents(BEDFONT_EVENT_BUTTONNAMECHANGE, false)
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
        sendStateChangeEvents(BEDFONT_EVENT_BUTTONNAMECHANGE, false)
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
                    sendScanningResults("PPM value is " + String(ppm.reading), ppm.reading, true)
                case .failure(let error):
                    //self.log(message: "Error: " + error.localizedDescription)
                    sendScanningResults("Error: " + error.localizedDescription, -1, false)
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
                    sendDeviceDetails(BEDFONT_EVENT_DEVICE_FIRMWARE, firmware.version)
                case .failure(let error):
                    //self.log(message: "Error: " + error.localizedDescription)
                    sendDeviceDetails(BEDFONT_EVENT_DEVICE_FIRMWARE, "Error: " + error.localizedDescription)
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
                    sendDeviceDetails(BEDFONT_EVENT_DEVICE_SERIALNUMBER, serial.serial)
                case .failure(let error):
                    //self.log(message: "Error: " + error.localizedDescription)
                    sendDeviceDetails(BEDFONT_EVENT_DEVICE_SERIALNUMBER, "Error: " + error.localizedDescription)
                }
            })
        }
    }
    
    func sendStateChangeEvents(eventName: String, boolval: Bool) {
        let eventData = [
            "changeState": boolval
        ]
        fireEvent(eventName, eventData)
    }
    
    func sendScanningEvents(connectResult: String, logMessage: String) {
        let eventData = [
            "connectResult": connectResult,
            "logMessage": logMessage
        ]
        fireEvent(BEDFONT_EVENT_SCAN_RESULT, eventData)
    }
    
    func sendScanningResults(statusName: String, ppm: Int, isSuccessful: Bool) {
        let eventData = [
            "statusName": statusName,
            "ppm": ppm,
            "isSuccessful": isSuccessful
        ]
        fireEvent(BEDFONT_EVENT_CONNECT_RESULT, eventData)
    }
    
    func sendDeviceDetails(eventName: String, deviceParam: String) {
        
        
        fireEvent(eventName, eventData)
    }
    
    func fireEvent(eventName: String, eventData: [String: Any]) {
        let jsonData = try JSONSerialization.data(withJSONObject: eventData, options: [])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            let jsCode = "cordova.fireDocumentEvent('\(eventName)', \(jsonString));"
            self.commandDelegate!.evalJs(jsCode)
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
        sendStateChangeEvents(BEDFONT_EVENT_BUTTONNAMECHANGE, true)
    }

    func disconnected(from peripheral: PeripheralIdentifier) {
        //log(message: "[connection observer] detected disconnect event")
        isConnectedText = "Disconnected"
        sendStateChangeEvents(BEDFONT_EVENT_BUTTONNAMECHANGE, false)
    }
}
