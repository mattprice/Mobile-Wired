//
//  WiredConnection.h
//  Mobile Wired
//
//  Copyright (c) 2012 Matthew Price, http://mattprice.me/
//  Copyright (c) 2012 Ember Code, http://embercode.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@protocol WiredConnectionDelegate;
@interface WiredConnection : NSObject {
    GCDAsyncSocket *socket;
    id <WiredConnectionDelegate> delegate;
    
    NSString *serverHost;
    NSInteger serverPort;
    
    NSMutableDictionary *userList;
    NSMutableDictionary *serverInfo;
    NSMutableDictionary *myPermissions;
    NSString *myUserID;
    
    Boolean isConnected;
    NSInteger failCount;
}

@property (strong, nonatomic) GCDAsyncSocket *socket;
@property (strong, nonatomic) id <WiredConnectionDelegate> delegate;

@property (strong) NSMutableDictionary *userList;
@property (strong) NSMutableDictionary *serverInfo;
@property (strong, nonatomic) NSString *myUserID;

@property Boolean isConnected;

- (id)init;

#pragma mark User Commands
- (void)connectToServer:(NSString *)server onPort:(NSInteger)port;
- (void)disconnect;
- (void)sendLogin:(NSString *)user withPassword:(NSString *)password;
- (void)setNick:(NSString *)nick;
- (void)setStatus:(NSString *)status;
- (void)setIcon:(NSData *)icon;
- (void)setIdle;

#pragma mark Connection Information
- (NSDictionary *)getMyUserInfo;
- (NSDictionary *)getMyPermissions;
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
- (void)attemptReconnection;

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
- (void)willReconnectDelayed:(NSString *)delay;
- (void)willReconnectDelayed:(NSString *)delay withError:(NSError *)error;
- (void)didReconnect;
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
