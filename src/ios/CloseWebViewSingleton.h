//
//  CloseWebViewSingleton.h
//  Delhaize Food Lion Loyalty Mobile App
//
//  Created by Soham Bhattacharjee on 23/11/16.
//
//

#import <Foundation/Foundation.h>
@class WLActionReciever;

@interface CloseWebViewSingleton : NSObject
+ (void)closeWebView:(NSDictionary *)dict;
@end
