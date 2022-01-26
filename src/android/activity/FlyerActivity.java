package com.foodlion.mobile;

import android.app.AlertDialog;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.app.Activity;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import androidx.databinding.DataBindingUtil;
import android.graphics.Color;
import android.graphics.RectF;
import android.graphics.drawable.Drawable;
import android.os.AsyncTask;
import android.os.Bundle;
import androidx.core.content.ContextCompat;
import androidx.appcompat.app.AppCompatActivity;
import android.util.Log;
import android.view.Display;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.TextView;

import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.NoConnectionError;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.TimeoutError;
import com.android.volley.VolleyError;
import com.android.volley.VolleyLog;
import com.android.volley.toolbox.JsonArrayRequest;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;
import com.flipp.flyerkit.FlyerView;
import com.foodlion.mobile.databinding.ActivityFlyerBinding;
import com.google.android.gms.common.api.PendingResult;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.tagmanager.Container;
import com.google.android.gms.tagmanager.ContainerHolder;
import com.google.android.gms.tagmanager.DataLayer;
import com.google.android.gms.tagmanager.TagManager;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import android.content.Intent;
/**
 * Created by Ashish on 11/18/2016.
 */

 enum WeeklySpecialAction {
    add_to_list("add to list"),
    open_item("open item"),
    share_flyer("share flyer"),
    remove_from_list("remove from list"),
    share_item("share item"),
    select_location("select location"),
    select_store("select store"),
    select_flyer("select flyer"),
    open_flyer("open flyer"),
    read("read"),
    pan("pan"),
    export_pdf("export pdf"),
    select_category("select category"),
    apply_discount_filter("apply discount filter");

    private String value;
    public String getValue() {
       return value;
      }
    private WeeklySpecialAction(String value) {
     this.value = value;
    } 
 }

 class DataLayerModel {
    String event= "weekly-special-event";
    WeeklySpecialAction weeklySpecialAction;
    String item_id;

    @Override
    public String toString()
    {
         return "event: " + event + " weeklySpecialAction: " + weeklySpecialAction.getValue() + " item_id: " + item_id + " ";
    }    
}

interface PanEventListener {
    public void onSuccess(Boolean res);
    public void onFailure(Exception e);
}

public class FlyerActivity extends AppCompatActivity {

    private String LOGTAG = this.getClass().getSimpleName();
    private final int FLYER_VIEW_RESULT_CODE = 99;
    Utils utils;
    private ActivityFlyerBinding mBinding;
    private RequestQueue mRequestQueue;
    //String postalCode = "L4W1L6";
    final String accessToken = "2536a66d";

    final String locale = "en-CA";
    final String merchantIdentifier = "foodlion";
    final String rootUrl = "https://api.flipp.com/";
    final String apiVersion = "v2.0";
    private String mStoreId = "0001";
    String productUpc, productName, itemId, categoryType, strName;

    int defaultFlyerId = 0;
    public int checkClickOperation = 0;

    private JSONArray mFlyerItems;
    private final Set<JSONObject> mClippings = new HashSet<JSONObject>();
    ArrayList<String> listNameArray = new ArrayList<String>();
    Map<String, String> listNameId = new TreeMap<String, String>();
    Boolean listItemClicked = false;
    ProgressDialog flyerProgressDialog;
    // Google Tag Manager
    private int flyer_run_id, flyer_type_id, flyer_postal_code;
    String flyer_client_id = "";
    private static final long TIMEOUT_FOR_CONTAINER_OPEN_MILLISECONDS = 500;
    private static final String CONTAINER_ID = "GTM-MMZ4FVG";
    String GETALLSHOPPINGLIST;
    String signInMode;
    String accessTokenForAPI;
    String hmacPrivateKeyFromhybrid;
    String hmacPublicKeyFromhybrid;
    String oauthSignatureMethodFromhybrid;
    String oauthVersionFromhybrid;
    String headerMulesoftClientIdFromhybrid;
    String headerMulesoftClientSecretFromhybrid;
    String appIdFromhybrid;
    String  API_BASE_URL;
    String CLIENT_ID;
    private String clientId;
    private DataLayer dataLayer;
    boolean isPanning=false;
    boolean didFinishedPanning=true;
    boolean isFlyerLoaded=false;
    public static final String REQ_TAG = "WEEKLYFLYER";
    RequestQueue.RequestFinishedListener myRequestListener;

    /*MD5:99:6A:8B:C5:97:44:90:6A:FF:3C:7C:53:06:07:54:72
      SHA1: D3:DC:7D:2D:A0:17:67:98:30:0D:D1:C7:11:96:A8:35:80:E9:0F:4C
      SHA256: 6C:14:98:3D:FB:A0:F1:81:68:86:62:F7:15:35:E1:05:B7:9B:22:E6:09:40:85:EA:CF:7F:EF:A2:40:6D:8C:6B*/

    private class ItemAnnotation implements FlyerView.TapAnnotation {
        private final RectF mRect;
        private final JSONObject mObject;

        public ItemAnnotation(RectF rect, JSONObject object) {
            mRect = rect;
            mObject = object;
        }

        @Override
        public RectF getTapRect() {
            return mRect;
        }

        public JSONObject getFlyerItem() {
            return mObject;
        }
    }

    private void updateBadges() {
        List<FlyerView.BadgeAnnotation> badgeAnnotations = new ArrayList<FlyerView.BadgeAnnotation>();
        for (JSONObject item : mClippings) {
            try {
                float left = (float) item.getDouble("left");
                float top = (float) item.getDouble("top");
                float width = (float) item.getDouble("width");
                float height = (float) item.getDouble("height");

                final RectF rect = new RectF(left, top, left + width, top + height);
                final Drawable drawable = ContextCompat.getDrawable(this, R.drawable.badge);

                FlyerView.BadgeAnnotation annotation = new FlyerView.BadgeAnnotation() {
                    @Override
                    public RectF getBadgeRect() {
                        return rect;
                    }

                    @Override
                    public Drawable getBadgeDrawable() {
                        return drawable;
                    }

                    @Override
                    public boolean isZoomIndependent() {
                        // clippings are not scaled as they should remain "circling" the item no matter how zoomed in/out
                        return true;
                    }
                };
                badgeAnnotations.add(annotation);
            } catch (JSONException e) {
                // Skip item.
            }
        }
        mBinding.flyerView.setBadgeAnnotations(badgeAnnotations);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        signInMode = getIntent().getStringExtra("signInMode");
        accessTokenForAPI = getIntent().getStringExtra("accessToken");
        hmacPrivateKeyFromhybrid = getIntent().getStringExtra("HMACPRIVATEKEY");
        hmacPublicKeyFromhybrid = getIntent().getStringExtra("HMACPUBLICKEY");
        oauthSignatureMethodFromhybrid = getIntent().getStringExtra("OAUTHSIGNATUREMETHOD");
        oauthVersionFromhybrid = getIntent().getStringExtra("OAUTHVERSION");
        headerMulesoftClientIdFromhybrid = getIntent().getStringExtra("mulesoftClientID");
        headerMulesoftClientSecretFromhybrid = getIntent().getStringExtra("mulesoftClientSecret");
        appIdFromhybrid = getIntent().getStringExtra("APPID");
        API_BASE_URL = getIntent().getStringExtra("shoppinglisturl");
        CLIENT_ID = getIntent().getStringExtra("CLIENTID");
        flyer_client_id = CLIENT_ID;

        //get ga client id
        SharedPreferences sharedPreferences = getApplicationContext().getSharedPreferences("FoodlionApp", MODE_PRIVATE);
        clientId = sharedPreferences.getString("gaClientId", "");

        // initialize GTM
        final TagManager tagManger = TagManager.getInstance(FlyerActivity.this);

        PendingResult<ContainerHolder> pending = tagManger.loadContainerPreferNonDefault(
                CONTAINER_ID,R.raw.gtm_android_binary_default );
        pending.setResultCallback(new ResultCallback<ContainerHolder>() {
            @Override
            public void onResult(ContainerHolder containerHolder) {
                containerHolder.refresh();
                ContainerHolderSingleton.setContainerHolder(containerHolder);
                Container container = containerHolder.getContainer();
                if (!containerHolder.getStatus().isSuccess()) {
                    Log.e("Print View", "Failed to load GTM container");
                    return;
                }
                Log.i("Print View", "LOADED GTM CONTAINER");

                ContainerLoadedCallback.registerCallbacksForContainer(container);
                containerHolder.setContainerAvailableListener(new ContainerLoadedCallback());

                // //get ga client id
                // SharedPreferences sharedPreferences = getApplicationContext().getSharedPreferences("FoodlionApp", MODE_PRIVATE);
                // String clientId = sharedPreferences.getString("gaClientId", "");
                // Log.i("FlyerActivity client id", clientId);

                // DataLayer dataLayer = tagManger.getDataLayer();
                // dataLayer.push(DataLayer.mapOf(
                //         "event", "weekly-special-event",
                //         "clientId", clientId,
                //         "weeklySpecialAction", "list_add",
                //         "flyer_type_id", flyer_type_id,
                //         "flyer_run_id", flyer_run_id,
                //         "flyer_id", defaultFlyerId,
                //         "store_id", mStoreId,
                //         "postal_code", flyer_postal_code,
                //         "item_id", itemId1 ));

                dataLayer = tagManger.getDataLayer();
            }
        }, TIMEOUT_FOR_CONTAINER_OPEN_MILLISECONDS, TimeUnit.MILLISECONDS);

        


        mStoreId = getIntent().getStringExtra("STOREID");
        if (mStoreId.equals("")){
            mStoreId = "0001";
            System.out.println("Added default storeId 0001 to this app..");
        }

        
        myRequestListener = new RequestQueue.RequestFinishedListener() {

            public void onRequestFinished(Request request) {
                if(request != null && String.valueOf(request.getTag()) == REQ_TAG) {
                    if (flyerProgressDialog.isShowing()){
                        flyerProgressDialog.dismiss();
                    }

                }
            }
            
        };

        mRequestQueue = Volley.newRequestQueue(this);
        mRequestQueue.addRequestFinishedListener(myRequestListener);

        mBinding = DataBindingUtil.setContentView(this, R.layout.activity_flyer);

        getSupportActionBar().setTitle("Weekly Flyer Print View");

        loadFlyer();

        mBinding.flyerView.setFlyerViewListener(new FlyerView.FlyerViewListener() {
            @Override
            public void onSingleTap(FlyerView flyerView, FlyerView.TapAnnotation tapAnnotation, int i, int i1) {
                if (tapAnnotation != null && tapAnnotation instanceof ItemAnnotation) {
                    Log.e("FlyerActivity", "Single Click " +((ItemAnnotation)tapAnnotation).getFlyerItem());
                    ItemAnnotation tapAnnotation1 = (ItemAnnotation)tapAnnotation;
                    JSONObject flyerItem = tapAnnotation1.getFlyerItem();

                    if (mClippings.contains(flyerItem)) {
                        mClippings.remove(flyerItem);
                    } else {
                        mClippings.clear();
                        mClippings.add(flyerItem);
                        JSONObject requestBodyJson = ((ItemAnnotation) tapAnnotation).getFlyerItem();
                        utils = new Utils();

                        productUpc = upc(requestBodyJson.optString("sku"));
                        productName = requestBodyJson.optString("name");
                        // clear itemID before so will get id of newly Tapped flyer item
                        itemId = "";

                        itemId = requestBodyJson.optString("id");
                        // track gtm action "select flyer"
                        DataLayerModel dataLayerModelObj = new DataLayerModel();
                        dataLayerModelObj.weeklySpecialAction = WeeklySpecialAction.select_flyer;
                        dataLayerModelObj.item_id = itemId;
                        gtmDataLayerPush(dataLayerModelObj);
                        categoryType = requestBodyJson.optString("category");
                        String url = API_BASE_URL.substring(0,(API_BASE_URL.length())-1);
                        GETALLSHOPPINGLIST = url+"?t=" + accessTokenForAPI; // + "&a=" + appIdFromhybrid;
                        listNameArray = new ArrayList<String>();

                        if (signInMode.equals("0")){
                            System.out.println("Guest user");

                            LayoutInflater factory = LayoutInflater.from(FlyerActivity.this);
                            final View deleteDialogView = factory.inflate(R.layout.guest_popup, null);

                            final AlertDialog addItemDialog = new AlertDialog.Builder(FlyerActivity.this).create();
                            addItemDialog.setView(deleteDialogView);

                            deleteDialogView.findViewById(R.id.ok_footer).setOnClickListener(new View.OnClickListener() {
                                @Override
                                public void onClick(View view) {
                                    addItemDialog.dismiss();
                                }
                            });
                            addItemDialog.show();
                        }else {
                            gettingShoppingListFromServer(GETALLSHOPPINGLIST, hmacPrivateKeyFromhybrid, hmacPublicKeyFromhybrid,
                                    oauthSignatureMethodFromhybrid, oauthVersionFromhybrid, headerMulesoftClientIdFromhybrid,headerMulesoftClientSecretFromhybrid, appIdFromhybrid,
                                    accessTokenForAPI,API_BASE_URL);
                        }
                    }
                    updateBadges();
                }
            }

            @Override
            public void onDoubleTap(FlyerView flyerView, FlyerView.TapAnnotation tapAnnotation, int i, int i1) {
                // do for double click
            }

            @Override
            public void onLongPress(FlyerView flyerView, FlyerView.TapAnnotation annotation, int x, int y) {
                // do for long press
            }

            @Override
            public void onScroll(FlyerView flyerView) {
                System.out.println("On scroll");
                if (!isPanning && didFinishedPanning && isFlyerLoaded) {
                    
                    ProcessPanning someTask = new ProcessPanning(new PanEventListener() {
                        @Override
                        public void onSuccess(Boolean result) {
                            didFinishedPanning=result;
                            isPanning = false;
                        }
                        
                        @Override
                        public void onFailure(Exception e) {
                            didFinishedPanning=true;
                            isPanning = false;
                        }
                    });
                    Boolean[] array = new Boolean[1];
                    array[0]=isPanning;
                    someTask.execute(array);
                }
            }

            @Override
            public void onFlyerLoading(FlyerView flyerView) {
                System.out.println("Flayer loading");
            }

            @Override
            public void onFlyerLoaded(FlyerView flyerView) {
                System.out.println("Flayer loaded");
                isFlyerLoaded=true;
            }

            @Override
            public void onFlyerLoadError(FlyerView flyerView, Exception e) {
                System.out.println("Flyer Load Error");
            }
        });
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (mRequestQueue != null) {
            mRequestQueue.removeRequestFinishedListener(myRequestListener);
        }

    }


    private void gettingShoppingListFromServer(String getallshoppinglist, final String hmacPrivateKey,
                                               final String hmacPublicKey, final String oauthSignatureMethod,
                                               final String oauthVersion, final String headerMulesoftClientIdFromhybrid, final String headerMulesoftClientSecretFromhybrid,
                                               final String appId, final String accessTokenn, final String API_BASE_URL) {
        final ProgressDialog pd;
        pd= new ProgressDialog(FlyerActivity.this);
        pd.setMessage("Loading");
        pd.show();

        final String Msg = "user/lists?t=" + accessTokenn;

        JsonObjectRequest jsObjRequest = new JsonObjectRequest(Request.Method.GET, getallshoppinglist, null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject response) {
                        try {
                            VolleyLog.v("Response:%n %s", response.toString(4));
                            pd.dismiss();
                            listNameArray.clear();
                            JSONArray jArray1 = response.getJSONArray("lists");
                            for (int i = 0; i < jArray1.length(); i++) {
                                JSONObject jObject = (JSONObject) jArray1.getJSONObject(i);
                                String listName = jObject.optString("listName");
                                String listId = jObject.optString("listId");
                                listNameArray.add(listName.toUpperCase());
                                listNameId.put(listName.toUpperCase(), listId);
                            }
                            Collections.sort(listNameArray);


                            if (listNameArray.size() == 1 && listNameId.size() == 1){
                                checkClickOperation = 1;
                                strName = listNameArray.get(0);
                                if (strName != null) {
                                    listItemClicked = true;
                                }
                                String selectedItem = listNameId.get(strName);
                                new AddItemClass().execute(hmacPrivateKey, hmacPublicKey, oauthSignatureMethod, oauthVersion,
                                         headerMulesoftClientIdFromhybrid, headerMulesoftClientSecretFromhybrid, accessTokenn, appId, selectedItem,API_BASE_URL);

                            } else if (listNameArray.size() >1 && listNameId.size() >1){
                                AlertDialog.Builder alertDioalog = new AlertDialog.Builder(FlyerActivity.this);
                                alertDioalog.setTitle("Select a List:");

                                final ArrayAdapter<String> arrayAdapter = new ArrayAdapter<String>(FlyerActivity.this,
                                        android.R.layout.simple_list_item_1, listNameArray);

                                alertDioalog.setPositiveButton("Create new List", new DialogInterface.OnClickListener() {
                                    @Override
                                    public void onClick(DialogInterface dialogInterface, int i) {
                                        LayoutInflater factory = LayoutInflater.from(FlyerActivity.this);
                                        final View deleteDialogView = factory.inflate(R.layout.create_popup, null);

                                        final AlertDialog addItemDialog = new AlertDialog.Builder(FlyerActivity.this).create();
                                        addItemDialog.setView(deleteDialogView);

                                        deleteDialogView.findViewById(R.id.ok_create_footer).setOnClickListener(new View.OnClickListener() {
                                            @Override
                                            public void onClick(View view) {
                                                EditText newListName = (EditText) deleteDialogView.findViewById(R.id.create_list);
                                                if (newListName.getText().toString() != null || newListName.getText().toString() != ""){
                                                    String newListNameStr = newListName.getText().toString();
                                                    boolean isListfound= false;
                                                    for(String listname : listNameArray) {
                                                        if(newListNameStr.equalsIgnoreCase(listname)) {
                                                            isListfound=true;
                                                            break;
                                                        }
                                                    }
                                                    if(!isListfound)
                                                    {
                                                        new PostClass().execute(hmacPrivateKey, hmacPublicKey, oauthSignatureMethod,
                                                                oauthVersion ,headerMulesoftClientIdFromhybrid, headerMulesoftClientSecretFromhybrid, accessTokenn, appId, newListNameStr,API_BASE_URL);
                                                        addItemDialog.dismiss();
                                                        gettingShoppingListFromServer(GETALLSHOPPINGLIST, hmacPrivateKeyFromhybrid, hmacPublicKeyFromhybrid,
                                                                oauthSignatureMethodFromhybrid, oauthVersionFromhybrid, headerMulesoftClientIdFromhybrid, headerMulesoftClientSecretFromhybrid, appIdFromhybrid,
                                                                accessTokenForAPI,API_BASE_URL);
                                                    }
                                                    else
                                                    {
                                                        final AlertDialog alertDialog = new AlertDialog.Builder(
                                                                FlyerActivity.this).create();
                                                        alertDialog.setTitle("Warning");

                                                        alertDialog.setMessage(newListNameStr+" already exists in list");

                                                        alertDialog.setButton("OK", new DialogInterface.OnClickListener() {
                                                            public void onClick(DialogInterface dialog, int which) {
                                                                alertDialog.dismiss();
                                                            }
                                                        });
                                                        alertDialog.show();                                                  }

                                                }
                                            }


                                        });


                                        addItemDialog.show();

                                    }
                                });

                                alertDioalog.setAdapter(arrayAdapter, new DialogInterface.OnClickListener() {
                                    @Override
                                    public void onClick(DialogInterface dialogInterface, int i) {
                                        checkClickOperation = 1;
                                        strName = arrayAdapter.getItem(i);
                                        if (strName != null) {
                                            listItemClicked = true;
                                        }
                                        String selectedItem = listNameId.get(strName);
                                        new AddItemClass().execute(hmacPrivateKey, hmacPublicKey, oauthSignatureMethod, oauthVersion,
                                                 headerMulesoftClientIdFromhybrid, headerMulesoftClientSecretFromhybrid, accessTokenn, appId, selectedItem,API_BASE_URL);

                                    }
                                });


                                //alertDioalog.show();
                                Display display = getWindowManager().getDefaultDisplay();
                                int mwidth = display.getWidth();
                                int mheight = display.getHeight();

                                Dialog dialog = alertDioalog.create();
                                Window dialogWindow = dialog.getWindow();
                                WindowManager.LayoutParams lp = dialogWindow.getAttributes();
                                dialogWindow.setGravity(Gravity.BOTTOM);

                                dialog.show();
                                dialog.getWindow().setLayout(mwidth, mheight/2);
                            }

                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        pd.dismiss();
                        VolleyLog.e("Error: not getting Item Id", error.getMessage());

                        if (error instanceof TimeoutError || error instanceof NoConnectionError) {
                            showErrorDialog("Network Error","The App is not able to access the Internet. Please check data connection on your phone and try again.");
                        } else {
                            showErrorDialog("Error","An unexpected problem occurred.  Please try again.  If the problem persists, please call Customer Service at 1-800-210-9569.");
                        }

                    }
                }) {
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                HashMap<String, String> params = new HashMap<String, String>();
                params.put("client_id", headerMulesoftClientIdFromhybrid);
                params.put("client_secret", headerMulesoftClientSecretFromhybrid);
                //params.put("content-type", "application/json");
                //params.put("oauth_signature", utils.getSignature(Msg, "GET", null, hmacPrivateKey, String.valueOf((System.currentTimeMillis() / 1000))));
                //params.put("oauth_nonce", String.valueOf((System.currentTimeMillis())) + ' ' + UUID.randomUUID().toString());
                //params.put("oauth_version", oauthVersion);
                params.put("Accept", "application/json");
                //params.put("oauth_signature_method", oauthSignatureMethod);
               // params.put("oauth_consumer_key", hmacPublicKey);
                //params.put("oauth_timestamp", String.valueOf((System.currentTimeMillis() / 1000)));
                System.out.println("params get==" + params);
                return params;
            }
        };

        jsObjRequest.setRetryPolicy(new DefaultRetryPolicy(DefaultRetryPolicy.DEFAULT_TIMEOUT_MS,
                0, DefaultRetryPolicy.DEFAULT_BACKOFF_MULT));
        mRequestQueue.add(jsObjRequest);
    }


    private String upc(String sku) {
        // while (sku.startsWith("0")) {
        //     sku = sku.substring(1);
        // }
        System.out.println("sku=" + sku);
        if (sku.endsWith("0")) {
            sku = sku.substring(0, sku.length() - 1);
            System.out.println("sku=" + sku);
        }
        return sku;
    }

    private void fetchFlyers(){
        mBinding.flyerView.setFlyerId(defaultFlyerId, accessToken, rootUrl, apiVersion);

        String itemsUrl = rootUrl + "flyerkit/" + apiVersion + "/publication/" +
                defaultFlyerId + "/products?access_token=" + accessToken + "&display_type=1,5,3,25,7,15";
        Log.d("FlyerActivity", "Flyer Products URL: " + itemsUrl);

        JsonArrayRequest itemsRequest =
                new JsonArrayRequest(itemsUrl, new Response.Listener<JSONArray>() {
                    @Override
                    public void onResponse(JSONArray response) {
                        // Log.d("FetchFlyers: ","JsonArray Response="+response.toString());
                        mFlyerItems = response;
                        System.out.println("mFlyerItems.length()==" + mFlyerItems.length());
                        List<FlyerView.TapAnnotation> tapAnnotations = new ArrayList<FlyerView.TapAnnotation>();
                        for (int i = 0, n = mFlyerItems.length(); i < n; ++i) {
                            try {
                                JSONObject item = mFlyerItems.getJSONObject(i);
                                float left = (float) item.getDouble("left");
                                float top = (float) item.getDouble("top");
                                float width = (float) item.getDouble("width");
                                float height = (float) item.getDouble("height");
                                RectF rect = new RectF(left, top, left + width, top + height);
                                //System.out.println("RectF=left-- " + left + " top--" + top + " width--" + width + " height--" + height);
                                FlyerView.TapAnnotation annotation =
                                        new ItemAnnotation(rect, item);
                                String validStartStr = item.getString("valid_from");
                                String validEndStr = item.getString("valid_to");
                                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                                try {
                                    Date validStartDate = sdf.parse(validStartStr);
                                    Date validEndDate = sdf.parse(validEndStr);
                                    validEndDate.setTime(validEndDate.getTime() + ((24 * 60 * 60 * 1000) - 1000));
                                    Date curDate = new Date();
                                    Log.d(LOGTAG, validStartDate.toString());
                                    Log.d(LOGTAG, validEndDate.toString());
                                    Log.d(LOGTAG, curDate.toString());
                                    if (curDate.before(validStartDate) || curDate.after(validEndDate)) {
                                        // no-op
                                        Log.d("FlyerActivity", "current date falls outside " + validStartStr + " - " + validEndStr);
                                    } else {
                                        tapAnnotations.add(annotation);
                                        Log.d("FlyerActivity", "current date is valid between " + validStartStr + " - " + validEndStr);

                                    }
                                } catch (ParseException e) {
                                    e.printStackTrace();
                                }
                            } catch (JSONException e) {
                                // Skip item.
                            }
                        }
                        mBinding.flyerView.setTapAnnotations(tapAnnotations);
                        updateBadges();
                    }
                }, new Response.ErrorListener() {

                    @Override
                    public void onErrorResponse(VolleyError error) {
                        VolleyLog.e("JsonArray Error=" + error);

                        if (error instanceof TimeoutError || error instanceof NoConnectionError) {
                            showErrorDialog("Network Error","The App is not able to access the Internet. Please check data connection on your phone and try again.");
                        } else {
                            showErrorDialog("Error","An unexpected problem occurred.  Please try again.  If the problem persists, please call Customer Service at 1-800-210-9569.");
                        }


                    }
                });
        itemsRequest.setTag(REQ_TAG);
        mRequestQueue.add(itemsRequest);
    }


    private void loadFlyer() {

        flyerProgressDialog= new ProgressDialog(FlyerActivity.this);
        flyerProgressDialog.setMessage("Loading");
        flyerProgressDialog.setCancelable(false);
        flyerProgressDialog.show();

        String urlFlyer = rootUrl + "flyerkit/" + apiVersion + "/publications/" +
                merchantIdentifier + "?store_code=" + mStoreId + "&locale=" +
                locale + "&access_token=" + accessToken;

        JsonArrayRequest flipRequest = new JsonArrayRequest(urlFlyer, new Response.Listener<JSONArray>() {
            @Override
            public void onResponse(JSONArray response) {
                // Log.d("LoadFlyer: ","JsonArray Response="+response.toString());
                try {
                    for (int i=0; i < response.length(); i++) {
                        JSONObject flipJsonObj = new JSONObject();
                        flipJsonObj = response.getJSONObject(i);
                        defaultFlyerId = flipJsonObj.getInt("id");
                        flyer_run_id = flipJsonObj.getInt("flyer_run_id");
                        flyer_type_id = flipJsonObj.getInt("flyer_type_id");
                        flyer_postal_code = flipJsonObj.getInt("postal_code");

                        String validStartStr = flipJsonObj.getString("valid_from");
                        String validEndStr = flipJsonObj.getString("valid_to");
                        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'hh:mm:ss");
                        try {
                            Date validStartDate = sdf.parse(validStartStr);
                            Date validEndDate = sdf.parse(validEndStr);
                            Date curDate = new Date();
                            Log.d(LOGTAG, validStartDate.toString());
                            Log.d(LOGTAG, validEndDate.toString());
                            Log.d(LOGTAG, curDate.toString());
                            if (curDate.before(validStartDate) || curDate.after(validEndDate)) {
                                // no-op
                                Log.d("FlyerActivity", "current date falls outside " + validStartStr + " - " + validEndStr);
                            } else {
                                Log.d("FlyerActivity", "current date is valid between " + validStartStr + " - " + validEndStr);
                                DataLayerModel dataLayerModelObj = new DataLayerModel();
                                dataLayerModelObj.weeklySpecialAction = WeeklySpecialAction.open_flyer;
                                gtmDataLayerPush(dataLayerModelObj);
                                fetchFlyers();
                                break;
                            }
                        } catch (ParseException e) {
                            e.printStackTrace();
                        }
                    }

                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }, new Response.ErrorListener() {

            @Override
            public void onErrorResponse(VolleyError error) {

                VolleyLog.e("JsonArray Error=" + error);

                if (error instanceof TimeoutError || error instanceof NoConnectionError) {
                    showErrorDialog("Network Error", "The App is not able to access the Internet. Please check data connection on your phone and try again.");
                } else {
                    showErrorDialog("Error","An unexpected problem occurred.  Please try again.  If the problem persists, please call Customer Service at 1-800-210-9569.");
                }

            }
        });
        mRequestQueue.add(flipRequest);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.flyer_menu_main, menu);
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.action_settings:
                Intent returnIntent = new Intent();
                setResult(FLYER_VIEW_RESULT_CODE,returnIntent);
                finish();
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }


    private class GetShoppingListClass extends AsyncTask<String, Void, Void> {
        private ProgressDialog pd;

        @Override
        protected void onPreExecute() {
            pd= new ProgressDialog(FlyerActivity.this);
            pd.setMessage("Loading");
            pd.show();
        }

        @Override
        protected Void doInBackground(String... strings) {
            String getallshoppinglist = strings[0];
            String hmacPrivateKey = strings[1];
            String hmacPublicKey = strings[2];
            String oauthSignatureMethod = strings[3];
            String oauthVersion = strings[4];
            String appId = strings[5];
            String accessTokenn = strings[6];

            try{
                URL url = new URL(getallshoppinglist);
                final String Msg = "user/lists?t=" + accessTokenn + "&a=" + appId;

                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("GET");
                //connection.setRequestProperty("oauth_consumer_key", hmacPublicKey);
                //connection.setRequestProperty("oauth_timestamp", String.valueOf((System.currentTimeMillis() / 1000)));
                //connection.setRequestProperty("oauth_signature_method", oauthSignatureMethod);
                //connection.setRequestProperty("oauth_version", oauthVersion);
                //connection.setRequestProperty("oauth_signature", utils.getSignature(Msg, "GET", null, hmacPrivateKey, String.valueOf((System.currentTimeMillis() / 1000))));
                //connection.setRequestProperty("oauth_nonce", String.valueOf((System.currentTimeMillis())) + ' ' + UUID.randomUUID().toString());
                //connection.setRequestProperty("content-type", "application/json");
                connection.setRequestProperty("Accept", "application/json");
                connection.setRequestProperty("client_id", headerMulesoftClientIdFromhybrid);
                connection.setRequestProperty("client_secret", headerMulesoftClientSecretFromhybrid);
                connection.setDoOutput(true);
                Log.v("PARAMS" , connection.toString());

                DataOutputStream dStream = new DataOutputStream(connection.getOutputStream());
                //dStream.writeBytes(mainObj.toString());
                //dStream.flush();
                //dStream.close();

                int responseCode = connection.getResponseCode();
                System.out.println("Res code=" + responseCode);


            }catch (Exception e){
                e.printStackTrace();
            }

            return null;
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            super.onPostExecute(aVoid);
            pd.dismiss();

        }
    }


    private class AddItemClass extends AsyncTask<String, Void, Boolean> {
        private ProgressDialog pd;

        @Override
        protected void onPreExecute() {
            pd= new ProgressDialog(FlyerActivity.this);
            pd.setMessage("Loading");
            pd.show();
        }

        @Override
        protected Boolean doInBackground(String... strings) {
            String hmacPrivateKey = strings[0];
            String hmacPublicKey = strings[1];
            String oauthSignatureMethod = strings[2];
            String oauthVersion = strings[3];
            String headerMulesoftClientIdFromhybrid = strings[4];
            String headerMulesoftClientSecretFromhybrid = strings[5];
            String accessTokenn = strings[6];
            String appId = strings[7];
            String selectedItem = strings[8];
            String API_BASE_URL = strings[9];

            URL url = null;
            String itemId1 = UUID.randomUUID().toString();
            final String Msg1 = "user/lists/" + selectedItem + "/items/" + itemId1 + "?t=" + accessTokenn;// + "&a=" + appId;
            String ADDINSHOPPINGLIST = API_BASE_URL + selectedItem + "/items/" + itemId1 + "?t=" + accessTokenn;// + "&a=" + appId;
            try {
                url = new URL(ADDINSHOPPINGLIST);
            } catch (MalformedURLException exception) {
                exception.printStackTrace();
                return false;
            }

            HttpURLConnection _connection = null;
            OutputStreamWriter osw = null;
            try {
                _connection = (HttpURLConnection) url.openConnection();
                _connection.setRequestMethod("PUT");
                _connection.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
                _connection.setRequestProperty("Accept", "application/json");
                _connection.setRequestProperty("client_id", headerMulesoftClientIdFromhybrid);
                _connection.setRequestProperty("client_secret", headerMulesoftClientSecretFromhybrid);
                _connection.setDoOutput(true);
                Log.v("PARAMS" , _connection.toString());


                osw = new OutputStreamWriter(_connection.getOutputStream());

                
                JSONObject product = new JSONObject();
                JSONObject customAttributes = new JSONObject();
                JSONObject payload = new JSONObject();
                try {

                    product.put("upc",productUpc);
                    product.put("productName",productName);

                    customAttributes.put("category",categoryType);
                    customAttributes.put("itemSource","WEEKLY_SPECIAL");

                    payload.put("product",product);
                    payload.put("customAttributes",customAttributes);
                    payload.put("itemSource","WEEKLY_SPECIAL");
                    payload.put("itemId",itemId1);
                    payload.put("itemName",productName);
                    payload.put("itemQuantity","1");

                } catch (Exception e) {
                    Log.e("Exception[ERROR]: ",e.toString());
                    e.printStackTrace();
                }

                osw.write(payload.toString());

                osw.flush();
                osw.close();

                Log.v("RESPONSE CODE: ", String.valueOf(_connection.getResponseCode()) );
                
                if(_connection.getResponseCode() == HttpURLConnection.HTTP_OK ||
                        _connection.getResponseCode() == HttpURLConnection.HTTP_CREATED){
                    Log.v("ADDED TO LIST", "Add to list success.");
                    // server_response = readStream(_connection.getInputStream());
                    Log.v("ADDED TO LIST SUCCESS", _connection.getResponseMessage() );
                    return true;
                } else {
                    // An unexpected problem occurred.  Please try again.  If the problem persists, please call Customer Service at 1(800) 210-9569
                    Log.v("ADDED TO LIST ERROR", _connection.getResponseMessage() );
                    // showErrorDialog("Server Error", "An unexpected problem occurred.  Please try again.  If the problem persists, please call Customer Service at 1(800) 210-9569");
                    // String ddd = readStream(_connection.getErrorStream());
                    return false;
                }


            } catch (IOException e) {
                //network error/ tell the user
                Log.v("ADDED TO LIST ERROR", "Network Error");
                e.printStackTrace();
            } finally  {
                if (_connection != null) {
                    _connection.disconnect();
                }
            }           
    

            return false;
        }

        @Override
        protected void onPostExecute(Boolean success) {
            super.onPostExecute(success);
            pd.dismiss();
            Log.e("Added to List?", success?"YES":"NO");

            System.out.println("flyer_client_id---"+flyer_client_id);
            final String itemId1 = UUID.randomUUID().toString();
            

            DataLayerModel dataLayerModelObj = new DataLayerModel();
            dataLayerModelObj.weeklySpecialAction = WeeklySpecialAction.add_to_list;
            dataLayerModelObj.item_id = itemId;
            gtmDataLayerPush(dataLayerModelObj);

            if(success) {

                LayoutInflater factory = LayoutInflater.from(FlyerActivity.this);
                final View deleteDialogView = factory.inflate(R.layout.popup, null);

                final AlertDialog addItemDialog = new AlertDialog.Builder(FlyerActivity.this).create();
                addItemDialog.setView(deleteDialogView);

                TextView title = new TextView(FlyerActivity.this);
                title.setText("ADDED TO LIST");
                title.setPadding(10, 10, 10, 10);
                title.setGravity(Gravity.CENTER);
                title.setTextColor(Color.BLACK);
                title.setTextSize(22);
                addItemDialog.setCustomTitle(title);

                deleteDialogView.findViewById(R.id.ok).setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View view) {
                        addItemDialog.dismiss();
                    }
                });
                addItemDialog.show();

            } else {

                showErrorDialog("FAILED TO ADD ITEM","WE ARE UNABLE TO ADD YOUR ITEM TO THE LIST. PLEASE TRY AGAIN LATER.");
            }
        }

    }



    private class PostClass extends AsyncTask<String, Void, Void> {
        private ProgressDialog pd;

        protected void onPreExecute() {
            pd= new ProgressDialog(FlyerActivity.this);
            pd.setMessage("Loading");
            pd.show();
        }

        @Override
        protected Void doInBackground(String... params) {

            String accessTokenn = params[6];

            try {
                String itemId1 = UUID.randomUUID().toString();
                String CREATE_SHOPPINGLIST = params[9]+itemId1 + "?t=" + accessTokenn ;//+ "&a=" + params[6];
                final String Msg = "user/lists/" + itemId1 + "?t=" + accessTokenn;// + "&a=" + params[6];
                //  System.out.println("----My CREATE_SHOPPINGLIST--747-"+CREATE_SHOPPINGLIST1);
                // String CREATE_SHOPPINGLIST = "https://api.us.apiconnect.ibmcloud.com/delhaize-america-enterprise-services/dev/coupons/api/v1/user/lists/" + itemId1 + "?t=" + params[5] + "&a=" + params[6];

                try {
                    URL url = new URL(CREATE_SHOPPINGLIST);
                    JSONObject obj = new JSONObject();
                    try {
                        obj.put("listName", params[8]);
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }

                    HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                    connection.setRequestMethod("PUT");
                    //connection.setRequestProperty("oauth_consumer_key", params[1]);
                    //connection.setRequestProperty("oauth_timestamp", String.valueOf((System.currentTimeMillis() / 1000)));
                    //connection.setRequestProperty("oauth_signature_method", params[2]);
                    //connection.setRequestProperty("oauth_version", params[3]);
                    //connection.setRequestProperty("oauth_signature", utils.getSignature(Msg, "PUT", obj.toString(), params[0], String.valueOf((System.currentTimeMillis() / 1000))));
                    //connection.setRequestProperty("oauth_nonce", String.valueOf((System.currentTimeMillis())) + ' ' + UUID.randomUUID().toString());
                    connection.setRequestProperty("Content-Type", "application/json");
                    connection.setRequestProperty("Accept", "application/json");
                    connection.setRequestProperty("client_id", params[4]);
                    connection.setRequestProperty("client_secret", params[5]);
                    connection.setDoOutput(true);
                    Log.v("PARAMS" , connection.toString());

                    DataOutputStream dStream = new DataOutputStream(connection.getOutputStream());
                    dStream.writeBytes(obj.toString());

                    //dStream.flush();
                    //dStream.close();

                    int responseCode = connection.getResponseCode();
                    System.out.println("Res code=" + responseCode);
                    Intent addedToList = new Intent();
                    addedToList.putExtra("addedToList", true);
                    setResult(RESULT_OK,addedToList);
                    pd.dismiss();

                } catch (MalformedURLException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                } catch (IOException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
                return null;
            } catch (Exception e) {
                e.printStackTrace();
            }
            return null;
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            super.onPostExecute(aVoid);
            pd.dismiss();

        }


    }

    private static class ContainerLoadedCallback implements ContainerHolder.ContainerAvailableListener {
        @Override
        public void onContainerAvailable(ContainerHolder containerHolder, String containerVersion) {
            // We load each container when it becomes available.
            Container container = containerHolder.getContainer();
            registerCallbacksForContainer(container);
        }

        public static void registerCallbacksForContainer(Container container) {
            // Register two custom function call macros to the container.
            container.registerFunctionCallMacroCallback("increment", new CustomMacroCallback());
            container.registerFunctionCallMacroCallback("mod", new CustomMacroCallback());
            // Register a custom function call tag to the container.
            container.registerFunctionCallTagCallback("custom_tag", new CustomTagCallback());
        }
    }

    private static class CustomMacroCallback implements Container.FunctionCallMacroCallback {
        private int numCalls;

        @Override
        public Object getValue(String name, Map<String, Object> parameters) {
            if ("increment".equals(name)) {
                return ++numCalls;
            } else if ("mod".equals(name)) {
                return (Long) parameters.get("key1") % Integer.valueOf((String) parameters.get("key2"));
            } else {
                throw new IllegalArgumentException("Custom macro name: " + name + " is not supported.");
            }
        }
    }

    private static class CustomTagCallback implements Container.FunctionCallTagCallback {
        @Override
        public void execute(String tagName, Map<String, Object> parameters) {
            // The code for firing this custom tag.
            Log.i("Weekly Flyer Print View", "Custom function call tag :" + tagName + " is fired.");
        }
    }
    
    private class ProcessPanning extends AsyncTask<Boolean, Void, Boolean> {
        private PanEventListener mCallBack;
        public Exception mException;

        public ProcessPanning(PanEventListener callback) {
            mCallBack = callback;
            Log.d("FlyerActivity","didFinishedPanning is false, ready to push gtm datalayer once");
            didFinishedPanning = false;
        }

        @Override
        protected void onPreExecute() {
        }

        @Override
        protected Boolean doInBackground(Boolean... params) {
            try {
                if (!params[0]) {
                    isPanning = true;
                    Log.d("FlyerActivity","isPanning is true, push gtm datalayer once");
                    DataLayerModel dataLayerModelObj = new DataLayerModel();
                    dataLayerModelObj.weeklySpecialAction = WeeklySpecialAction.pan;
                    dataLayerModelObj.item_id = "";
                    gtmDataLayerPush(dataLayerModelObj);    
                } 

                int time = 10000;
                Thread.sleep(time);
                
                
                return true;
    
            } catch (Exception e) {
                mException = e;
            }
    
            return null;
        }

        @Override
        protected void onPostExecute(Boolean result) {
            super.onPostExecute(result);
            if (mCallBack != null) {
                if (mException == null) {
                    mCallBack.onSuccess(result);
                } else {
                    mCallBack.onFailure(mException);
                }
            }

			
        }
    }

    private void showErrorDialog(String title,String msg) {

        final AlertDialog alertDialog = new AlertDialog.Builder(FlyerActivity.this).create();
        alertDialog.setTitle(title);
        alertDialog.setMessage(msg);

        alertDialog.setButton("OK", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                alertDialog.dismiss();
            }
        });
        if (!alertDialog.isShowing()) {
            alertDialog.show();
        }
    }
    

    public String trimMessage(String json, String key){
        String trimmedString = null;

        try{
            JSONObject obj = new JSONObject(json);
            trimmedString = obj.getString(key);
        } catch(JSONException e){
            e.printStackTrace();
            return null;
        }

        return trimmedString;
    }

     private void gtmDataLayerPush(DataLayerModel dataLayerObj) {
        // Log.e("FlyerActivity", "DataLayerModel: " + dataLayerObj + "clientId: " + clientId );
        dataLayer.push(DataLayer.mapOf(
                            "event", dataLayerObj.event,
                            "clientId", clientId,
                            "weeklySpecialAction", dataLayerObj.weeklySpecialAction.getValue(),
                            "flyer_type_id", flyer_type_id,
                            "flyer_run_id", flyer_run_id,
                            "flyer_id", defaultFlyerId,
                            "store_id", mStoreId,
                            "postal_code", flyer_postal_code,
                            "item_id", dataLayerObj.item_id ));
    }
}
