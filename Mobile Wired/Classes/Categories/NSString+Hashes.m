//
//  Mobile_WiredAppDelegate.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import "NSString+Hashes.h"
#import <CommonCrypto/CommonHMAC.h>


@implementation NSString (Hashes)

- (NSString *)SHA1Value
{
    NSString *string = self;
    const char *cString = [string UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cString, strlen(cString), result);
    NSString *newString = [NSString  stringWithFormat:
                           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                           result[0], result[1], result[2], result[3], result[4],
                           result[5], result[6], result[7], result[8], result[9],
                           result[10], result[11], result[12], result[13], result[14],
                           result[15], result[16], result[17], result[18], result[19] ];
    newString = [newString lowercaseString];
    
    return newString;
}

@end
