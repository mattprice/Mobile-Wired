//
//  WiredConnection.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/16/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"


@protocol WiredConnectionDelegate;
@interface WiredConnection : NSObject {
    GCDAsyncSocket *socket;
    id <WiredConnectionDelegate> delegate;
    NSMutableDictionary *userList;
}

@property (nonatomic, retain) GCDAsyncSocket *socket;
@property (nonatomic, assign) id <WiredConnectionDelegate> delegate;
@property (copy) NSMutableDictionary *userList;
@property (nonatomic, assign) NSString *_userID;

- (id)init;

#pragma mark User Commands
- (void)connectToServer:(NSString *)server onPort:(UInt16)port;
- (void)disconnect;
- (void)sendLogin:(NSString *)user withPassword:(NSString *)password;
- (void)setNick:(NSString *)nick;
- (void)setStatus:(NSString *)status;
- (void)setIcon:(NSData *)icon;
- (void)setIdle;

#pragma mark Channel Commands
- (void)joinChannel:(NSString *)channel;
- (void)leaveChannel:(NSString *)channel;
- (void)sendChatMessage:(NSString *)message toChannel:(NSString *)channel;
- (void)sendChatEmote:(NSString *)message toChannel:(NSString *)channel;
- (void)setTopic:(NSString *)topic forChannel:(NSString *)channel;

#pragma mark Connection Helpers
- (void)sendCompatibilityCheck;
- (void)sendClientInformation;
- (void)sendAcknowledgement;
- (void)sendOkay;
- (void)sendPingReply;
- (void)sendPingRequest;
- (void)readData;

#pragma mark GCDAsyncSocket Wrappers
- (void)sendTransaction:(NSString *)transaction withParameters:(NSDictionary *)parameters;
- (void)sendTransaction:(NSString *)transaction;
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;

@end

@protocol WiredConnectionDelegate <NSObject>
- (void)didReceiveServerInfo;
- (void)didLoginSuccessfully;
- (void)didReceiveTopic:(NSString *)topic fromNick:(NSString *)nick forChannel:(NSString *)channel;
- (void)didReceiveMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel;
- (void)didReceiveEmote:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel;

@end
