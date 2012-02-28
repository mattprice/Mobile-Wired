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

@property (strong, nonatomic) GCDAsyncSocket *socket;
@property (strong, nonatomic) id <WiredConnectionDelegate> delegate;
@property (copy) NSMutableDictionary *userList;
@property (copy) NSMutableDictionary *serverInfo;
@property (nonatomic) NSString *myUserID;
@property (nonatomic) Boolean isConnected;

- (id)init;

#pragma mark User Commands
- (void)connectToServer:(NSString *)server onPort:(UInt16)port;
- (void)disconnect;
- (void)sendLogin:(NSString *)user withPassword:(NSString *)password;
- (void)setNick:(NSString *)nick;
- (void)setStatus:(NSString *)status;
- (void)setIcon:(NSData *)icon;
- (void)setIdle;

#pragma mark Connection Information
- (NSDictionary *)getMyUserInfo;
- (void)getInfoForUser:(NSString *)userID;
- (NSDictionary *)getServerInfo;
- (Boolean)isConnected;

#pragma mark Channel Commands
- (void)joinChannel:(NSString *)channel;
- (void)leaveChannel:(NSString *)channel;
- (void)sendChatMessage:(NSString *)message toChannel:(NSString *)channel;
- (void)sendChatEmote:(NSString *)message toChannel:(NSString *)channel;
- (void)setTopic:(NSString *)topic forChannel:(NSString *)channel;
- (void)sendMessage:(NSString *)message toID:(NSString *)userID;
- (void)sendBroadcast:(NSString *)message;
- (void)kickUserID:(NSString *)userID fromChannel:(NSString *)channel message:(NSString *)message;
- (void)banUserID:(NSString *)userID message:(NSString *)message expiration:(NSDate *)expiration;

#pragma mark Connection Helpers
- (void)sendCompatibilityCheck;
- (void)sendClientInformation;
- (void)sendAcknowledgement;
- (void)sendOkay;
- (void)sendPingReply;
- (void)sendPingRequest;
- (void)readData;

#pragma mark GCDAsyncSocket Wrappers
- (void)secureSocket;
- (void)sendTransaction:(NSString *)transaction withParameters:(NSDictionary *)parameters;
- (void)sendTransaction:(NSString *)transaction;
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;

@end

@protocol WiredConnectionDelegate <NSObject>
- (void)didReceiveServerInfo:(NSDictionary *)serverInfo;
- (void)didLoginSuccessfully;
- (void)didReceiveTopic:(NSString *)topic fromNick:(NSString *)nick forChannel:(NSString *)channel;
- (void)didReceiveChatMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel;
- (void)didReceiveEmote:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel;
- (void)didFailLoginWithReason:(NSString *)reason;
- (void)didFailConnectionWithReason:(NSError *)error;
- (void)didReceiveMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID;
- (void)didReceiveBroadcast:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID;
- (void)userJoined:(NSString *)nick withID:(NSString *)userID;
- (void)userLeft:(NSString *)nick withID:(NSString *)userID;
- (void)setUserList:(NSDictionary *)userList;
- (void)didReceiveUserInfo:(NSDictionary *)info;

@end
