//
//  WiredConnection.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/16/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import "WiredConnection.h"
#import "NSString+Base64.h"
#import "TBXML.h"
#import <CommonCrypto/CommonHMAC.h>

#define STEALTH_MODE  FALSE

@implementation WiredConnection

@synthesize socket, delegate;
@synthesize userList, _userID;

/*
 * Initiates a socket connection object.
 *
 */
- (id)init
{
    if ((self = [super init])) {
        // Create a new socket connection using the main dispatch queue.
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    }
    
    return self;
}

#pragma mark User Commands
/*
 * Connects to the given server and port specified.
 *
 * This method also handles sending the handshake, and creating an empty user list.
 *
 */
- (void)connectToServer:(NSString *)server onPort:(UInt16)port
{
    NSError *error = nil;
    NSDictionary *parameters;
    
    // Attempt a socket connection to the server.
    NSLog(@"Beginning socket connection...");
    if (![socket connectToHost:server onPort:port withTimeout:15 error:&error]) {
        // Connection failed.
        NSLog(@"Connection error: %@",error);
    }
    
    // Start sending Wired connection info.
    NSLog(@"Sending Wired handshake...");
    parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                  @"1.0",   @"p7.handshake.version",
                  @"Wired", @"p7.handshake.protocol.name",
                  @"2.0",   @"p7.handshake.protocol.version",
                  nil];
    [self sendTransaction:@"p7.handshake.client_handshake" withParameters:parameters];
    [self readData];
    
    // Create an empty user list.
    userList = [[NSMutableDictionary alloc] init];

}

/*
 * Runs anything that needs to be done post-connection.
 *
 * For now, this only attempts to enable background support.
 * In the future it's possible that we may want to run other commands as well.
 *
 */
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
#if !TARGET_IPHONE_SIMULATOR
    // Backgrounding doesn't seem to be supported on the simulator yet
    [sock performBlock:^{
        if ([sock enableBackgroundingOnSocket])
            NSLog(@"Enabling backgrounding...");
        else
            NSLog(@"Failed to enable backgrounding.");
    }];
#endif
}

- (void)disconnect
{
    NSLog(@"Attempting to disconnect from server...");
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                _userID, @"wired.user.id",
                                @"",     @"wired.user.disconnect_message",
                                nil];
    [self sendTransaction:@"wired.user.disconnect_user" withParameters:parameters];
    
    // Disconnect the socket and then release.
    [socket setDelegate:nil];
    [socket disconnectAfterWriting];
    [socket release], socket = nil;
    [userList release], userList = nil;
}

/*
 * Sends a users login information to the Wired server.
 *
 * The password must be converted to a SHA1 digest before sending it
 * to the server, which requires importing <CommonCrypto/CommonHMAC.h>.
 *
 */
- (void)sendLogin:(NSString *)user withPassword:(NSString *)clearText
{
    NSLog(@"Sending login information...");
    
    // Convert the password to a SHA1 digest.
    const char *cString = [clearText UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cString, strlen(cString), result);
    NSString *password = [NSString  stringWithFormat:
                          @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                          result[0], result[1], result[2], result[3], result[4],
                          result[5], result[6], result[7], result[8], result[9],
                          result[10], result[11], result[12], result[13], result[14],
                          result[15], result[16], result[17], result[18], result[19] ];
    password = [password lowercaseString];
    
    // Send the user login information to the Wired server.
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                user,     @"wired.user.login",
                                password, @"wired.user.password",
                                nil];
    [self sendTransaction:@"wired.send_login" withParameters:parameters];
    [self readData];
}

- (void)setNick:(NSString *)nick
{
    NSLog(@"Attempting to change nick to: %@...", nick);
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:nick forKey:@"wired.user.nick"];
    [self sendTransaction:@"wired.user.set_nick" withParameters:parameters];
    [self readData];
}

- (void)setStatus:(NSString *)status
{
    NSLog(@"Attempting to change status to: %@...", status);
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:status forKey:@"wired.user.status"];
    [self sendTransaction:@"wired.user.set_status" withParameters:parameters];
    [self readData];
}

- (void)setIdle
{
    NSLog(@"Attempting to set user idle...");
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"YES" forKey:@"wired.user.idle"];
    [self sendTransaction:@"wired.user.set_idle" withParameters:parameters];
    [self readData];
}

- (void)setIcon:(NSData *)icon
{
    NSLog(@"Attempting to set user icon...");
    
    // Create a base64 representation of the image.
    NSString *base64 = [NSString encodeBase64WithData:icon];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:base64 forKey:@"wired.user.icon"];
    [self sendTransaction:@"wired.user.set_icon" withParameters:parameters];
    [self readData];
}

#pragma mark Channel Commands

- (void)joinChannel:(NSString *)channel
{
    NSLog(@"Attempting to join channel %@...",channel);
    
    // TODO: Check to make sure the channel was joined successfully.
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:channel forKey:@"wired.chat.id"];
    [self sendTransaction:@"wired.chat.join_chat" withParameters:parameters];
    [self readData];
}

- (void)leaveChannel:(NSString *)channel
{
    NSLog(@"Attempting to leave channel %@...",channel);
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:channel forKey:@"wired.chat.id"];
    [self sendTransaction:@"wired.chat.leave_chat" withParameters:parameters];
    [self readData];
}

- (void)setTopic:(NSString *)topic forChannel:(NSString *)channel
{
    // TODO: I'm sure we should check for errors.
    NSLog(@"Attempting to set topic for channel %@...",channel);
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                channel, @"wired.chat.id",
                                topic,   @"wired.chat.topic.topic",
                                nil];
    [self sendTransaction:@"wired.chat.set_topic" withParameters:parameters];
    [self readData];
}

/*
 * Sends a chat message to the specified channel.
 *
 * This method parses the message before sending it onto the channel. If the
 * message is equal to a known /command then we'll execute the command
 * instead of sending it as a literal message.
 *
 */
- (void)sendChatMessage:(NSString *)message toChannel:(NSString *)channel
{
    // TODO: Clear and Ping commands.
    if ([message isEqualToString:@"/afk"]) {
        [self setIdle];
    }
    
    else if ([message hasPrefix:@"/me"]) {
        message = [message stringByReplacingOccurrencesOfString:@"/me " withString:@""];
        [self sendChatEmote:message toChannel:channel];
    }
    
    else if ([message hasPrefix:@"/status"]) {
        message = [message stringByReplacingOccurrencesOfString:@"/status " withString:@""];
        [self setStatus:message];
    }
    
    else if ([message hasPrefix:@"/nick"]) {
        message = [message stringByReplacingOccurrencesOfString:@"/nick " withString:@""];
        [self setNick:message];
    }
    
    else if ([message hasPrefix:@"/topic"]) {
        message = [message stringByReplacingOccurrencesOfString:@"/topic " withString:@""];
        [self setTopic:message forChannel:channel];
    }
    
    else if ([message hasPrefix:@"/broadcast"]) {
        message = [message stringByReplacingOccurrencesOfString:@"/broadcast " withString:@""];
        [self sendBroadcast:message];
    }
    
    else {
        NSLog(@"Attempting to send chat message...");
        
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    channel, @"wired.chat.id",
                                    message, @"wired.chat.say",
                                    nil];
        [self sendTransaction:@"wired.chat.send_say" withParameters:parameters];
        [self readData];
    }
}

- (void)sendChatEmote:(NSString *)message toChannel:(NSString *)channel
{
    NSLog(@"Attempting to send emote...");
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                channel, @"wired.chat.id",
                                message, @"wired.chat.me",
                                nil];
    [self sendTransaction:@"wired.chat.send_me" withParameters:parameters];
    [self readData];
}

- (void)sendMessage:(NSString *)message toID:(NSString *)userID
{
    NSLog(@"Attempting to message...");
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                userID,  @"wired.user.id",
                                message, @"wired.message.message",
                                nil];
    [self sendTransaction:@"wired.message.send_message" withParameters:parameters];
    [self readData];
}

- (void)sendBroadcast:(NSString *)message
{
    NSLog(@"Attempting to send broadcast...");
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:message forKey:@"wired.message.broadcast"];
    [self sendTransaction:@"wired.message.send_broadcast" withParameters:parameters];
    [self readData];
}

#pragma mark Connection Helpers

/*
 * Sends a compatibility check to the server.
 *
 * Reads in MobileWired_Spec.xml and sends it to the server. Wired requires that
 * certain characters be encoded before sending. To save processing time the XML
 * is now pre-encoded. The orginal code is left in only for reference.
 *
 */
- (void)sendCompatibilityCheck
{
    NSLog(@"Sending compatibility check...");
    NSString *contents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MobileWired_Spec" ofType:@"xml"]
                                                   encoding:NSUTF8StringEncoding error:nil];
    
    // Escape the XML document.
//    contents = [[[[[contents stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;"]
//                   stringByReplacingOccurrencesOfString: @"\"" withString: @"&quot;"]
//                  stringByReplacingOccurrencesOfString: @"'" withString: @"&#39;"]
//                 stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"]
//                stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:contents forKey:@"p7.compatibility_check.specification"];
    [self sendTransaction:@"p7.compatibility_check.specification" withParameters:parameters];
    [self readData];
}

/*
 * Sends information about the wired client to the server.
 *
 * If the STEALTH_MODE macro is set to TRUE then the client lies and reports
 * information about the newest known Mac build that is available.
 *
 */
- (void)sendClientInformation
{
    NSLog(@"Sending client information...");
    
#if STEALTH_MODE
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Wired Client",  @"wired.info.application.name",
                                @"2.0",           @"wired.info.application.version",
                                @"8182",          @"wired.info.application.build",
                                @"Mac OS X",      @"wired.info.os.name",
                                @"10.6.7",        @"wired.info.os.version",
                                @"i386",          @"wired.info.arch",
                                @"false",         @"wired.info.supports_rsrc",
                                nil];
#else
    NSString *CFBundleVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    NSString *CFBundleBuild = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Mobile Wired",  @"wired.info.application.name",
                                CFBundleVersion,  @"wired.info.application.version",
                                CFBundleBuild,    @"wired.info.application.build",
                                [[UIDevice currentDevice] systemName],    @"wired.info.os.name",
                                [[UIDevice currentDevice] systemVersion], @"wired.info.os.version",
                                [[UIDevice currentDevice] model],         @"wired.info.arch",
                                @"false",         @"wired.info.supports_rsrc",
                                nil];
#endif
    
    [self sendTransaction:@"wired.client_info" withParameters:parameters];
    [self readData];
}

- (void)sendAcknowledgement
{
    NSLog(@"Sending acknowledgement...");
    [self sendTransaction:@"p7.handshake.acknowledge"];
}

- (void)sendOkay
{
    NSLog(@"Sending okay...");
    [self sendTransaction:@"wired.okay"];
}

- (void)sendPingRequest
{
    NSLog(@"Attempting to send ping...");
    
    [self sendTransaction:@"wired.send_ping"];
    [self readData];
}

- (void)sendPingReply
{
    NSLog(@"Attempting to send ping reply...");
    
    [self sendTransaction:@"wired.ping"];
    [self readData];
}

- (void)readData
{
    [socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}

#pragma mark GCDAsyncSocket Wrappers

/*
 * Sends a transaction message and its parameters to the Wired server.
 *
 * The message and paramaters could also be created using an XML framework,
 * but the replies are always so simple that it's not worth the extra processing
 * power or the learning curve required.
 *
 */
- (void)sendTransaction:(NSString *)transaction withParameters:(NSDictionary *)parameters
{
    NSMutableString *generatedXML = [NSMutableString string];
    NSString *CRLF = [[[NSString alloc] initWithData:[GCDAsyncSocket CRLFData] encoding:NSUTF8StringEncoding] autorelease];
    
    // Begin translating the transaction message into XML.
    [generatedXML appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    [generatedXML appendString:[NSString stringWithFormat:@"<p7:message name=\"%@\" xmlns:p7=\"http://www.zankasoftware.com/P7/Message\">",transaction]];
    
    // If parameters were sent convert them to XML too.
    if (parameters != nil) {
        for(id aParameter in parameters) {
            NSString *key = aParameter;
            NSString *value = [parameters valueForKey:key];
            [generatedXML appendString:[NSString stringWithFormat:@"<p7:field name=\"%@\">%@</p7:field>",key,value]];
        }
    }
    
    // End the transaction message.
    // Line break is the end message signal for the socket.
    [generatedXML appendString:@"</p7:message>"];
    [generatedXML appendString:CRLF];
    
    // Write the data to the socket.
    [socket writeData:[generatedXML dataUsingEncoding:NSUTF8StringEncoding] withTimeout:15 tag:0];
}

- (void)sendTransaction:(NSString *)transaction
{
    [self sendTransaction:transaction withParameters:nil];
}

/*
 * Reads and parses all data sent back from the Wired server.
 *
 * This handles every single response sent back from the server so there's
 * a huge amount of if-statements throughout the whole method. If something
 * is going wrong with receiving data then this is probably where to look.
 *
 * Wherever possible, offload actions you need to perform to other methods.
 *
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    TBXMLElement *rootElement, *childElement;
    NSString *rootName, *childName, *childValue;
    
    // Greate a TBXML object of the data.
    TBXML *doc = [[TBXML tbxmlWithXMLData:data] retain];
    
    // Extract the root element and its name.
    if (!doc.rootXMLElement) { [doc release]; return; }
    rootElement = doc.rootXMLElement;
    
    rootName = [TBXML valueOfAttributeNamed:@"name" forElement:rootElement];
    childElement = rootElement->firstChild;
    
    if ([rootName isEqualToString:@"p7.handshake.server_handshake"]) {
        NSLog(@"Received handshake.");
        
        [delegate updateConnectionProcessWithString:@"Received handshake"];
        [self sendAcknowledgement];
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"p7.handshake.compatibility_check"]) {
                childValue = [TBXML textForElement:childElement];
                
                if ([childValue isEqualToString:@"1"]) {
                    [self sendCompatibilityCheck];
                } else {
                    [self sendClientInformation];
                }
            }
        } while ((childElement = childElement->nextSibling));
    }
    
    else if ([rootName isEqualToString:@"p7.compatibility_check.status"]) {
        NSLog(@"Received compatibility status.");
        
        [delegate updateConnectionProcessWithString:@"Received compatibility status"];
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"p7.compatibility_check.status"]) {
                childValue = [TBXML textForElement:childElement];
                
                if ([childValue isEqualToString:@"1"]) {
                    [self sendClientInformation];
                } else {
                    NSLog(@"Compatibility mismatch.");
                }
            }
        } while ((childElement = childElement->nextSibling));
    }
    
    else if ([rootName isEqualToString:@"wired.server_info"]) {
        NSLog(@"Received server info.");
        [delegate didReceiveServerInfo];
    }
    
    else if ([rootName isEqualToString:@"wired.login"]) {
        NSLog(@"Login was successful.");
        
        // Only one child is returned, so no need for a do{} loop.
        childValue = [TBXML textForElement:childElement];
        _userID = childValue;
        
        [delegate didLoginSuccessfully];
    }
    
    else if ([rootName isEqualToString:@"wired.account.privileges"]) {
        NSLog(@"Received account priviledges.");
    }
    
    else if ([rootName isEqualToString:@"wired.okay"]) {
        NSLog(@"The last command was successful.");
    }
    
    else if ([rootName isEqualToString:@"wired.send_ping"]) {
        NSLog(@"Received ping request.");
        [self sendPingReply];
    }
    
    else if ([rootName isEqualToString:@"wired.ping"]) {
        NSLog(@"Received ping reply.");
    }
    
    else if ([rootName isEqualToString:@"wired.error"]) {
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.error"]) {
                childValue = [TBXML textForElement:childElement];
                
                if ([childValue isEqualToString:@"wired.error.login_failed"]) {
                    NSLog(@"Login failed: username or password is wrong.");
                    [delegate didFailLoginWithReason:@"Login failed: username or password is wrong."];
                }
                
                else if ([childValue isEqualToString:@"wired.banned"]) {
                    NSLog(@"Login failed: user is banned.");
                    [delegate didFailLoginWithReason:@"Login failed: user is banned."];
                }
                
                else {
                    NSLog(@"%@",[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
                }
            }
        } while ((childElement = childElement->nextSibling));
    }
    
    else if ([rootName isEqualToString:@"wired.chat.user_list"] ||
             [rootName isEqualToString:@"wired.chat.user_status"] ||
             [rootName isEqualToString:@"wired.chat.user_join"]) {
        NSLog(@"Received info about a user in the channel.");
        
        NSString *userID = @"", *channel = @"1";
        NSMutableDictionary *channelInfo, *userInfo = [NSMutableDictionary dictionary];
        
        // TODO: User icon should be returned as NSData.
        // TODO: Return NSColor for user color (?).
        // TODO: Return BOOL for idle (?).
        // TODO: Return NSDate for idle time (?).
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.chat.id"]) {
                channel = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.id"]) {
                userID = [TBXML textForElement:childElement];
                [userInfo setValue:userID forKey:@"wired.user.id"];
            }
            
            else {
                childValue = [TBXML textForElement:childElement];
                [userInfo setValue:childValue forKey:childName];
            }
        } while ((childElement = childElement->nextSibling));
        
        // If we have existing channel data saved, be sure not to overwrite it.
        channelInfo = [userList objectForKey:channel];
        if (channelInfo == nil) {
            channelInfo = [NSMutableDictionary dictionary];
        }
        
        // If we don't have data for the user already then they've just joined.
        if ([channelInfo objectForKey:userID] == nil) {
            [delegate userJoined:[userInfo objectForKey:@"wired.user.nick"] withID:userID];
        }
        
        // Save the new channel info and user info into the user list.
        [channelInfo setValue:userInfo forKey:userID];
        [userList setValue:channelInfo forKey:channel];
    }
    
    else if ([rootName isEqualToString:@"wired.chat.user_leave"]) {
        NSLog(@"User has left the channel.");
        NSString *userID = @"0", *nick = @"Unknown", *channel = @"1";
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.chat.id"]) {
                channel = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.id"]) {
                userID = [TBXML textForElement:childElement];
            }
        } while ((childElement = childElement->nextSibling));
        
        nick = [[[userList objectForKey:channel] objectForKey:userID] objectForKey:@"wired.user.nick"];
        
        // Remove the user from the user list.
        [[userList objectForKey:channel] removeObjectForKey:userID];
        
        [delegate userLeft:nick withID:userID];
    }
    
    else if ([rootName isEqualToString:@"wired.chat.user_list.done"]) {
        NSLog(@"Finished receiving a list of users in the channel.");
        [delegate setUserList:userList];
    }
    
    else if ([rootName isEqualToString:@"wired.chat.topic"]) {
        NSLog(@"Received channel topic.");
        NSString *topic = @"", *nick = @"Unknown", *channel = @"1";
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.chat.id"]) {
                channel = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.nick"]) {
                nick = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.chat.topic.topic"]) {
                topic = [TBXML textForElement:childElement];
            }
        } while ((childElement = childElement->nextSibling));
        
        [delegate didReceiveTopic:topic fromNick:nick forChannel:channel];
    }
    
    else if ([rootName isEqualToString:@"wired.chat.say"]) {
        NSLog(@"Received a chat message.");
        NSString *message = @"", *userID = @"0", *nick = @"Unknown", *channel = @"1";
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.chat.id"]) {
                channel = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.id"]) {
                userID = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.chat.say"]) {
                message = [TBXML textForElement:childElement];
            }
        } while ((childElement = childElement->nextSibling));
        
        nick = [[[userList objectForKey:channel] objectForKey:userID] objectForKey:@"wired.user.nick"];
        
        [delegate didReceiveChatMessage:message fromNick:nick withID:userID forChannel:channel];
    }
    
    else if ([rootName isEqualToString:@"wired.chat.me"]) {
        NSLog(@"Received an emote.");
        NSString *message = @"", *userID = @"0", *nick = @"Unknown", *channel = @"1";
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.chat.id"]) {
                channel = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.id"]) {
                userID = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.chat.me"]) {
                message = [TBXML textForElement:childElement];
            }
        } while ((childElement = childElement->nextSibling));
        
        nick = [[[userList objectForKey:channel] objectForKey:userID] objectForKey:@"wired.user.nick"];
        
        [delegate didReceiveEmote:message fromNick:nick withID:userID forChannel:channel];
    }
    
    else if ([rootName isEqualToString:@"wired.message.message"]) {
        NSLog(@"Received a message.");
        NSString *message = @"", *userID = @"0", *nick = @"Unknown";
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.user.id"]) {
                userID = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.message.message"]) {
                message = [TBXML textForElement:childElement];
            }
        } while ((childElement = childElement->nextSibling));
        
        nick = [[[userList objectForKey:@"1"] objectForKey:userID] objectForKey:@"wired.user.nick"];
        
        [delegate didReceiveMessage:message fromNick:nick withID:userID];
    }
    
    else if ([rootName isEqualToString:@"wired.message.broadcast"]) {
        NSLog(@"Received a broadcast.");
        NSString *message = @"", *userID = @"0", *nick = @"Unknown";
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.user.id"]) {
                userID = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.message.broadcast"]) {
                message = [TBXML textForElement:childElement];
            }
        } while ((childElement = childElement->nextSibling));
        
        nick = [[[userList objectForKey:@"1"] objectForKey:userID] objectForKey:@"wired.user.nick"];
        
        [delegate didReceiveBroadcast:message fromNick:nick withID:userID];
    }
    
    else {
        NSLog(@"%@",[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    }
    
    [self readData];
    [doc release];

}

- (void)dealloc
{
    [self disconnect];
    [super dealloc];
    [GCDAsyncSocket dealloc];
}

@end
