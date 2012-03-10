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
    NSMutableDictionary *serverInfo;
    NSString *myUserID;
    Boolean isConnected;
}

@property (strong, nonatomic) GCDAsyncSocket *socket;
@property (strong, nonatomic) id <WiredConnectionDelegate> delegate;
@property (copy) NSMutableDictionary *userList;
@property (copy) NSMutableDictionary *serverInfo;
@property (strong, nonatomic) NSString *myUserID;
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
- (void)didReceiveUserInfo:(NSDictionary *)info;
- (void)didLoginSuccessfully;
- (void)didFailLoginWithReason:(NSString *)reason;
- (void)didDisconnect;
- (void)willReconnect;
- (void)didReconnect;
- (Boolean)isReconnecting;
- (void)didConnectAndLoginSuccessfully;
- (void)didFailConnectionWithReason:(NSError *)error;
- (void)didReceiveTopic:(NSString *)topic fromNick:(NSString *)nick forChannel:(NSString *)channel;
- (void)didReceiveChatMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel;
- (void)didReceiveEmote:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel;
- (void)didReceiveMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID;
- (void)didReceiveBroadcast:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID;
- (void)userJoined:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel;
- (void)userChangedNick:(NSString *)oldNick toNick:(NSString *)newNick forChannel:(NSString *)channel;
- (void)userLeft:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel;
- (void)userWasKicked:(NSString *)nick withID:(NSString *)userID byUser:(NSString *)kicker forReason:(NSString *)reason forChannel:(NSString *)channel;
- (void)setUserList:(NSDictionary *)userList forChannel:(NSString *)channel;

@end
