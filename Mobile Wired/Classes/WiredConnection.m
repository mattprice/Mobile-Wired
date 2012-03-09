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

#define STEALTH_MODE  FALSE


@implementation WiredConnection

@synthesize socket, delegate;
@synthesize userList, myUserID;
@synthesize serverInfo, isConnected;

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
 */
- (void)connectToServer:(NSString *)server onPort:(UInt16)port
{
    NSError *error = nil;
    isConnected = false;
    userList = [[NSMutableDictionary alloc] init];
    serverInfo = [[NSMutableDictionary alloc] init];
    
    // Attempt a socket connection to the server.
    NSLog(@"Beginning socket connection...");
    if (![socket connectToHost:server onPort:port withTimeout:15 error:&error]) {
        // Connection failed.
        NSLog(@"Connection error: %@",error);
        [delegate didFailConnectionWithReason:error];
    }
}

- (void)disconnect
{
    NSLog(@"Attempting to disconnect from server...");
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                myUserID, @"wired.user.id",
                                @"",      @"wired.user.disconnect_message",
                                nil];
    [self sendTransaction:@"wired.user.disconnect_user" withParameters:parameters];
    
    // Disconnect the socket and then release.
    isConnected = false;
    [socket setDelegate:nil];
    [socket disconnectAfterWriting];
    socket = nil;
    userList = nil;
}

/*
 * Sends a users login information to the Wired server.
 *
 * The password must be converted to a SHA1 digest before sending it
 * to the server, which is now done before hitting this method.
 *
 */
- (void)sendLogin:(NSString *)user withPassword:(NSString *)password
{
    NSLog(@"Sending login information...");
    
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

- (void)setIcon:(NSData *)icon
{
    NSLog(@"Attempting to set user icon...");
    NSString *base64;
    
    // Create a base64 representation of the image.
    if (icon == nil) {
        base64 = @"iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAA6pJREFUSMftVktPE1EU7g/RpQlQ3iJ1FMX4NlGJCdGY+Fpposa4MEZXLjSujCGamLhwR8Q+AbECFlCB+IhArMRHFNFi6dx50Xb6munMdPxmaijB0haNiQtuTprbe++c75zznXPutazvZP6pWFYA/hKAMn/XeZgGtyGNntziXwFAha2TqXWRCjtd4yT4u+Uh29zN2jxMlYNY7aTORf4cAOpqXKTKSQ4PCHfex8Y4mU1qYtqQ2YQ6TEs3/OK+Xq7CQda6inuTBwBWt/Rxg0FJ1jJsSvUGUrcnY1fHo9cnonc/xIdDUkLJQDqmEs0P2WoHTZUOgKOw6/yLcFTWvkSUCy8jWLHa6Qo7sToMwaTSQbb1sDf9saicCcbVQz6+yoxhSQCI76nhOV3X3dNJ8Gl10KCXWsBqdrLWTcrt9J7H3Kdwmk9p+/v4ApTkAJAkW7pZLqn1/5AQpcLxxRYM39TNhBKqX0jDjsaiAPD91mQspmjbHrG1Bb3OCtKszE4fHRLufYxjns3gJQGwXediJrg0KC17QBeuDNgLa+rcBKbs9HKgekOXsVKbL1C/APANDn0VlbZ3MTBZQDvKYmMXc21cHCUSnVDFdCYsa58jivNr8tCAUOmgF7mS8wBFhHN3P8bLlwDIxr3Vx78T0nq+kVQybZMiLFiIYZkPKFLIF5Te8mk4a8sXUKTKbi83G1f1ggNEVjpJHpKrneTMSBgn8Fv2YDHJlJkF9qmEXmwk1cyB/lziWhZmRbWT7ptJRWQjtbNMzMM0mgXxTVT1Esa1iSgSnfq90FBBIBB5jfI5NxqGyRAsQjuyoKmLDcZLArjpF/MDUEagjYlnGo7qI7R08WVkl5eDdlCHDHk2K5UCcPL5HBil8jY7yvTDavYM9DU0JQiI7Z9JYffEM0HLFNH+PCTVu3OJZFmqSpGRVU56t5c9Oxq2TyXx5UEfv7o9dGUsKqtLgrxh5e09bL2r5ButwU1WtYcuv4rwkoZKbOnjEa5jQ8LQrNG05/Uqmv49pqKrZ7OZKvHKNHq1g27qYgKiev9L4tLrCOJzeiS8poOuN2qC9QVTWQC4iD6BuDd4FrdIS0HzmSODgp836jYQU1Jq5s77OBZtZgyBvbWHRfGbuyruuDrXci59FHODh7wgMvT+iKs9gdTxp4J1QavJ9qUdjzh0IUHSpqNKSz8HepfxqgAGbNzbyzV1G2Vc4yS/x7DejAyOtT7hN+NVsNxnCwICFes8TNFj4Na28nT8PwF+AtAeCZTCkyndAAAAAElFTkSuQmCC";
    } else {
        base64 = [NSString encodeBase64WithData:icon];
    }
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:base64 forKey:@"wired.user.icon"];
    [self sendTransaction:@"wired.user.set_icon" withParameters:parameters];
    [self readData];
}

- (void)setIdle
{
    NSLog(@"Attempting to set user idle...");
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"YES" forKey:@"wired.user.idle"];
    [self sendTransaction:@"wired.user.set_idle" withParameters:parameters];
    [self readData];
}

#pragma mark Connection Info

- (NSDictionary *)getMyUserInfo
{
    // User list heirarchy is Channel -> User Info.
    return [[userList objectForKey:@"1"] objectForKey:myUserID];
}

- (void)getInfoForUser:(NSString *)userID
{
    NSLog(@"Requesting info for user: %@...", userID);
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:userID forKey:@"wired.user.id"];
    [self sendTransaction:@"wired.user.get_info" withParameters:parameters];
    [self readData];
}

- (NSDictionary *)getServerInfo
{
    return serverInfo;
}

- (Boolean)isConnected
{
    return isConnected;
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
    // TODO: Need a less messy way to handle blank commands.
    if ([message isEqualToString:@"/afk"]) {
        [self setIdle];
    }
    
    else if ([message hasPrefix:@"/me "]) {
        message = [message stringByReplacingOccurrencesOfString:@"/me " withString:@""];
        [self sendChatEmote:message toChannel:channel];
    }
    
    else if ([message hasPrefix:@"/status"]) {
        message = [message stringByReplacingOccurrencesOfString:@"/status " withString:@""];
        message = [message stringByReplacingOccurrencesOfString:@"/status" withString:@""];
        [self setStatus:message];
    }
    
    else if ([message hasPrefix:@"/nick "]) {
        message = [message stringByReplacingOccurrencesOfString:@"/nick " withString:@""];
        [self setNick:message];
    }
    
    else if ([message hasPrefix:@"/topic"]) {
        message = [message stringByReplacingOccurrencesOfString:@"/topic " withString:@""];
        message = [message stringByReplacingOccurrencesOfString:@"/topic" withString:@""];
        [self setTopic:message forChannel:channel];
    }
    
    else if ([message hasPrefix:@"/broadcast "]) {
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

- (void)kickUserID:(NSString *)userID fromChannel:(NSString *)channel message:(NSString *)message
{
    NSLog(@"Attempting to kick user...");
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                channel, @"wired.chat.id",
                                userID,  @"wired.user.id",
                                message, @"wired.user.disconnect_message",
                                nil];
    [self sendTransaction:@"wired.chat.kick_user" withParameters:parameters];
    [self readData];
}

/*
 * Bans a user from the server.
 *
 * This method bans an IP address, not a user's account. Banning an account
 * isn't possible with current Wired servers, so just delete it instead.
 *
 * Note: If Wired doesn't receive an expiration date then it bans the IP
 * address permanently. Otherwise, the ban expires at the time specified.
 * The expiration date needs to be sent based off the GMT timezone.
 *
 * Note: Disconnect message can be left blank but we still have to send it.
 *
 */
- (void)banUserID:(NSString *)userID message:(NSString *)message expiration:(NSDate *)expiration
{
    NSLog(@"Attempting to ban user...");
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    // If no expiration date was listed then be sure not to send one back.
    // Otherwise, convert the date to GMT and format it correctly.
    if (expiration != nil) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSTimeZone *GMT = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [dateFormatter setTimeZone:GMT];
        
        NSString *dateString = [dateFormatter stringFromDate:expiration];
        [parameters setObject:dateString forKey:@"wired.banlist.expiration_date"];
    }
    
    [parameters setObject:userID  forKey:@"wired.user.id"];
    [parameters setObject:message forKey:@"wired.user.disconnect_message"];
    
    [self sendTransaction:@"wired.user.ban_user" withParameters:parameters];
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
 * Runs anything that needs to be done post-connection.
 *
 * This attempts to enable background support (if not in the simulator)
 * and then attempts to start a SSL/TLS connection to the server.
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
    
    // Start sending Wired connection info.
    NSLog(@"Sending Wired handshake...");
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"1.0",   @"p7.handshake.version",
                                @"Wired", @"p7.handshake.protocol.name",
                                @"2.0",   @"p7.handshake.protocol.version",
                                nil];
    [self sendTransaction:@"p7.handshake.client_handshake" withParameters:parameters];
    [self readData];
}

- (void)secureSocket
{
    NSLog(@"Attempting to secure connection...");
    
    // Configure SSL/TLS settings.
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:1];
    
    // Don't validate the certificate chain. This is insecure, but we
    // don't know the Wired server's SSL certificate in advance.
    [settings setObject:[NSNumber numberWithBool:NO]
                 forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
    
    [socket startTLS:settings];
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    NSLog(@"socketDidSecure:%p", sock);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
    NSLog(@"Server disconnected unexpectedly. <Error: %@>", error);
    [delegate didFailConnectionWithReason:error];
    isConnected = false;
}

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
    NSString *CRLF = [[NSString alloc] initWithData:[GCDAsyncSocket CRLFData] encoding:NSUTF8StringEncoding];
    
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
    NSError *error;
    TBXML *doc = [TBXML tbxmlWithXMLData:data error:&error];
    
    // Extract the root element and its name.
    if (error || !doc.rootXMLElement) {  return; }
    rootElement = doc.rootXMLElement;
    
    rootName = [TBXML valueOfAttributeNamed:@"name" forElement:rootElement];
    childElement = rootElement->firstChild;
    
    if ([rootName isEqualToString:@"p7.handshake.server_handshake"]) {
        NSLog(@"Received handshake.");
        
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
        NSData *serverBanner;
        NSDate *startTime;
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.info.banner"]) {
                serverBanner = [NSString decodeBase64WithString:[TBXML textForElement:childElement]];
                [serverInfo setValue:serverBanner forKey:@"wired.info.banner"];
            }
            
            else if ([childName isEqualToString:@"wired.info.start_time"]) {
                startTime = [NSDate dateWithTimeIntervalSince1970:[[TBXML textForElement:childElement] intValue]];
                [serverInfo setValue:startTime forKey:@"wired.info.start_time"];
            }
            
            else {
                childValue = [TBXML textForElement:childElement];
                [serverInfo setObject:childValue forKey:childName];
            }
            
        } while ((childElement = childElement->nextSibling));
        
        [delegate didReceiveServerInfo:serverInfo];
    }
    
    else if ([rootName isEqualToString:@"wired.login"]) {
        NSLog(@"Login was successful.");
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.user.id"]) {
                childValue = [TBXML textForElement:childElement];
                myUserID = [[NSString alloc] initWithString:childValue];
            }
        } while ((childElement = childElement->nextSibling));
        
        isConnected = true;
        [delegate didLoginSuccessfully];
    }
    
    else if ([rootName isEqualToString:@"wired.account.privileges"]) {
        NSLog(@"Received account priviledges.");
    }
    
    else if ([rootName isEqualToString:@"wired.okay"]) {
        // We should really keep up with what command this refers to.
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
                    [delegate didFailLoginWithReason:@"user or password is wrong"];
                }
                
                else if ([childValue isEqualToString:@"wired.banned"]) {
                    NSLog(@"Login failed: user is banned.");
                    [delegate didFailLoginWithReason:@"user is banned"];
                }
                
                else {
                    NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                }
            }
        } while ((childElement = childElement->nextSibling));
    }
    
    else if ([rootName isEqualToString:@"wired.chat.user_list"] ||
             [rootName isEqualToString:@"wired.chat.user_status"] ||
             [rootName isEqualToString:@"wired.chat.user_join"]) {
        NSLog(@"Received info about a user in the channel.");
        
        NSString *userID = @"", *channel = @"1";
        NSData *userIcon;
        NSDate *idleTime;
        UIColor *userColor;
        NSMutableDictionary *channelInfo, *userInfo, *tempInfo = [NSMutableDictionary dictionary];
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.chat.id"]) {
                channel = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.id"]) {
                userID = [TBXML textForElement:childElement];
                [tempInfo setValue:userID forKey:@"wired.user.id"];
            }
            
            else if ([childName isEqualToString:@"wired.user.icon"]) {
                userIcon = [NSString decodeBase64WithString:[TBXML textForElement:childElement]];
                [tempInfo setValue:userIcon forKey:@"wired.user.icon"];
            }
            
            else if ([childName isEqualToString:@"wired.account.color"]) {
                childValue = [TBXML textForElement:childElement];
                
                if ([childValue isEqualToString:@"wired.account.color.red"]) {
                    userColor = [UIColor redColor];
                }
                        
                else if ([childValue isEqualToString:@"wired.account.color.orange"]) {
                    userColor = [UIColor orangeColor];
                }
                        
                else if ([childValue isEqualToString:@"wired.account.color.green"]) {
                    userColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0];
                }
                        
                else if ([childValue isEqualToString:@"wired.account.color.blue"]) {
                    userColor = [UIColor blueColor];
                }
                
                else if ([childValue isEqualToString:@"wired.account.color.purple"]) {
                    userColor = [UIColor purpleColor];
                }
                
                else {
                    userColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.0 alpha:1.0];
                }
                
                [tempInfo setValue:userColor forKey:@"wired.account.color"];
            }
            
            else if ([childName isEqualToString:@"wired.user.idle_time"]) {
                idleTime = [NSDate dateWithTimeIntervalSince1970:[[TBXML textForElement:childElement] intValue]];
                [tempInfo setValue:idleTime forKey:@"wired.user.idle_time"];
            }
            
            else {
                childValue = [TBXML textForElement:childElement];
                [tempInfo setValue:childValue forKey:childName];
            }
        } while ((childElement = childElement->nextSibling));
        
        // If we have existing channel data saved, be sure not to overwrite it.
        channelInfo = [userList objectForKey:channel];
        if (channelInfo == nil) {
            channelInfo = [NSMutableDictionary dictionary];
        }
        
        // If we don't have data for the user already then they've just joined.
        if ((userInfo = [channelInfo objectForKey:userID]) == nil) {
            userInfo = [NSMutableDictionary dictionary];
            [delegate userJoined:[tempInfo objectForKey:@"wired.user.nick"] withID:userID];
        }
        
        [userInfo addEntriesFromDictionary:tempInfo];
        
        // Save the new channel info and user info into the user list.
        [channelInfo setValue:userInfo forKey:userID];
        [userList setValue:channelInfo forKey:channel];
        [delegate setUserList:userList];
    }
    
    else if ([rootName isEqualToString:@"wired.chat.user_icon"]) {
        NSLog(@"Received new icon for user.");
        NSString *userID = @"0", *channel = @"1";
        NSData *userIcon = [NSData data];
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.user.id"]) {
                userID = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.icon"]) {
                userIcon = [NSString decodeBase64WithString:[TBXML textForElement:childElement]];
            }
        } while ((childElement = childElement->nextSibling));
        
        // Update the user's icon.
        NSMutableDictionary *userInfo = [[userList objectForKey:channel] objectForKey:userID];
        [userInfo setObject:userIcon forKey:@"wired.user.icon"];
        [[userList objectForKey:channel] setObject:userInfo forKey:userID];
        [delegate setUserList:userList];
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
        [delegate setUserList:userList];
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
    
    else if ([rootName isEqualToString:@"wired.user.info"]) {
        NSLog(@"Received user info.");
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        NSDate *idleTime, *loginTime;
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            childValue = [TBXML textForElement:childElement];
            
            if ([childName isEqualToString:@"wired.user.login_time"]) {
                loginTime = [NSDate dateWithTimeIntervalSince1970:[childValue intValue]];
                [userInfo setValue:loginTime forKey:@"wired.user.login_time"];
            }
            
            else if ([childName isEqualToString:@"wired.user.idle_time"]) {
                idleTime = [NSDate dateWithTimeIntervalSince1970:[childValue intValue]];
                [userInfo setValue:idleTime forKey:@"wired.user.idle_time"];
            }
            
            else {
                [userInfo setObject:childValue forKey:childName];
            }
            
        } while ((childElement = childElement->nextSibling));
        
        [delegate didReceiveUserInfo:userInfo];
    }
    
    else {
        NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
    
    [self readData];

}

- (void)dealloc
{
    [self disconnect];
    [GCDAsyncSocket dealloc];
}

@end
