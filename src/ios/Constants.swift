//
//  Constants.swift
//  Delhaize Food Lion Loyalty Mobile App
//
//  Created by Soham Bhattacharjee on 23/11/16.
//
//

import Foundation
struct AppConstants {
    // Postal/ZIP code given by user (L1B9C3, 90210)
    static var POSTAL_CODE = "L4W1L6"
    // Store code selected by user
    static var STORE_CODE = "0693" //"0001" //"0693" //"001"
    // Locale of user (en, fr, en-US, en-CA)
    static let LOCALE = "en-CA"
    // Flipp's name identifier of merchant
    static let MERCHANT_IDENTIFIER = "foodlion" //"flippflyerkit"
    // Access token provided by Flipp
    static let ACCESS_TOKEN = "2536a66d" //"062b6223"
    // Root URL of API calls
    static let ROOT_URL = "https://api.flipp.com/"
    // API version number (vX.X)
    static let API_VERSION = "v2.0"
    // Default Flyer ID
    static let DEFAULT_FLYER_ID = 953466 //788309 //948583 //939425
    // Flipp's merchant ID
    static let MERCHANT_ID = "4489"
    static let baseColor = UIColor(red: 0.0/255.0, green: 86.0/255.0, blue: 149.0/255.0, alpha: 1.0)
}
struct APPURLConstants {
    static let partStringForGettingList = "user/lists?"
    static let partStringForAddingToList = "user/lists/"
}

struct ItemCategory {
    let catLeft: Any?
    let catHeight: Any?
    let catWidth: Any?
    let catTop: Any?
    let catName: Any?
}
