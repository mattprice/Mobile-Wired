//
//  WiredConnection.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/16/11.
//  Copyright 2011 Ember Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"


@interface WiredConnection : NSObject {
    
}

@property (nonatomic, retain) GCDAsyncSocket *socket;

- (id)init;
- (BOOL)connectToServer:(NSString *)server onPort:(UInt16)port;
- (void)sendTransaction:(NSString *)transaction withParameters:(NSDictionary *)parameters;
- (void)sendTransaction:(NSString *)transaction;

@end
