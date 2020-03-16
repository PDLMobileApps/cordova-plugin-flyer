package com.foodlion.mobile;

import org.apache.commons.codec.binary.Base64;
import org.json.JSONObject;

import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/**
 * Created by Ashish on 11/21/2016.
 */

public class Utils {
    //String secret = "3f3edfdd-b4a5-4c22-b551-d0681954e8e7";
    //String uuid = UUID.randomUUID().toString();
    //String timestamp = String.valueOf((System.currentTimeMillis() / 1000));
    String nonce = String.valueOf((int)(System.currentTimeMillis()))+' '+UUID.randomUUID().toString();
    String hash;

       public String getSignature(String Msg, String httpmethod, String requestbody, String secret, String timestamp){
        try {
            if (httpmethod != "GET"){
                Msg = Msg+ httpmethod+ timestamp+ requestbody;
            } else {
                Msg = Msg+ httpmethod+ timestamp;
            }
            System.out.println("MSG-"+Msg);

            Mac sha256_HMAC = Mac.getInstance("HmacSHA256");
            SecretKeySpec secret_key = new SecretKeySpec(secret.getBytes(), "HmacSHA256");
            sha256_HMAC.init(secret_key);
            hash = new String(Base64.encodeBase64(sha256_HMAC.doFinal(Msg.getBytes())));

        }
        catch (Exception e){
            e.printStackTrace();
        }
        return hash;
    }

}
