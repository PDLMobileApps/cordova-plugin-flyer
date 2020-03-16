//
//  CommonCrypto.h
//  FlyerAPI
//
//  Created by Soham Bhattacharjee on 22/11/16.
//  Copyright © 2016 IBM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>

@interface CommonCrypto : NSObject
+ (NSString *)getAlgorythmString:(NSString *)secret andBaseString:(NSString *)baseString;

@end
