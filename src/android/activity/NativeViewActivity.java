package com.foodlion.mobile;

import android.content.Intent;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Iterator;

/**
 * Start a native Activity. This plugin
 * use Java Reflection to decide which method
 * execute
 */
public class NativeViewActivity extends CordovaPlugin {
    private static final String TAG = "NativeViewPlugin";
    private CallbackContext callback = null;
    private final int FLYER_VIEW_RESULT_CODE = 99;

    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        Log.d(TAG, "Initializing " + TAG);
    }

    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) {
        try {
            Method method = getClass().getMethod(action, JSONArray.class, CallbackContext.class);
            try {
                callback = callbackContext;
                method.invoke(this, args, callbackContext);
                return true;
            } catch (IllegalAccessException e) {
                JSONObject error = errorResult(e);
                callbackContext.error(error);
                e.printStackTrace();
            } catch (IllegalArgumentException e) {
                JSONObject error = errorResult(e);
                callbackContext.error(error);
                e.printStackTrace();
            }catch (InvocationTargetException e) {
                JSONObject error = errorResult(e);
                callbackContext.error(error);
                e.printStackTrace();
            }
        }catch (NoSuchMethodException e) {
            String message = String.format("Method with name: %s was not found on: %s\n Reason: %s", action, getClass().getName(), e.getMessage());
            Log.d(TAG, message);
            HashMap<String, Object> data = new HashMap<String, Object>();
            data.put("message", message);
            JSONObject error = errorResult(e, data);
            callbackContext.error(error);
            e.printStackTrace();
        }
        return false;
    }

    public void show(JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (args.opt(0) instanceof JSONObject) {
            try {
                Intent intent  = new Intent("com.foodlion.mobile.FlyerActivity");
                intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                addExtraParams(args.getJSONObject(0), intent);
                cordova.setActivityResultCallback(this);
                cordova.getActivity().startActivityForResult(intent, FLYER_VIEW_RESULT_CODE);
            }catch (Exception clsErr) {
                JSONObject error = errorResult(clsErr);
                callback.error(error);
                clsErr.printStackTrace();
            }
        }else {
            Log.d(TAG,"The params of show() method needs be a json object");
        }
    }

    private void addExtraParams(JSONObject jsonObject, Intent intent) throws JSONException {
        if (jsonObject != null) {
            Iterator<?> keys = jsonObject.keys();
            while (keys.hasNext()) {
                String key = (String) keys.next();
                Object value = jsonObject.get(key);
                if(value instanceof Integer) {
                    intent.putExtra(key, jsonObject.getInt(key));
                }
                if(value instanceof String) {
                    intent.putExtra(key, jsonObject.getString(key));
                }
                if(value instanceof Boolean) {
                    intent.putExtra(key, jsonObject.getBoolean(key));
                }
            }
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if(resultCode == FLYER_VIEW_RESULT_CODE){
            callback.success();
        } else {
            return;
        }
    }

    private JSONObject errorResult(Exception e) {
        HashMap<String, Object> data = new HashMap<String, Object>();
        data.put("success", false);
        data.put("name", e.getClass().getName());
        data.put("message", e.getMessage() != null ? e.getMessage() : e.getCause().getMessage());
        JSONObject error = new JSONObject(data);
        return error;
    }

    private JSONObject errorResult(Exception e, HashMap<String, Object> extraData) {
        HashMap<String, Object> data = new HashMap<String, Object>();
        data.put("success", false);
        data.put("name", e.getClass().getName());
        data.put("message", e.getMessage() != null ? e.getMessage() : e.getCause().getMessage());
        data.putAll(extraData);
        JSONObject error = new JSONObject(data);
        return error;
    }
}
