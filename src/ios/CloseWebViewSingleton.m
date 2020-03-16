//
//  CloseWebViewSingleton.m
//  Delhaize Food Lion Loyalty Mobile App
//
//  Created by Soham Bhattacharjee on 23/11/16.
//
//

#import "CloseWebViewSingleton.h"
#import <IBMMobileFirstPlatformFoundationHybrid/IBMMobileFirstPlatformFoundationHybrid.h>

@implementation CloseWebViewSingleton
+ (void)closeWebView:(NSDictionary *)dict {
    [NativePage showWebView:dict];
}
@end
