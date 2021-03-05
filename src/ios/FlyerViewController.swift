//
//  FlyerViewController.swift
//  Delhaize Food Lion Loyalty Mobile App
//
//  Created by Soham Bhattacharjee on 23/11/16.
//
//

import UIKit
import Foundation

struct DataLayerModel {
    let event: String = "weekly-special-event"
    let weeklySpecialAction: WeeklySpecialAction
    var item_id: String?
}

enum WeeklySpecialAction: String {
    case add_to_list = "add to list"
    case open_item = "open item"
    case share_flyer = "share flyer"
    case remove_from_list = "remove from list"
    case share_item = "share item"
    case select_location = "select location"
    case select_store = "select store"
    case select_flyer = "select flyer"
    case open_flyer = "open flyer"
    case read = "read"
    case pan = "pan"
    case export_pdf = "export pdf"
    case select_category = "select category"
    case apply_discount_filter = "apply discount filter"
}

enum FlyerError: String {
    case UnexpectedErrorMsg = "An unexpected problem occurred.  Please try again.  If the problem persists, please call Customer Service at 1-800-210-9569."
    case NoConnectionErrorMsg = "The App is not able to access the Internet. Please check data connection on your phone and try again."
}

@objc(ItemAnnotation)
class ItemAnnotation: NSObject, WFKFlyerViewBadgeAnnotation, WFKFlyerViewTapAnnotation {
    var frame = CGRect.zero
    var flyerItem: AnyObject? = nil
    var image: UIImage? = nil
}
let urlSession = {
    return URLSession(
        configuration: URLSessionConfiguration.default, delegate: nil,
        delegateQueue: OperationQueue.main)
}()

@objc protocol FlyerViewControllerDelegate : NSObjectProtocol{
    func viewControllerDismissed()
}

@objc(FlyerViewController)
class FlyerViewController: UIViewController, WFKFlyerViewDelegate, TAGContainerOpenerNotifier {
    
    // MARK: Properties
    private var flyerItems: [AnyObject] = []
    private var flyerPages: [AnyObject] = []
    private var flyerView: WFKFlyerView? = nil
    private var clippings = NSMutableSet()
    private var categoryArray: [ItemCategory] = []
    private var listNamesArray: [String] = []
    private var clientId : String?
    private var dataLayer: TAGDataLayer?
    private var dataLayerFlyerItemID: Int = 0
    private var didFinishedPanning: Bool = true
    private var isFlyerLoaded: Bool = false
    @objc public var delegate: FlyerViewControllerDelegate?
    
    // MARK: API Properties
    var APPID: String?
    var HMACPRIVATEKEY: String?
    var HMACPUBLICKEY: String?
    var OAUTHSIGNATUREMETHOD: String?
    var OAUTHVERSION: String?
    var PARTNERKEY: String?
    var SHAREDKEY: String?
    var STOREID: String?
    var accessToken: String?
    var anonToken: String?
    var SIGNINMODE: String?
    var CLIENTID: String?
    var shoppingListURL: String?
    var mulesoftClientID : String?
    var mulesoftClientSecret : String?
    var tagManager: TAGManager?
    var container: TAGContainer?
    var selectedFlyerID = 0
    var selectedFlyerTypeID = 0
    var selectedFlyerRunID = 0
    var selectedFlyerPostalCode = 0
    var dict = ["addedToList" : false] as Dictionary

    // MARK: IBOutlets
    @IBOutlet weak var pickerView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    // MARK: Init and View Lifecycle Methods
    override func loadView() {
        super.loadView()
        
        // Initialise GTM
        self.tagManager = TAGManager.instance()
        
        // Modify the log level of the logger to print out not only
        // warning and error messages, but also verbose, debug, info messages.
        // self.tagManager!.logger.setLogLevel(kTAGLoggerLogLevelVerbose)
        
        /*
         * Opens a container.
         *
         * @param containerId The ID of the container to load.
         * @param tagManager The TAGManager instance for getting the container.
         * @param openType The choice of how to open the container.
         * @param timeout The timeout period (default is 2.0 seconds).
         * @param notifier The notifier to inform on container load events.
         */
        //        TAGContainerOpener.openContainer(withId: "GTM-KR5SRRZ", tagManager: self.tagManager, openType: kTAGOpenTypePreferNonDefault, timeout: nil, notifier: self)
        

        // GTM
        // Data Layer Push
        let clientIdKey = "gaClientId"
        //  Look in UserDefaults for the Google Analytics Client ID.
        let defaults = UserDefaults.standard
        self.clientId = (defaults.object(forKey: clientIdKey) as! String)
        self.dataLayer = self.tagManager!.dataLayer

        // removing all categories
        self.categoryArray.removeAll()
        
        getFlyerDetails { (data: Data?) in
            
            if data != nil {
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                    var jsonDictArray = jsonResult as! [Dictionary<String, Any>]

                    let currentDate = Date()
                    jsonDictArray = jsonDictArray.filter({ (item) -> Bool in
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        let validTo = dateFormatter.date(from: (item["valid_to"] as? String)!) ?? currentDate
                        let validFrom = dateFormatter.date(from: (item["valid_from"] as? String)!) ?? currentDate
                        return validFrom <= currentDate && currentDate <= validTo
                    })
                    
                    if jsonDictArray.count > 0 {
                        let jsonDict = jsonDictArray[0]
                        if Array(jsonDict.keys).contains("id") {
                            
                            // Save Flyer Run ID
                            if let runID = jsonDict["flyer_run_id"] as? NSNumber {
                                self.selectedFlyerRunID = Int(runID)
                            }
                            // Save Flyer Type ID
                            if let typeID = jsonDict["flyer_type_id"] as? NSNumber {
                                self.selectedFlyerTypeID = Int(typeID)
                            }
                            // Save Flyer Postal Code
                            if let postalCode = jsonDict["postal_code"] {
                                self.selectedFlyerPostalCode =  Int(postalCode as! String)!
                            }
                            
                            // Save Flyer ID
                            if let flyerID = jsonDict["id"] as? NSNumber {
                                self.selectedFlyerID = Int(flyerID)
                                
                                // Load Flyers
                                self.loadFlyerDetails(flyerItemID: Int(flyerID))
                            }
                            
                            //                            self.getFlyerCategories(flyerID: String(Int(flyerID)), onCompletion: { (data: Data?) in
                            //                                OperationQueue.main.addOperation({
                            //                                    do {
                            //                                        let jsonResult = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                            //                                        let jsonDictArray = jsonResult as! [Dictionary<String, Any>]
                            //                                        for itemDict in jsonDictArray {
                            //                                            let cat = ItemCategory(catLeft: itemDict["left"], catHeight: itemDict["height"], catWidth: itemDict["width"], catTop: itemDict["top"], catName: itemDict["name"])
                            //                                            self.categoryArray.append(cat)
                            //                                        }
                            //                                        print(jsonDictArray)
                            //
                            //                                        // Load flyers
                            //                                        self.loadFlyerDetails(flyerItemID: Int(flyerID))
                            //
                            //                                        // Load categories
                            //                                        self.initailiseFlyerView()
                            //                                    }
                            //                                    catch {
                            //                                        self.showErrorMessage()
                            //                                    }
                            //                                })
                            //                            })
                        }
                        else {
                            self.showErrorMessage(withTitle: "Server Error",withMessage: FlyerError.UnexpectedErrorMsg.rawValue)
                        }
                    }
                    else {
                        self.showErrorMessage(withTitle: "Server Error",withMessage: FlyerError.UnexpectedErrorMsg.rawValue)
                    }
                }
                catch {
                    self.showErrorMessage(withTitle: "Server Error",withMessage: FlyerError.UnexpectedErrorMsg.rawValue)
                }
            }
            else {
                self.showErrorMessage(withTitle: "Network Error",withMessage: FlyerError.NoConnectionErrorMsg.rawValue)
            }
        }
    }
    
    func initailiseFlyerView() {
        edgesForExtendedLayout = []
        
        clippings = NSMutableSet()
        // if flyerView == nil {
        //     flyerView = WFKFlyerView()
        // }
        flyerView!.highlightAnnotations = nil
        flyerView!.translatesAutoresizingMaskIntoConstraints = false
        // flyerView!.delegate = self
        view.addSubview(flyerView!)
        view.backgroundColor = AppConstants.baseColor
        // Adding a navigation bar
        title = "Weekly Special Print View"
        let navigationBarAppearace = UINavigationBar.appearance()
        // change navigation item title color
        navigationBarAppearace.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]

        var navigationBar = UINavigationBar()
        navigationBar = UINavigationBar(frame: CGRect(x: 0.0, y: UIApplication.shared.statusBarFrame.height, width: view.frame.size.width, height: 44))
        navigationBar.barTintColor = AppConstants.baseColor
        navigationBar.isTranslucent = false
        navigationBar.tintColor = UIColor.white
        navigationBar.backgroundColor = AppConstants.baseColor
        navigationBar.barStyle = .default
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "cross"), style: .done, target: self, action: #selector(back(sender:)))
        navigationBar.pushItem(navigationItem, animated: true)
        navigationBar.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(navigationBar)
        
        // Adding a segmented control
        //        let catNamesArray = self.categoryArray.map { (category) -> String in
        //            return category.catName as! String
        //        }
        //        let categorySegment = HMSegmentedControl(sectionTitles: catNamesArray)
        //        categorySegment!.frame = CGRect(x: 0.0, y: (navigationBar.frame.size.height), width: view.frame.size.width, height: 44)
        //        categorySegment!.borderType = .bottom
        //        categorySegment!.borderColor = UIColor.white
        //        categorySegment!.backgroundColor = AppConstants.baseColor
        //        categorySegment!.segmentEdgeInset = UIEdgeInsetsMake(0, 10, 0, 10);
        //        categorySegment!.selectionStyle = .fullWidthStripe
        //        categorySegment!.segmentWidthStyle = .dynamic
        //        categorySegment!.selectionIndicatorLocation = .down
        //        categorySegment!.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white,
        //                                                NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12.0)]
        //        categorySegment!.selectionIndicatorColor = UIColor.white
        //        categorySegment!.autoresizingMask = [.flexibleRightMargin, .flexibleWidth]
        //        categorySegment!.indexChangeBlock = { (index) in
        //            let categoryItem = self.categoryArray[index]
        //
        //        }
        //
        //        view.addSubview(categorySegment!)
        
        //        view.addConstraints(
        //            NSLayoutConstraint.constraints(withVisualFormat: "V:|[navigationBar(==64)][categorySegment(==44)][flyerView]|",
        //                                           options: [NSLayoutFormatOptions.alignAllLeading, NSLayoutFormatOptions.alignAllTrailing],
        //                                           metrics: nil, views: ["flyerView": flyerView!, "navigationBar": navigationBar, "categorySegment": categorySegment!]))
        
        view.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[navigationBar(==64)][flyerView]|",
                                           options: [NSLayoutConstraint.FormatOptions.alignAllLeading, NSLayoutConstraint.FormatOptions.alignAllTrailing],
                                           metrics: nil, views: ["flyerView": flyerView!, "navigationBar": navigationBar]))
        
        
        view.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "|[flyerView]|",
                                           options: [], metrics: nil, views: ["flyerView": flyerView!]))
    }

    
    
    //AppConstants.DEFAULT_FLYER_ID
    func loadFlyerDetails(flyerItemID: Int) {
        if flyerView == nil {
            flyerView = WFKFlyerView()
        }
        flyerView!.delegate = self
        flyerView!.setFlyerId(flyerItemID, usingRootUrl: AppConstants.ROOT_URL, usingVersion: AppConstants.API_VERSION, usingAccessToken: AppConstants.ACCESS_TOKEN)
        
        // Get the flyer item information for the flyer
        // Note: you must add the display types that you support to the API call
        let itemsUrl = "\(AppConstants.ROOT_URL)flyerkit/\(AppConstants.API_VERSION)/publication/\(flyerItemID)/products?access_token=\(AppConstants.ACCESS_TOKEN)&display_type=1,5,3,25,7,15"
        print("Flyer Items URL: " + itemsUrl)
        guard let itemsNSURL = NSURL(string: itemsUrl) else { return }
        
        urlSession.dataTask(with: itemsNSURL as URL) {
            data, response, error in
            
            if (response as! HTTPURLResponse).statusCode != 200 {
                return
            }
            
            guard let data = data else { return }
            
            self.flyerItems =
                try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyObject]
            
            let currentDate = Date()
            self.flyerItems = self.flyerItems.filter({ (item) -> Bool in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                var validTo = dateFormatter.date(from: (item["valid_to"] as? String)!) ?? currentDate
                let validFrom = dateFormatter.date(from: (item["valid_from"] as? String)!) ?? currentDate
                validTo = validTo.addingTimeInterval((24*60*60*8)-1)
                return validFrom <= currentDate && currentDate <= validTo
            })
            
            self.flyerView!.tapAnnotations = self.flyerItems.map { item in
                let left = CGFloat((item["left"] as? NSNumber)?.doubleValue ?? 0)
                let top = CGFloat((item["top"] as? NSNumber)?.doubleValue ?? 0)
                let width = CGFloat((item["width"] as? NSNumber)?.doubleValue ?? 0)
                let height = CGFloat((item["height"] as? NSNumber)?.doubleValue ?? 0)
                let rect = CGRect(x: left, y: top, width: width, height: height) //CGRectMake(left, top, width, height)
                let annotation = ItemAnnotation()
                annotation.frame = rect
                annotation.flyerItem = item
                annotation.image = UIImage(named: "badge")
                return annotation
            }
            
            self.updateCircleBadges()
            }.resume()
        
        // Get the page information for the flyer
        let pagesUrl = "\(AppConstants.ROOT_URL)flyerkit/\(AppConstants.API_VERSION)/publication/\(flyerItemID)/pages?access_token=\(AppConstants.ACCESS_TOKEN)"
        print("Flyer Pages URL: " + pagesUrl)
        guard let pagesNSURL = NSURL(string: pagesUrl) else { return }
        
        urlSession.dataTask(with: pagesNSURL as URL) {
            data, response, error in
            
            if (response as! HTTPURLResponse).statusCode != 200 {
                self.showErrorMessage(withTitle: "Server Error",withMessage: FlyerError.UnexpectedErrorMsg.rawValue)
                return
            }
            guard let data = data else {
                self.showErrorMessage(withTitle: "Network Error",withMessage: FlyerError.NoConnectionErrorMsg.rawValue)
                return
            }
            self.flyerPages = try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyObject]
            
            // Initialise Flyers
            OperationQueue.main.addOperation({
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                FTIndicator.dismissProgress()
                self.view.isUserInteractionEnabled = true
                self.initailiseFlyerView()
            })
            }.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: Error Handling
    func showErrorMessage(withTitle title: String = "Error", withMessage msg: String ) {
        
        OperationQueue.main.addOperation({
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            FTIndicator.dismissProgress()
            self.view.isUserInteractionEnabled = true
            
            let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "Ok", style: .default, handler: { action in
                self.dismissNativePage()
            })
            alertController.addAction(alertAction)
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    // MARK: Flyer View Events
    
    func flyerViewDidScroll(_ flyerView: WFKFlyerView) {
        // NSLog("FlyerView scrolled %@", NSStringFromCGRect(flyerView.visibleContent()))
        if (self.didFinishedPanning && self.isFlyerLoaded && flyerView.isTracking) {
            self.didFinishedPanning = false
            // NSLog("didFinishedPanning is false, ready to push gtm datalayer once")
            DispatchQueue.global(qos: .background).async {
                let dataLayerModel = DataLayerModel(weeklySpecialAction: WeeklySpecialAction.pan,
                                                    item_id: "")
                self.gtmDataLayerPush(dataLayerObj: dataLayerModel)

                // Go back to the main thread to update the UI
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                    // NSLog("isPanning is true, push gtm datalayer once")
                    self.didFinishedPanning = true
                    
                }
            }
        }
    }
    
    func flyerViewWillBeginLoading(_ flyerView: WFKFlyerView) {
        NSLog("FlyerView will begin loading")
    }
    
    func flyerViewDidFinishLoading(_ flyerView: WFKFlyerView) {
        NSLog("FlyerView did finish loading")
        self.isFlyerLoaded = true;
        let dataLayerModel = DataLayerModel(weeklySpecialAction: WeeklySpecialAction.open_flyer,
                                            item_id: "")
        self.gtmDataLayerPush(dataLayerObj: dataLayerModel)

    }
    
    func flyerViewDidFailLoading(_ flyerView: WFKFlyerView, withError error: Error?) {
        NSLog("FlyerView failed loading: %@", error?.localizedDescription ?? "")
    }
    
    // MARK: Touch Event Handlers
    
    // Single tap event handler
    func flyerView(_ flyerView: WFKFlyerView, gotSingleTap annotation: WFKFlyerViewTapAnnotation?,
                   at point: CGPoint) {
        NSLog("FlyerView single tapped %@ at %@", annotation?.description ?? "",
              NSCoder.string(for: point))
        
        guard let flyerItem = (annotation as? ItemAnnotation)?.flyerItem else { return }
        
        // switch based on item display type
        guard let itemDisplayType = (flyerItem["item_type"] as AnyObject).integerValue else { return }
        switch itemDisplayType {
        // video
        case 3: break
            //guard let flyerItemId = (flyerItem["id"] as AnyObject).integerValue else { return }
            // openVideoItemView(flyerItemId: flyerItemId)
        // external link
        case 5:
            let itemUrl = flyerItem["web_url"] as! String
            UIApplication.shared.openURL(NSURL(string:itemUrl)! as URL)
        // page anchor
        case 7:
            let itemAnchorPageNumber = flyerItem["page_destination"] as! Int
            let itemAnchorPage = self.flyerPages[itemAnchorPageNumber - 1]
            let left = itemAnchorPage["left"] as! CGFloat
            let top = itemAnchorPage["top"] as! CGFloat
            let width = itemAnchorPage["width"] as! CGFloat
            let height = itemAnchorPage["height"] as! CGFloat
            let rect = CGRect(x: left, y: top, width: width, height: height) //CGRectMake(left, top, width, height)
            flyerView.zoom(to: rect, animated: true)
        // Iframe
        case 15: break
            //guard let flyerItemId = (flyerItem["id"] as AnyObject).integerValue else { return }
            // openIframeItemView(flyerItemId: flyerItemId)
        // coupon
        case 25: break
            //guard let flyerItemId = (flyerItem["id"] as AnyObject).integerValue else { return }
        //openCouponItemView(flyerItemId: flyerItemId)
        default: break
            //guard let flyerItemId = (flyerItem["id"] as AnyObject).integerValue else { return }
            //openFlyerItemView(flyerItemId: flyerItemId)
        }
        
        // remove previously selected circle
        if clippings.contains(flyerItem) {
            clippings.remove(flyerItem)
        }
        else {
            // remove all circles
            clippings.removeAllObjects()
            // circle item
            clippings.add(flyerItem)

            self.dataLayerFlyerItemID = flyerItem["id"] as! Int
            let dataLayerModel = DataLayerModel(weeklySpecialAction: WeeklySpecialAction.select_flyer,
                                                item_id: "\(self.dataLayerFlyerItemID)" )
            self.gtmDataLayerPush(dataLayerObj: dataLayerModel)

            // Call API
            getList(flyerItemSKU: flyerItem["sku"] as AnyObject, flyerItemCat: flyerItem["category"] as AnyObject, flyerItemName: flyerItem["name"] as AnyObject)
        }
        updateCircleBadges()
    }
    
    // Double Tap event handler
    func flyerView(_ flyerView: WFKFlyerView, gotDoubleTap annotation: WFKFlyerViewTapAnnotation?,
                   at point: CGPoint) {
        NSLog("FlyerView double tapped %@ at %@", annotation?.description ?? "",
              NSCoder.string(for: point))
        let visibleContent = flyerView.visibleContent()
        
        // zoom flyer in or out
        if (fabs(visibleContent.size.height - flyerView.contentSize().height) > 0.001) {
            let zoomScale = flyerView.frame.size.height / flyerView.contentSize().height
            let zoomSize =  CGSize(width: flyerView.frame.size.width / zoomScale, height: flyerView.contentSize().height)
            let rect = CGRect(
                x: visibleContent.origin.x + visibleContent.size.width / 2.0 - zoomSize.width / 2.0,
                y: visibleContent.origin.y + visibleContent.size.height / 2.0 - zoomSize.height / 2.0,
                width: zoomSize.width, height: zoomSize.height)
            flyerView.zoom(to: rect, animated: true)
        } else {
            let zoomSize = CGSize(width: 700.0, height: 700.0)
            let rect = CGRect(x: point.x - zoomSize.width / 2.0, y: point.y - zoomSize.height / 2.0,
                              width: zoomSize.width, height: zoomSize.height)
            flyerView.zoom(to: rect, animated: true)
        }
    }
    
    // Long press event handler
    func flyerView(_ flyerView: WFKFlyerView, gotLongPress annotation: WFKFlyerViewTapAnnotation?,
                   at point: CGPoint) {
        NSLog("FlyerView long pressed %@ at %@", annotation?.description ?? "",
              NSCoder.string(for: point))
        //        guard let itemAnnotation = annotation as? ItemAnnotation,
        //            let flyerItem = itemAnnotation.flyerItem else {
        //                return
        //        }
        
        //        // remove previously selected circle
        //        if clippings.contains(flyerItem) {
        //            clippings.remove(flyerItem)
        //        }
        //        else {
        //            // remove all circles
        //            clippings.removeAllObjects()
        //
        //            // circle item
        //            clippings.add(flyerItem)
        //        }
        //        updateCircleBadges()
        
        //        // Call API
        //        getList(flyerItemSKU: flyerItem["sku"] as AnyObject, flyerItemCat: flyerItem["category"] as AnyObject, flyerItemName: flyerItem["name"] as AnyObject)
    }
    
    //    // Opens the flyer item view (display_type = 1)
    //    func openFlyerItemView(flyerItemId: Int) {
    //        //        let flyerItemController = FlyerItemViewController()
    //        //        flyerItemController.flyerItemId = flyerItemId
    //        //        navigationController?.pushViewController(flyerItemController, animated: true)
    //    }
    //
    //    // Opens the coupon item view (display_type = 25)
    //    func openCouponItemView(flyerItemId: Int) {
    //        //        let couponController = CouponViewController()
    //        //        couponController.flyerItemId = flyerItemId
    //        //        navigationController?.pushViewController(couponController, animated: true)
    //    }
    //
    //    // Opens the video item view (display_type = 3)
    //    func openVideoItemView(flyerItemId: Int) {
    //        //        let videoController = VideoViewController()
    //        //        videoController.flyerItemId = flyerItemId
    //        //        navigationController?.pushViewController(videoController, animated: true)
    //    }
    //
    //    // Opens the iframe item view (display_type = 15)
    //    func openIframeItemView(flyerItemId: Int) {
    //        //        let iframeController = IframeViewController()
    //        //        iframeController.flyerItemId = flyerItemId
    //        //        navigationController?.pushViewController(iframeController, animated: true)
    //    }
    
    // MARK: Other Methods
    
    // update the flyer view based on changes from the discount slider
    func discountChanged(slider: UISlider) {
        flyerView!.highlightAnnotations = flyerItems.filter { item -> Bool in
            guard let percentOff = item["percent_off"] as? NSNumber else { return false }
            return slider.value > 0 && percentOff.floatValue > slider.value
            }.map { item in
                let left = CGFloat((item["left"] as? NSNumber)?.doubleValue ?? 0)
                let top = CGFloat((item["top"] as? NSNumber)?.doubleValue ?? 0)
                let width = CGFloat((item["width"] as? NSNumber)?.doubleValue ?? 0)
                let height = CGFloat((item["height"] as? NSNumber)?.doubleValue ?? 0)
                
                let annotation = ItemAnnotation()
                annotation.frame = CGRect(x: left, y: top, width: width, height: height)
                return annotation
        }
    }
    
    // update the circled items within the flyer view
    private func updateCircleBadges() {
        flyerView!.badgeAnnotations = clippings.map { item in
            let newItem = item as! Dictionary<String, AnyObject>
            let left = CGFloat(newItem["left"]?.doubleValue ?? 0)
            let top = CGFloat(newItem["top"]?.doubleValue ?? 0)
            let width = CGFloat(newItem["width"]?.doubleValue ?? 0)
            let height = CGFloat(newItem["height"]?.doubleValue ?? 0)
            let rect = CGRect(x: left, y: top, width: width, height: height)
            
            let annotation = ItemAnnotation()
            annotation.flyerItem = item as AnyObject?
            annotation.image = UIImage(named:"badge")
            annotation.frame = rect
            
            return annotation
        }
    }

    private func gtmDataLayerPush(dataLayerObj: DataLayerModel) {
        self.dataLayer?.push([
            "event": dataLayerObj.event,
            "clientId": self.clientId!,
            "weeklySpecialAction": dataLayerObj.weeklySpecialAction.rawValue,
            "flyer_type_id": "\(self.selectedFlyerTypeID)",
            "flyer_run_id": "\(self.selectedFlyerRunID)",
            "flyer_id": "\(self.selectedFlyerID)",
            "store_id": self.STOREID, //?? "0001",
            "postal_code": "\(self.selectedFlyerPostalCode)",
            "item_id": dataLayerObj.item_id!
        ])
    }


    // MARK: - Navigation
    @objc func back(sender: UIButton) {
        dismissNativePage()
    }

    func dismissNativePage() {
        self.dismiss(animated: false, completion: nil);
        
        if self.flyerView != nil {
            flyerView!.removeConstraints(flyerView!.constraints)
            flyerView = nil
        }
        view.subviews.forEach({ 
            $0.removeFromSuperview() 
        }) 
        view = nil
        
        delegate?.viewControllerDismissed()
    }
    
    // MARK: - API Calls
    func getSession() -> URLSession {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 30.0
        return URLSession(configuration: sessionConfig)
    }
    
    func getList(flyerItemSKU: AnyObject, flyerItemCat: AnyObject, flyerItemName: AnyObject) {
        
        // Nil Checking
        if accessToken == nil, mulesoftClientID == nil, mulesoftClientSecret == nil{
            return
        }
        
        // None of the features are available for the guest users
        if SIGNINMODE == "0" {
            let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "Please sign up!", content: "Feature not available for the guest users", buttonTitles: ["Ok"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
            })
            alertView?.headIconImg = UIImage(named: "cross.png")
            alertView?.present()
            return
        }
        
        
        // Customising Base String
        let partString = APPURLConstants.partStringForGettingList + "t=" + accessToken!
        let finalURLString = shoppingListURL! + partString
        
        guard let url = URL(string: finalURLString) else {
            print("Cannot create URL")
            return
        }
        
        // Setup Session
        let session = getSession()
        // Make the request
        let mutableRequest = NSMutableURLRequest(url: url)
        
        // Fix for fetching shopping lists - removing unecessary HTTPHeaderFields
//        let uuid = UUID().uuidString
//        let timeStamp = Int64(NSDate().timeIntervalSince1970 * 1000)
//        let timeStampString = String(timeStamp)
//        let nonce = timeStampString + " " + uuid
//
//        let oathSignature = CommonCrypto.getAlgorythmString(HMACPRIVATEKEY, andBaseString: partString + "GET" + String(timeStamp/1000))
        mutableRequest.setValue(mulesoftClientID, forHTTPHeaderField: "client_id")
        mutableRequest.setValue(mulesoftClientSecret, forHTTPHeaderField: "client_secret")
        //mutableRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        mutableRequest.setValue("application/json", forHTTPHeaderField: "Accept")
//        mutableRequest.setValue(oathSignature, forHTTPHeaderField: "oauth_signature")
//        mutableRequest.setValue(nonce, forHTTPHeaderField: "oauth_nonce")
//        mutableRequest.setValue("2.0", forHTTPHeaderField: "oauth_version")
//        mutableRequest.setValue(OAUTHSIGNATUREMETHOD, forHTTPHeaderField: "oauth_signature_method")
//        mutableRequest.setValue(HMACPUBLICKEY, forHTTPHeaderField: "oauth_consumer_key")
//        mutableRequest.setValue(String(timeStamp/1000), forHTTPHeaderField: "oauth_timestamp")
        mutableRequest.httpMethod = "GET"
        
        // Activity Loader
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        view.isUserInteractionEnabled = false
        FTIndicator.showProgressWithmessage("Fetching your list..")
        
        let task = session.dataTask(with: mutableRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            OperationQueue.main.addOperation({
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                FTIndicator.dismissProgress()
                self.view.isUserInteractionEnabled = true
                
                guard let dataItem = data else {
                    let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "FAILED TO FETCH THE LIST", content: "WE ARE UNABLE TO FETCH YOUR SHOPPING LIST", buttonTitles: ["CANCEL", "TRY AGAIN"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                        
                        if index == 1 {
                            self.getList(flyerItemSKU: flyerItemSKU, flyerItemCat: flyerItemCat, flyerItemName: flyerItemName)
                        }
                        else {
                            print("User Cancelled")
                        }
                    })
                    alertView?.headIconImg = UIImage(named: "cross.png")
                    alertView?.present()
                    return
                }
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: dataItem, options: .mutableContainers)
                    self.showList(listData: jsonResult as! Dictionary<String, Any>, flyerItemSKU: flyerItemSKU, flyerItemCat: flyerItemCat, flyerItemName: flyerItemName)
                }
                catch {
                    print("Error")
                    OperationQueue.main.addOperation({
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        FTIndicator.dismissProgress()
                        self.view.isUserInteractionEnabled = true
                        
                        
                        let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "FAILED TO FETCH THE LIST", content: "WE ARE UNABLE TO FETCH YOUR SHOPPING LIST", buttonTitles: ["CANCEL", "TRY AGAIN"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                            if index == 1 {
                                self.getList(flyerItemSKU: flyerItemSKU, flyerItemCat: flyerItemCat, flyerItemName: flyerItemName)
                            }
                            else {
                                print("User Cancelled")
                            }
                        })
                        alertView?.headIconImg = UIImage(named: "cross.png")
                        alertView?.present()
                    })
                }
            })
        })
        task.resume()
    }
    func addItemsToList(listID: String, sku: AnyObject, category: AnyObject, itemName: AnyObject) {
        
        // Nil Checking
        guard let accessTokenString = accessToken, let hmacPublicKey = HMACPUBLICKEY, !sku.isKind(of: NSNull.classForCoder()), !category.isKind(of: NSNull.classForCoder()), !itemName.isKind(of: NSNull.classForCoder())  else {
            
            OperationQueue.main.addOperation({
                let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "FAILED TO ADD ITEM", content: "WE ARE UNABLE TO ADD YOUR ITEM TO THE LIST. PLEASE TRY AGAIN LATER.", buttonTitles: ["CANCEL", "TRY AGAIN"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                    if index == 1 {
                        self.addItemsToList(listID: listID, sku: sku, category: category, itemName: itemName)
                    }
                    else {
                        print("User Cancelled")
                    }
                })
                alertView?.headIconImg = UIImage(named: "cross.png")
                alertView?.present()
            })
            return
        }
        
        // Getting an UUID every time
        let uuid = UUID().uuidString
        
        // Customising Base URL String
        let taURL = "?t=" + accessTokenString
        let partURL = APPURLConstants.partStringForAddingToList + listID + "/items/" + uuid + taURL
        let completeURLString = shoppingListURL! + partURL
        
        guard let url = URL(string: completeURLString) else {
            print("Cannot create URL")
            return
        }
        
        // Setup Session
        let session = getSession()
        
        // Make the request
        let mutableRequest = NSMutableURLRequest(url: url)
        
        // Creating Nonce
//        let timeStamp = Int64(NSDate().timeIntervalSince1970 * 1000)
//        let timeStampString = String(timeStamp)
//        let nonce = timeStampString + " " + UUID().uuidString
        
        // Customising SKU to get upc
        let upc = String(sku as! String)
        var upcString = "\(upc)"
        //Fix for deprecated method
        let lastChar = upcString.last
        if lastChar == "0" {
            upcString = upcString.substring(to: upcString.index(before: upcString.endIndex))
        }
        
        // Request Body
        let jsonRequestBody = ["product": ["upc": upcString,
                                           "productName": itemName],
                               "customAttributes": ["category": category,
                                                    "itemSource": "WEEKLY_SPECIAL"],
                               "itemSource": "WEEKLY_SPECIAL",
                               "itemId": uuid,
                               "itemName": itemName,
                               "itemQuantity": 1] as [String : Any]
        
        do {
            // Activity Loader
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            view.isUserInteractionEnabled = false
            FTIndicator.showProgressWithmessage("Adding your item to the list..")
            
            let json = try JSONSerialization.data(withJSONObject: jsonRequestBody, options: JSONSerialization.WritingOptions.prettyPrinted)
//            let partString = (partURL + "PUT" + String(timeStamp/1000) + "{\"itemId\":\"\(uuid)\",\"itemQuantity\":1,\"itemName\":\"\(itemName as! String)\",\"itemSource\":\"WEEKLY_SPECIAL\",\"product\":{\"productName\":\"\(itemName as! String)\",\"upc\":\(upcString)},\"customAttributes\":{\"category\":\"\(category)\",\"itemSource\":\"WEEKLY_SPECIAL\"}}")
            
//            let oathSignature = CommonCrypto.getAlgorythmString(hmacPrivateKey, andBaseString: partString)
            
            // Fix for adding item to shopping lists - removing unecessary HTTPHeaderFields
            mutableRequest.setValue(mulesoftClientID, forHTTPHeaderField: "client_id")
            mutableRequest.setValue(mulesoftClientSecret, forHTTPHeaderField: "client_secret")
            mutableRequest.setValue("application/json", forHTTPHeaderField: "content-type")
            mutableRequest.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "accept")
//            mutableRequest.setValue(oathSignature, forHTTPHeaderField: "oauth_signature")
//            mutableRequest.setValue(nonce, forHTTPHeaderField: "oauth_nonce")
//            mutableRequest.setValue("2.0", forHTTPHeaderField: "oauth_version")
//            mutableRequest.setValue(oauthSignatureMethod, forHTTPHeaderField: "oauth_signature_method")
//            mutableRequest.setValue(hmacPublicKey, forHTTPHeaderField: "oauth_consumer_key")
//            mutableRequest.setValue(String(timeStamp/1000), forHTTPHeaderField: "oauth_timestamp")
            mutableRequest.httpMethod = "PUT"
            mutableRequest.httpBody = json
            
            print(mutableRequest)
            
            let task = session.dataTask(with: mutableRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
                
                OperationQueue.main.addOperation({
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    FTIndicator.dismissProgress()
                    self.view.isUserInteractionEnabled = true
                    
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                        //print(httpResponse.statusCode)
                        print("Success")
                        print("httpResponse description \(httpResponse.description)\n")
                        print("httpResponse statusCode \(httpResponse.statusCode)\n")
                        
                        let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "ADDED TO LIST", content: "YOU HAVE SUCCESSFULLY ADDED THE ITEM TO THE LIST", buttonTitles: ["OK"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                            if index == 0 {
                            }
                        })
                        alertView?.headIconImg = UIImage(named: "checkmark")
                        alertView?.present()
                        
                        let dataLayerModel = DataLayerModel(weeklySpecialAction: WeeklySpecialAction.add_to_list,
                                                            item_id: "\(self.dataLayerFlyerItemID)" )
                        self.gtmDataLayerPush(dataLayerObj: dataLayerModel)

                    }
                    else {
                        print("Error")
                        let httpResponse = response as? HTTPURLResponse
                        print("httpResponse description \(httpResponse!.description)\n")
                        print("httpResponse statusCode \(httpResponse!.statusCode)\n")
                        let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "FAILED TO ADD ITEM", content: "WE ARE UNABLE TO ADD YOUR ITEM TO THE LIST. PLEASE TRY AGAIN LATER.", buttonTitles: ["CANCEL", "TRY AGAIN"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                            if index == 1 {
                                self.addItemsToList(listID: listID, sku: sku, category: category, itemName: itemName)
                            }
                            else {
                                print("User Cancelled")
                            }
                        })
                        alertView?.headIconImg = UIImage(named: "cross.png")
                        alertView?.present()
                    }
                })
            })
            task.resume()
        }
        catch {
            OperationQueue.main.addOperation({
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                FTIndicator.dismissProgress()
                self.view.isUserInteractionEnabled = true
                
                let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "FAILED TO ADD ITEM", content: "WE ARE UNABLE TO ADD YOUR ITEM TO THE LIST. PLEASE TRY AGAIN LATER.", buttonTitles: ["CANCEL", "TRY AGAIN"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                    if index == 1 {
                        self.addItemsToList(listID: listID, sku: sku, category: category, itemName: itemName)
                    }
                    else {
                        print("User Cancelled")
                    }
                })
                alertView?.headIconImg = UIImage(named: "cross.png")
                alertView?.present()
            })
        }
    }
    func createNewList(itemName: String) {
        
        // Nil Checking
        guard let appID = APPID, let hmacPrivateKey = HMACPRIVATEKEY, let oauthSignatureMethod = OAUTHSIGNATUREMETHOD, let accessTokenString = accessToken, let hmacPublicKey = HMACPUBLICKEY else {
            OperationQueue.main.addOperation({
                let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "FAILED TO CREATE THE LIST", content: "WE ARE UNABLE TO CREATE THE LIST", buttonTitles: ["CANCEL", "TRY AGAIN"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                    if index == 1 {
                        self.createNewList(itemName: itemName)
                    }
                    else {
                        print("User Cancelled")
                    }
                })
                alertView?.headIconImg = UIImage(named: "cross.png")
                alertView?.present()
            })
            return
        }
        
        // List name duplicate checking
        if listNamesArray.contains(itemName.uppercased()) {
            let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "Warning", content: "\(itemName) already exists in list", buttonTitles: ["OK"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                print("User tapped 'OK'")
            })
            alertView?.headIconImg = UIImage(named: "cross.png")
            alertView?.present()
            return
        }
        
        // Getting an UUID every time
        let listID = UUID().uuidString
        
        // Customising Base URL String
        let taURL = "?t=" + accessTokenString
        let partURL = APPURLConstants.partStringForAddingToList + listID + taURL
        let completeURLString = shoppingListURL! + partURL
        
        guard let completeURL = URL(string: completeURLString) else {
            print("Cannot create URL")
            return
        }
        
//        let timeStamp = Int64(NSDate().timeIntervalSince1970 * 1000)
//        let timeStampString = String(timeStamp)
//        let nonce = timeStampString + " " + UUID().uuidString
        
        let newJsonRequestBody = ["listName": itemName] as [String : Any]
        
        do {
            // Activity Loader
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            FTIndicator.showProgressWithmessage("Creating your list")
            view.isUserInteractionEnabled = false
            
            let json = try JSONSerialization.data(withJSONObject: newJsonRequestBody, options: JSONSerialization.WritingOptions.prettyPrinted)
//            let partString = (partURL + "PUT" + String(timeStamp/1000) + "{\"listName\":\"\(itemName)\"}")
//            let oathSignature = CommonCrypto.getAlgorythmString(hmacPrivateKey, andBaseString: partString)
            
            
            // Setup Session
            let session = getSession()
            
            // Make the request
            let mutableRequest = NSMutableURLRequest(url: completeURL)
            mutableRequest.setValue(mulesoftClientID, forHTTPHeaderField: "client_id")
            mutableRequest.setValue(mulesoftClientSecret, forHTTPHeaderField: "client_secret")
            mutableRequest.setValue("application/json", forHTTPHeaderField: "content-type")
            mutableRequest.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "accept")
            // Fix for creating new shopping lists - removing unecessary HTTPHeaderFields
//            mutableRequest.setValue(oathSignature, forHTTPHeaderField: "oauth_signature")
//            mutableRequest.setValue(nonce, forHTTPHeaderField: "oauth_nonce")
//            mutableRequest.setValue("2.0", forHTTPHeaderField: "oauth_version")
//            mutableRequest.setValue(oauthSignatureMethod, forHTTPHeaderField: "oauth_signature_method")
//            mutableRequest.setValue(hmacPublicKey, forHTTPHeaderField: "oauth_consumer_key")
//            mutableRequest.setValue(String(timeStamp/1000), forHTTPHeaderField: "oauth_timestamp")
            mutableRequest.httpMethod = "PUT"
            mutableRequest.httpBody = json
            
            let task = session.dataTask(with: mutableRequest as URLRequest, completionHandler: { (data, response: URLResponse?, error) -> Void in
                OperationQueue.main.addOperation({
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    FTIndicator.dismissProgress()
                    self.view.isUserInteractionEnabled = true
                    
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                        self.dict = ["addedToList" : true] as Dictionary
                        print(httpResponse.statusCode)
                        let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "LIST CREATED", content: "YOU HAVE SUCCESSFULLY CREATED A NEW LIST", buttonTitles: ["OK"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                            if index == 0 {
                                //After creating new list, fetch updated list and display
                                if let array:NSArray = self.clippings.allObjects as NSArray?{
                                    let flyerItem: AnyObject = array.lastObject as AnyObject
                                    self.getList(flyerItemSKU: flyerItem["sku"] as AnyObject, flyerItemCat: flyerItem["category"] as AnyObject, flyerItemName: flyerItem["name"] as AnyObject)
                                }
                            }
                        })
                        alertView?.headIconImg = UIImage(named: "checkmark")
                        alertView?.present()
                    }
                    else {
                        let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "FAILED TO CREATE THE LIST", content: "WE ARE UNABLE TO CREATE THE LIST", buttonTitles: ["Cancel", "Try again"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                            if index == 1 {
                                self.createNewList(itemName: itemName)
                            }
                            else {
                                print("User Cancelled")
                            }
                        })
                        alertView?.headIconImg = UIImage(named: "cross.png")
                        alertView?.present()
                    }
                })
            })
            task.resume()
        }
        catch {
            OperationQueue.main.addOperation({
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                FTIndicator.dismissProgress()
                self.view.isUserInteractionEnabled = true
                
                let alertView = ZHPopupView.popupNormalAlertView(in: self.view, backgroundStyle: ZHPopupViewBackgroundType_Blur, title: "FAILED TO CREATE THE LIST", content: "WE ARE UNABLE TO CREATE THE LIST", buttonTitles: ["CANCEL", "TRY AGAIN"], confirmBtnTextColor: UIColor.white, otherBtnTextColor: UIColor.white, buttonPressedBlock: { index in
                    if index == 1 {
                        self.createNewList(itemName: itemName)
                    }
                    else {
                        print("User Cancelled")
                    }
                })
                alertView?.headIconImg = UIImage(named: "cross.png")
                alertView?.present()
            })
        }
    }
    func showList(listData: Dictionary<String, Any>, flyerItemSKU: AnyObject, flyerItemCat: AnyObject, flyerItemName: AnyObject) {
        
        // If the dictionary doesn't contain "lists" key, just return!
        let arrKeys = Array(listData.keys)
        if !arrKeys.contains("lists") {
            return
        }
        
        // Removing previous elements
        listNamesArray.removeAll()
        
        let listArray = listData["lists"] as! [Dictionary<String, Any>]
        var listDetails:[Dictionary<String, String>] = []
        for list in listArray {
            if list["listName"] != nil, list["listId"] != nil {
                // adding list names to global array for duplicate checking purpose
                listNamesArray.append((list["listName"] as! String).uppercased())
                
                listDetails.append(["listName": list["listName"] as! String,
                                    "listId": list["listId"] as! String])
            }
        }
        
        // Alphabetical Sorting of list names
        listNamesArray = listNamesArray.sorted(by: <)
        var counter = 0
        var tempArray:[Dictionary<String, String>] = []
        repeat {
            print(counter)
            for dict in listDetails {
                if listNamesArray[counter] == dict["listName"]?.uppercased() {
                    tempArray.append(dict)
                    counter += 1
                    break
                }
            }
        } while counter < listNamesArray.count
        if tempArray.count > 0 {
            listDetails = tempArray
        }
        
        // If there is one list, add the item to that list directly
        if listDetails.count == 1 {
            let listItemDict = listDetails[0]
            self.addItemsToList(listID: listItemDict["listId"]!, sku: flyerItemSKU, category: flyerItemCat, itemName: flyerItemName)
            return
        }
        
        // Show List AlertController
        let messageText = "Select a List"
        let listAlert = UIAlertController(title: "", message: messageText, preferredStyle: .actionSheet)
        let messageProperty = NSMutableAttributedString(
            string: messageText,
            attributes: [
                NSAttributedString.Key.foregroundColor: AppConstants.baseColor,
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20.0)
            ]
        )
        listAlert.setValue(messageProperty, forKey: "_attributedMessage")
        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .left
        for listItemDict in listDetails {
            let title = listItemDict["listName"]!
            let alertAction =  UIAlertAction(title: title.uppercased(), style: .default, handler: { action in
                action.accessibilityValue = listItemDict["listId"]
                self.addItemsToList(listID: listItemDict["listId"]!, sku: flyerItemSKU, category: flyerItemCat, itemName: flyerItemName)
            })
            listAlert.addAction(alertAction)
        }
        listAlert.addAction(UIAlertAction(title: "Create New List", style: .destructive, handler: { action in
            print("Create New List")
            let alertController = UIAlertController(title: "New List", message: "", preferredStyle: .alert)
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "List Name"
            }
            let confirmAction = UIAlertAction(title: "OK", style: .default, handler: {
                alert -> Void in
                let firstTextField = alertController.textFields![0] as UITextField
                if firstTextField.text != nil, !firstTextField.text!.isEmpty {
                    print("New List \(firstTextField.text)")
                    print("Now Hit the API")
                    self.createNewList(itemName: firstTextField.text!)
                }
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
                alert -> Void in
            })
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
            
        }))
        listAlert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { action in
            listAlert.dismiss(animated: true, completion: nil)
        }))
        present(listAlert, animated: true, completion: nil)
    }
    
    // MARK: - Get Data From Hybrid
    @objc func setDataFromWebView(_ data: NSDictionary) {
        print(data)
        APPID = data["APPID"] as? String
        HMACPRIVATEKEY = data["HMACPRIVATEKEY"] as? String
        OAUTHSIGNATUREMETHOD = data["OAUTHSIGNATUREMETHOD"] as? String
        accessToken = data["accessToken"] as? String
        HMACPUBLICKEY = data["HMACPUBLICKEY"] as? String
        STOREID = data["STOREID"] as? String ?? "0001"
        SIGNINMODE = data["signInMode"] as? String ?? "0"
        if STOREID!.count < 1 {
            STOREID = "0001"
        }
        if SIGNINMODE!.count < 1 {
            SIGNINMODE = "0"
        }
        CLIENTID = data["CLIENTID"] as? String ?? ""
        mulesoftClientID = data["mulesoftClientID"] as? String ?? ""
        mulesoftClientSecret = data["mulesoftClientSecret"] as? String ?? ""
        let tempShoppingURL = data["shoppinglisturl"] as? String ?? ""
        shoppingListURL = tempShoppingURL.replacingOccurrences(of: "user/lists/", with: "")
    }
    
    // MARK: - Call Flyer Details API
    func getFlyerDetails(onCompletion: @escaping (_ result: Data?) -> Void) {
        
        // Activity Loader
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        FTIndicator.showProgressWithmessage("Fetching your flyers")
        view.isUserInteractionEnabled = false
        
        //let storeID = STOREID ?? "0001"
        // Flyer Details URL
        let flyerURLString = "https://api.flipp.com/flyerkit/v2.0/publications/foodlion?access_token=2536a66d&locale=en-US&store_code=\(STOREID!)"
        guard let requestURL = URL(string: flyerURLString) else {
            print("Cannot create URL")
            return
        }
        
        // Setup Session
        let session = getSession()
        
        // Make Request
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
        
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            onCompletion(data)
        }
        task.resume()
    }
    //    func getFlyerCategories(flyerID: String, onCompletion: @escaping (_ result: Data?) -> Void) {
    //        // Activity Loader
    //        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    //        FTIndicator.showProgressWithmessage("Fetching flyer categories")
    //
    //        // Flyer Categories URL
    //        let categoriesURSLString = "https://api.flipp.com/flyerkit/v2.0/publication/\(flyerID)/categories?access_token=\(AppConstants.ACCESS_TOKEN)"
    //        guard let requestURL = URL(string: categoriesURSLString) else {
    //            print("Cannot create URL")
    //            return
    //        }
    //        // Setup Session
    //        let session = URLSession.shared
    //
    //        // Make Request
    //        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
    //
    //        let task = session.dataTask(with: urlRequest as URLRequest) {
    //            (data, response, error) -> Void in
    //            onCompletion(data)
    //        }
    //        task.resume()
    //    }
}

extension UIDevice {
    var iPhoneX: Bool {
        return UIScreen.main.nativeBounds.height == 2436
    }
}

extension FlyerViewController {
    func containerAvailable(_ container: TAGContainer!) {
        // Note that containerAvailable may be called on any thread, so you may need to dispatch back to
        // your main thread.
        OperationQueue.main.addOperation {
            self.container = container
        }
    }
}
