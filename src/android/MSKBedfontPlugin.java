package org.mskcc.bedfont;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Map;
import java.util.Objects;

import android.app.Application;
import android.util.Log;

import com.bedfont.icosdk.ble.v2.*;

import io.reactivex.disposables.Disposable;

public class MSKBedfontPlugin extends CordovaPlugin {

    /***LIST OF ALL EVENTS****/
    private static final String BEDFONT_EVENT_RECOVERYCHANGE = "OnRecoveryChangeEvent";

    private static final String BEDFONT_EVENT_SCANSTATECHANGE = "OnScanStateChangeEvent";

    private static final String BEDFONT_EVENT_CONNECTIONCHANGE = "OnConnectionChangeEvent";

    private static final String BEDFONT_EVENT_CONNECTINGCHANGE = "OnCOnnectingChangeEvent";

    private static final String BEDFONT_EVENT_BUTTONNAMECHANGE = "OnButtonNameChangeEvent";

    private static final String BEDFONT_EVENT_CONNECT_RESULT = "OnConnectResultEvent";

    private static final String BEDFONT_EVENT_SCAN_RESULT = "OnScanResultEvent";

    private static final String BEDFONT_EVENT_DEVICE_USAGE = "onDeviceUsageEvent";

    private static final String BEDFONT_EVENT_DEVICE_FIRMWARE = "onDeviceFirmwareEvent";

    private static final String BEDFONT_EVENT_DEVICE_SERIALNUMBER = "onDeviceSerialNumberEvent";

    private static final String BEDFONT_EVENT_DEVICE_BATTERY = "onDeviceBatteryEvent";



    private static final String SUCCESS = "SUCCESS";
    private static final String SUCCESS_NEEDS_RECOVERY = "SUCCESS_NEEDS_RECOVERY";
    private static final String ZEROING = "ZEROING";
    private static final String ERROR_FAILED_TO_FINALIZE = "ERROR_FAILED_TO_FINALIZE";
    private static final String ERROR_FAILED_TO_CONNECT = "ERROR_FAILED_TO_CONNECT";
    private static final String ERROR_SCAN_FAILED = "ERROR_SCAN_FAILED";

    private static final String DEVICE_NOT_CONNECTED = "DEVICE_NOT_CONNECTED";

    private static final boolean STATE_DISCONNECT = true;
    private static final boolean STATE_SCAN_AND_CONNECT = false;

    private CordovaWebView webView;
    private CallbackContext callback;
    private Boolean initialized = false;

    private SmokerlyzerBluetoothLeManager smokerlyzerBluetoothLeManager;
    private Disposable connectionSubscription;
    private Disposable scanningSubscription;
    private Disposable onBackToSubscription;
    private Disposable connectingSubscription;
    private Disposable recoverySubscription;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        this.webView = webView;
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        callback = callbackContext;
        PluginResult result;

        switch (action) {

            case "initialize":
                if(!initialized) {
                    initSDK();
                    initialized=true;
                    result = new PluginResult(PluginResult.Status.OK);
                }
                else {
                    result = new PluginResult(PluginResult.Status.OK, "Already Initialized!");
                }

                result.setKeepCallback(false);
                callback.sendPluginResult(result);
                return true;

            case "dispose":
                // Cleanup subscriptions
                if(scanningSubscription!=null)
                    scanningSubscription.dispose();
                if(connectionSubscription!=null)
                    connectionSubscription.dispose();
                if(connectingSubscription!=null)
                    connectingSubscription.dispose();
                if(recoverySubscription!=null)
                    recoverySubscription.dispose();

                result = new PluginResult(PluginResult.Status.OK);
                result.setKeepCallback(false);
                callback.sendPluginResult(result);
                return true;

            case "performScanning":
                performScanning();
                result = new PluginResult(PluginResult.Status.OK);
                result.setKeepCallback(false);
                callback.sendPluginResult(result);
                return true;

            case "performDisconnection":
                perfromDisconnection();
                result = new PluginResult(PluginResult.Status.OK);
                result.setKeepCallback(false);
                callback.sendPluginResult(result);
                return true;

            case "testNorecovery":
                performTestNoRecovery();
                result = new PluginResult(PluginResult.Status.OK);
                result.setKeepCallback(false);
                callback.sendPluginResult(result);
                return true;

            case "getDeviceUsage":
                getDeviceUsage();
                result = new PluginResult(PluginResult.Status.OK);
                result.setKeepCallback(false);
                callback.sendPluginResult(result);
                return true;
            case "getDeviceFirmware":
                getDeviceFirmware();
                result = new PluginResult(PluginResult.Status.OK);
                result.setKeepCallback(false);
                callback.sendPluginResult(result);
                return true;
            case "getDeviceSerialNumber":
                getDeviceSerialNumber();
                result = new PluginResult(PluginResult.Status.OK);
                result.setKeepCallback(false);
                callback.sendPluginResult(result);
                return true;
            case "getDeviceBattery":
                 getDeviceBattery();
                 result = new PluginResult(PluginResult.Status.OK);
                 result.setKeepCallback(false);
                 callback.sendPluginResult(result);
                 return true;

        }

        return false;

    }


    private void initSDK() {
        smokerlyzerBluetoothLeManager = SmokerlyzerBluetoothLeManager.build(this.cordova.getContext());
        scanningSubscription = smokerlyzerBluetoothLeManager
                .getScanTracker()
                .getSubscription()
                .subscribe(this::scanStateChange);
        // Subscribe to listen for a disconnect
        connectionSubscription = smokerlyzerBluetoothLeManager
                .getConnectionTracker()
                .getSubscription()
                .subscribe(this::connectionChange);
        connectingSubscription = smokerlyzerBluetoothLeManager
                .getConnectingTracker()
                .getSubscription()
                .subscribe(this::connectingChange);
        recoverySubscription = smokerlyzerBluetoothLeManager
                .getRecoveryListener()
                .getSubscription()
                .subscribe(this::recoveryChange);
    }

    private void recoveryChange(Boolean aBoolean) {
        sendStateChangeEvents(BEDFONT_EVENT_RECOVERYCHANGE, aBoolean.booleanValue());
    }

    private void connectingChange(Boolean aBoolean) {
        sendStateChangeEvents(BEDFONT_EVENT_CONNECTINGCHANGE, aBoolean.booleanValue());
    }

    private void connectionChange(Boolean aBoolean) {
        sendStateChangeEvents(BEDFONT_EVENT_CONNECTIONCHANGE, aBoolean.booleanValue());
        if(aBoolean) {
            connected();
        } else {
            disconnected();
        }
    }


    private void scanStateChange(Boolean aBoolean) {
        sendStateChangeEvents(BEDFONT_EVENT_SCANSTATECHANGE, aBoolean.booleanValue());
    }




    private void connected() {
        sendStateChangeEvents(BEDFONT_EVENT_BUTTONNAMECHANGE, STATE_DISCONNECT);
    }

    private void disconnected() {
        sendStateChangeEvents(BEDFONT_EVENT_BUTTONNAMECHANGE, STATE_SCAN_AND_CONNECT);
    }


    private void performScanning() {
        if(smokerlyzerBluetoothLeManager!=null) {
            smokerlyzerBluetoothLeManager.scanAndConnect(new String[]{"iCOquit"}, connectResult -> {
                switch(connectResult) {
                    case SUCCESS:
                        sendScanningEvents(SUCCESS, "Finalized connection. Device is READY");
                        break;
                    case SUCCESS_NEEDS_RECOVERY:
                        sendScanningEvents(SUCCESS_NEEDS_RECOVERY,"Finalized connection. Recovery function needs to be run on the sensor");
                        break;
                    case ZEROING:
                        sendScanningEvents(ZEROING,"Zeroing the sensor, please wait...");
                        break;
                    case ERROR_FAILED_TO_FINALIZE:
                        sendScanningEvents(ERROR_FAILED_TO_FINALIZE,"Connection process failed to finalize.");
                        break;
                    case ERROR_FAILED_TO_CONNECT:
                        sendScanningEvents(ERROR_FAILED_TO_CONNECT,"Failed to connect to device");
                        break;
                    case ERROR_SCAN_FAILED:
                        sendScanningEvents(ERROR_SCAN_FAILED,"Failed to find device");
                        break;
                }
            });
        }
    }

    private void perfromDisconnection() {

        if(smokerlyzerBluetoothLeManager!=null)
            smokerlyzerBluetoothLeManager.disconnect();
        disconnected();
    }


    private void performTestNoRecovery() {
        if(smokerlyzerBluetoothLeManager!=null)
            smokerlyzerBluetoothLeManager.getIsConnected((isConnected) -> {
                if(isConnected) {
                    smokerlyzerBluetoothLeManager.startBreathTestNoRecovery(this::onBreathTestComplete);
                }
                else {
                    sendScanningEvents(DEVICE_NOT_CONNECTED,"Device is not connected");
                }
            });
    }


    public void onBreathTestComplete(boolean isSuccessful, int ppm, SmokerlyzerBluetoothLeManager.StatusCodeConstants status) {

        if(isSuccessful && status == SmokerlyzerBluetoothLeManager.StatusCodeConstants.SUCCESS){
            sendScanningResults(status.name(), ppm, isSuccessful);
        } else if (status == SmokerlyzerBluetoothLeManager.StatusCodeConstants.ERROR_ZEROING_REQUIRED) {
            sendScanningResults(status.name(), -1, isSuccessful);
        }
        else if (status == SmokerlyzerBluetoothLeManager.StatusCodeConstants.ERROR_DEVICE_NOT_READY) {
            sendScanningResults(status.name(), -1, isSuccessful);
        }
        else{
            sendScanningResults(status.name(), -1, isSuccessful);
        }

    }

    private void getDeviceUsage() {
        if(smokerlyzerBluetoothLeManager!=null)
            smokerlyzerBluetoothLeManager.getIsConnected((r2) -> {
                if (r2) {
                    smokerlyzerBluetoothLeManager.getUsage((r) -> {
                        sendDeviceDetails(BEDFONT_EVENT_DEVICE_USAGE, ""+r);
                    });
                } else{
                    sendDeviceDetails(BEDFONT_EVENT_DEVICE_USAGE, "Device Not Connected");
                }
            });
    }

    private void getDeviceFirmware() {
        if(smokerlyzerBluetoothLeManager!=null)
            smokerlyzerBluetoothLeManager.getIsConnected((r2) -> {
                if (r2) {
                    smokerlyzerBluetoothLeManager.getFirmwareVersion((r) -> {
                        sendDeviceDetails(BEDFONT_EVENT_DEVICE_FIRMWARE, ""+r);
                    });
                } else{
                    sendDeviceDetails(BEDFONT_EVENT_DEVICE_FIRMWARE, "Device Not Connected");
                }
            });
    }

    private void getDeviceSerialNumber() {
        if(smokerlyzerBluetoothLeManager!=null)
            smokerlyzerBluetoothLeManager.getIsConnected((r2) -> {
                if (r2) {
                    smokerlyzerBluetoothLeManager.getSerialNumber((r) -> {
                        sendDeviceDetails(BEDFONT_EVENT_DEVICE_SERIALNUMBER, ""+r);
                    });
                } else{
                    sendDeviceDetails(BEDFONT_EVENT_DEVICE_SERIALNUMBER, "Device Not Connected");
                }
            });
    }

    private void getDeviceBattery() {
        if(smokerlyzerBluetoothLeManager!=null)
            smokerlyzerBluetoothLeManager.getIsConnected((r2) -> {
                if (r2) {
                    smokerlyzerBluetoothLeManager.getBatteryReading((r) -> {
                        sendDeviceDetails(BEDFONT_EVENT_DEVICE_BATTERY, ""+r);
                    });
                } else{
                    sendDeviceDetails(BEDFONT_EVENT_DEVICE_BATTERY, "Device Not Connected");
                }
            });
    }



    public void sendStateChangeEvents(String eventName, boolean boolVal) {

        JSONObject params = new JSONObject();
        try {
            params.put("changeState", boolVal);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        fireEvent(eventName, params);
    }

    public void sendScanningEvents(String connectResult, String logMessage) {

        JSONObject params = new JSONObject();
        try {
            params.put("connectResult", connectResult);
            params.put("logMessage", logMessage);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        fireEvent(BEDFONT_EVENT_CONNECT_RESULT, params);
    }

    public void sendScanningResults(String statusName, int ppm, boolean isSuccessful) {

        JSONObject params = new JSONObject();
        try {
            params.put("statusName", statusName);
            params.put("ppm", ppm);
            params.put("isSuccessful", isSuccessful);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        fireEvent(BEDFONT_EVENT_SCAN_RESULT, params);
    }

    public void sendDeviceDetails(String eventName, String deviceParam) {

        JSONObject params = new JSONObject();
        try {
            params.put("deviceDetail", deviceParam);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        fireEvent(eventName, params);
    }

    public void fireEvent(String eventName, JSONObject params) {
        showToast(params.toString());
        String js = "cordova.fireDocumentEvent('" + eventName + "', " + params.toString() + ");";
        webView.getView().post(() -> webView.loadUrl("javascript:" + js));
    }

    private void showToast(String message) {
//        final android.widget.Toast toast = android.widget.Toast.makeText(cordova.getActivity().getWindow().getContext(), message, android.widget.Toast.LENGTH_LONG);
//        toast.show();
        Log.d("Bedfont", message);
    }
}
