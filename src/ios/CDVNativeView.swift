//
//  CDVNativeView.swift
//
//

import UIKit

@objc(CDVNativeView) class CDVNativeView : CDVPlugin, FlyerViewControllerDelegate {
    var showCallbackId = ""
    
    @objc(show:)
    func show(_ command: CDVInvokedUrlCommand) {
        showCallbackId = command.callbackId
        let pluginResult: CDVPluginResult
        let params = command.argument(at: 0)
        
        if(params != nil) {
            let flyerViewController = FlyerViewController()
            flyerViewController.delegate = self
            flyerViewController.setDataFromWebView(params as! NSDictionary)
            DispatchQueue.main.async {
                flyerViewController.modalPresentationStyle = UIModalPresentationStyle.currentContext
                self.viewController.present(flyerViewController, animated: true, completion: nil)
            }
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "The params of show() method needs be a json object")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    func viewControllerDismissed() {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "")
        self.commandDelegate.send(pluginResult, callbackId: showCallbackId)
    }
}

