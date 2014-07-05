//
//  WiredConnection.m
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

#import "WiredConnection.h"
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

#pragma mark - User Commands
/*
 * Connects to the given server and port specified.
 *
 */
- (void)connectToServer:(NSString *)server onPort:(NSInteger)port
{
    NSError *error = nil;
    isConnected = false;
    userList = [[NSMutableDictionary alloc] init];
    serverInfo = [[NSMutableDictionary alloc] init];
    
    serverHost = server;
    serverPort = (port) ? port : 4871;
    
    // Attempt a socket connection to the server.
    NSLog(@"Beginning socket connection...");
    if (![socket connectToHost:serverHost onPort:(uint16_t)serverPort withTimeout:15 error:&error]) {
        // Connection failed.
        NSLog(@"Connection error: %@",error);
        [delegate didFailConnectionWithReason:error];
    }
}

- (void)disconnect
{
    NSLog(@"Attempting to disconnect from server...");
    
    NSDictionary *parameters = @{@"wired.user.id": myUserID,
                                 @"wired.user.disconnect_message": @""};
    [self sendTransaction:@"wired.user.disconnect_user" withParameters:parameters];
    
    // Alert the delegate that we're disconnectiong.
    [delegate didDisconnect];
    
    // Disconnect the socket and then release.
    isConnected = false;
    [socket setDelegate:nil];
    [socket disconnectAfterWriting];
    socket = nil;
    userList = nil, serverHost = nil, serverPort = 0;
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
    
    user = ([user length] > 0) ? user : @"guest";
    password = ([password length] > 0) ? password : @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    
    // Send the user login information to the Wired server.
    NSDictionary *parameters = @{@"wired.user.login": user,
                                @"wired.user.password": password};
    [self sendTransaction:@"wired.send_login" withParameters:parameters];
    [self readData];
}

- (void)setNick:(NSString *)nick
{
//    NSLog(@"Attempting to change nick to: %@...", nick);
    NSLog(@"Attempting to change nick.");
    
    NSDictionary *parameters = @{@"wired.user.nick": nick};
    [self sendTransaction:@"wired.user.set_nick" withParameters:parameters];
    [self readData];
}

- (void)setStatus:(NSString *)status
{
//    NSLog(@"Attempting to change status to: %@...", status);
    NSLog(@"Attempting to change status.");
    
    NSDictionary *parameters = @{@"wired.user.status": status};
    [self sendTransaction:@"wired.user.set_status" withParameters:parameters];
    [self readData];
}

- (void)setIcon:(NSData *)icon
{
    NSLog(@"Attempting to set user icon...");
    NSString *base64;
    
    // Create a base64 representation of the image.
    if (icon == nil) {
        base64 = @"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";
    } else {
        base64 = [icon base64EncodedStringWithOptions:0];
    }
    
    NSDictionary *parameters = @{@"wired.user.icon": base64};
    [self sendTransaction:@"wired.user.set_icon" withParameters:parameters];
    [self readData];
}

- (void)setIdle
{
    NSLog(@"Attempting to set user idle...");
    
    NSDictionary *parameters = @{@"wired.user.idle": @"YES"};
    [self sendTransaction:@"wired.user.set_idle" withParameters:parameters];
    [self readData];
}

#pragma mark - Connection Info

- (NSDictionary *)getMyUserInfo
{
    return userList[@"1"][myUserID];
}

- (NSDictionary *)getMyPermissions
{
    return myPermissions;
}

- (void)getInfoForUser:(NSString *)userID
{
    NSLog(@"Requesting info for user: %@...", userID);
    
    NSDictionary *parameters = @{@"wired.user.id": userID};
    [self sendTransaction:@"wired.user.get_info" withParameters:parameters];
    [self readData];
}

#pragma mark - Channel Commands

/*
 * Attempts to join a channel on the Wired server.
 *
 * We need to make sure we reset the user list for the channel every time we join it.
 * This is only for if the user was kicked since we reset all user lists on server connection.
 *
 * TODO: Check to make sure the channel was joined successfully.
 *
 */
- (void)joinChannel:(NSString *)channel
{
    NSLog(@"Attempting to join channel %@...",channel);
    
    // Reset the user list for this channel.
    [userList removeObjectForKey:channel];
    
    // Attempt to join the channel.
    NSDictionary *parameters = @{@"wired.chat.id": channel};
    [self sendTransaction:@"wired.chat.join_chat" withParameters:parameters];
    [self readData];
}

- (void)leaveChannel:(NSString *)channel
{
    NSLog(@"Attempting to leave channel %@...",channel);
    
    NSDictionary *parameters = @{@"wired.chat.id": channel};
    [self sendTransaction:@"wired.chat.leave_chat" withParameters:parameters];
    [self readData];
}

/*
 * Attempts to set the channel topic.
 *
 * User must have the correct permissions in order to set the topic.
 * We currently do not check for those permissions.
 *
 * TODO: Check for errors, such as lack of permission.
 *
 */
- (void)setTopic:(NSString *)topic forChannel:(NSString *)channel
{
    NSLog(@"Attempting to set topic for channel %@...",channel);
    
    NSDictionary *parameters = @{@"wired.chat.id": channel,
                                @"wired.chat.topic.topic": topic};
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
 * TODO: Clear and Ping commands.
 * TODO: Need a less messy way to handle blank commands.
 *
 */
- (void)sendChatMessage:(NSString *)message toChannel:(NSString *)channel
{
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
        
        NSDictionary *parameters = @{@"wired.chat.id": channel,
                                    @"wired.chat.say": message};
        [self sendTransaction:@"wired.chat.send_say" withParameters:parameters];
        [self readData];
    }
}

- (void)sendChatEmote:(NSString *)message toChannel:(NSString *)channel
{
    NSLog(@"Attempting to send emote...");
    
    NSDictionary *parameters = @{@"wired.chat.id": channel,
                                @"wired.chat.me": message};
    [self sendTransaction:@"wired.chat.send_me" withParameters:parameters];
    [self readData];
}

- (void)sendMessage:(NSString *)message toID:(NSString *)userID
{
    NSLog(@"Attempting to message...");
    
    NSDictionary *parameters = @{@"wired.user.id": userID,
                                @"wired.message.message": message};
    [self sendTransaction:@"wired.message.send_message" withParameters:parameters];
    [self readData];
}

- (void)sendBroadcast:(NSString *)message
{
    NSLog(@"Attempting to send broadcast...");
    
    NSDictionary *parameters = @{@"wired.message.broadcast": message};
    [self sendTransaction:@"wired.message.send_broadcast" withParameters:parameters];
    [self readData];
}

- (void)kickUserID:(NSString *)userID fromChannel:(NSString *)channel message:(NSString *)message
{
    NSLog(@"Attempting to kick user...");
    
    NSDictionary *parameters = @{@"wired.chat.id": channel,
                                @"wired.user.id": userID,
                                @"wired.user.disconnect_message": message};
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
        parameters[@"wired.banlist.expiration_date"] = dateString;
    }
    
    parameters[@"wired.user.id"] = userID;
    parameters[@"wired.user.disconnect_message"] = message;
    
    [self sendTransaction:@"wired.user.ban_user" withParameters:parameters];
    [self readData];
}

#pragma mark - Connection Helpers

/*
 * Sends a compatibility check to the server.
 *
 * Reads in the WiredSpec XML file and sends it to the server. Wired requires that
 * certain characters be encoded before sending. To save processing time the XML
 * should be pre-encoded. To save bandwidth the documentation lines should be removed.
 * 
 * The orginal code is left in only for reference.
 *
 */
- (void)sendCompatibilityCheck
{
    NSLog(@"Sending compatibility check...");
    
    // Send the correct WiredSpec XML file depending on what version the server is.
    // TODO: There's probably a better way of handling multiple server versions but this works for now.
    NSString *resource, *version = serverInfo[@"p7.handshake.protocol.version"];
    
    if ([version isEqualToString:@"2.0b55"])
        resource = @"WiredSpec_2.0b55";

    else if ([version isEqualToString:@"2.0b53"])
        resource = @"WiredSpec_2.0b53";
    
    else if ([version isEqualToString:@"2.0b51"])
        resource = @"WiredSpec_2.0b51";
    
    else
        resource = @"WiredSpec_2.0b55";
    
    NSString *contents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resource ofType:@"xml"]
                                                   encoding:NSUTF8StringEncoding error:nil];
    
    // Escape the XML document.
//    contents = [[[[[contents stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;"]
//                   stringByReplacingOccurrencesOfString: @"\"" withString: @"&quot;"]
//                  stringByReplacingOccurrencesOfString: @"'" withString: @"&#39;"]
//                 stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"]
//                stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"];
    
    NSDictionary *parameters = @{@"p7.compatibility_check.specification": contents};
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
                                @"268",           @"wired.info.application.build",
                                @"Mac OS X",      @"wired.info.os.name",
                                @"10.8.3",        @"wired.info.os.version",
                                @"x86_64",        @"wired.info.arch",
                                @"false",         @"wired.info.supports_rsrc",
                                nil];
#else
    NSString *CFBundleVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *CFBundleBuild = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    NSDictionary *parameters = @{@"wired.info.application.name": @"Mobile Wired",
                                @"wired.info.application.version": CFBundleVersion,
                                @"wired.info.application.build": CFBundleBuild,
                                @"wired.info.os.name": [[UIDevice currentDevice] systemName],
                                @"wired.info.os.version": [[UIDevice currentDevice] systemVersion],
                                @"wired.info.arch": [[UIDevice currentDevice] model],
                                @"wired.info.supports_rsrc": @"false"};
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

- (void)attemptReconnection
{
    failCount++;
    [self connectToServer:serverHost onPort:serverPort];
}

#pragma mark - GCDAsyncSocket Wrappers
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
    
    // Reset the failCount if we were in a reconnecting loop.
    failCount = 0;
    
    // Start sending Wired connection info.
    NSLog(@"Sending Wired handshake...");
    NSDictionary *parameters = @{@"p7.handshake.version": @"1.0",
                                @"p7.handshake.protocol.name": @"Wired",
                                @"p7.handshake.protocol.version": @"2.0"};
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
    settings[(NSString *)kCFStreamSSLValidatesCertificateChain] = @NO;
    
    [socket startTLS:settings];
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    NSLog(@"socketDidSecure:%p", sock);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error
{
    NSLog(@"Server disconnected unexpectedly. <Error: %@>", error);
    
    // If we're already connected then we must have unexpected disconnected.
    // TODO: Change isConnected to something else when we're in the process of connecting.
    if (isConnected && !failCount) {
        failCount = 1;
        
        [delegate willReconnect];
        [delegate willReconnectDelayed:@"00:10"];
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(attemptReconnection) userInfo:nil repeats:NO];
    }
    
    // If we have a failCount then we must be in a reconnecting loop.
    else if (failCount && failCount < 3) {
        [delegate willReconnectDelayed:@"00:10" withError:error];
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(attemptReconnection) userInfo:nil repeats:NO];
    }
    
    // Anything else must be an utter connection failure. Sorry guys!
    else {
        [delegate didFailConnectionWithReason:error];
    }
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
            NSString *value = parameters[key];
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
    TBXML *doc = [[TBXML alloc] initWithXMLData:data error:&error];
    
    // Extract the root element and its name.
    if (error || !doc.rootXMLElement) {  return; }
    rootElement = doc.rootXMLElement;
    
    rootName = [TBXML valueOfAttributeNamed:@"name" forElement:rootElement];
    childElement = rootElement->firstChild;
    
#pragma mark Handshake
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
            
            else if ([childName isEqualToString:@"p7.handshake.protocol.version"]) {
                childValue = [TBXML textForElement:childElement];
                
                [serverInfo setValue:childValue forKey:@"p7.handshake.protocol.version"];
            }
        } while ((childElement = childElement->nextSibling));
    }

#pragma mark Compatibility Check
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
    
#pragma mark Server Info
    else if ([rootName isEqualToString:@"wired.server_info"]) {
        NSLog(@"Received server info.");
        NSData *serverBanner;
        NSDate *startTime;
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.info.banner"]) {
                serverBanner = [[NSData alloc] initWithBase64EncodedString:[TBXML textForElement:childElement] options:0];
                [serverInfo setValue:serverBanner forKey:@"wired.info.banner"];
            }
            
            else if ([childName isEqualToString:@"wired.info.start_time"]) {
                startTime = [NSDate dateWithTimeIntervalSince1970:[[TBXML textForElement:childElement] intValue]];
                [serverInfo setValue:startTime forKey:@"wired.info.start_time"];
            }
            
            else {
                childValue = [TBXML textForElement:childElement];
                serverInfo[childName] = childValue;
            }
            
        } while ((childElement = childElement->nextSibling));
        
        [delegate didReceiveServerInfo:serverInfo];
    }
    
#pragma mark Login Successful
    else if ([rootName isEqualToString:@"wired.login"]) {
        NSLog(@"Login was successful.");
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.user.id"]) {
                childValue = [TBXML textForElement:childElement];
                myUserID = childValue;
            }
        } while ((childElement = childElement->nextSibling));
        
        [delegate didLoginSuccessfully];
    }
    
#pragma mark Account Priviledges
    else if ([rootName isEqualToString:@"wired.account.privileges"]) {
        NSLog(@"Received account priviledges.");
        
        NSMutableDictionary *tempInfo = [NSMutableDictionary dictionary];
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            childValue = [TBXML textForElement:childElement];
            
            [tempInfo setValue:childValue forKey:childName];
        } while ((childElement = childElement->nextSibling));
        
        myPermissions = tempInfo;
    }
    
#pragma mark Okay
    else if ([rootName isEqualToString:@"wired.okay"]) {
        // TODO: We should really keep up with what command this refers to.
        NSLog(@"The last command was successful.");
    }
    
#pragma mark Ping Request
    else if ([rootName isEqualToString:@"wired.send_ping"]) {
        NSLog(@"Received ping request.");
        [self sendPingReply];
    }
    
#pragma mark Ping Reply
    else if ([rootName isEqualToString:@"wired.ping"]) {
        NSLog(@"Received ping reply.");
    }
    
#pragma mark Wired Error
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
                    NSString *prettyXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    prettyXML = [prettyXML stringByReplacingOccurrencesOfString:@"<p7:field" withString:@"\n\t<p7:field"];
                    prettyXML = [prettyXML stringByReplacingOccurrencesOfString:@"</p7:message>" withString:@"\n</p7:message>"];
                    NSLog(@"\n%@",prettyXML);
                }
            }
        } while ((childElement = childElement->nextSibling));
    }
    
#pragma mark User List (Partial)
#pragma mark User Status
#pragma mark User Joined
#pragma mark User Info
    else if ([rootName isEqualToString:@"wired.chat.user_list"]   ||
             [rootName isEqualToString:@"wired.chat.user_status"] ||
             [rootName isEqualToString:@"wired.chat.user_join"]   ||
             [rootName isEqualToString:@"wired.user.info"]) {
        NSLog(@"Received info about a user in the channel.");
        
        NSString *userID = @"", *channel = @"1";
        NSData *userIcon;
        NSDate *loginTime, *idleTime;
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
                userIcon = [[NSData alloc] initWithBase64EncodedString:[TBXML textForElement:childElement] options:0];
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
                    userColor = [UIColor colorWithRed:0.0f green:0.8f blue:0.0f alpha:1.0f];
                }
                        
                else if ([childValue isEqualToString:@"wired.account.color.blue"]) {
                    userColor = [UIColor blueColor];
                }
                
                else if ([childValue isEqualToString:@"wired.account.color.purple"]) {
                    userColor = [UIColor purpleColor];
                }
                
                else {
                    userColor = [UIColor colorWithHue:0.0f saturation:0.0f brightness:0.0f alpha:1.0f];
                }
                
                [tempInfo setValue:userColor forKey:@"wired.account.color"];
            }
            
            else if ([childName isEqualToString:@"wired.user.login_time"]) {
                loginTime = [NSDate dateWithTimeIntervalSince1970:[[TBXML textForElement:childElement] intValue]];
                [tempInfo setValue:loginTime forKey:@"wired.user.login_time"];
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
        
        // If this was a request for a specific user, return the user info and exit.
        if ([rootName isEqualToString:@"wired.user.info"]) {
            [delegate didReceiveUserInfo:tempInfo];
            return;
        }
        
        // If we have existing channel data saved, be sure not to overwrite it.
        channelInfo = userList[channel];
        if (channelInfo == nil) {
            channelInfo = [NSMutableDictionary dictionary];
        }
        
        // If we don't have data for the user already then create a new NSDictionary.
        userInfo = channelInfo[userID];
        if (userInfo == nil) {
            userInfo = [NSMutableDictionary dictionary];
        }
        
        // Check existing users for name changes.
        else {
            NSString *oldNick = userInfo[@"wired.user.nick"];
            NSString *newNick = tempInfo[@"wired.user.nick"];
            
            if (![oldNick isEqualToString:newNick]) {
                [delegate userChangedNick:oldNick toNick:newNick forChannel:channel];
            }
        }
        
        // If the user just joined then notify the delegate.
        if ([rootName isEqualToString:@"wired.chat.user_join"]) {
            [delegate userJoined:tempInfo[@"wired.user.nick"] withID:userID forChannel:channel];
        }
        
        [userInfo addEntriesFromDictionary:tempInfo];
        
        // Save the new channel info and user info into the user list.
        [channelInfo setValue:userInfo forKey:userID];
        [userList setValue:channelInfo forKey:channel];
        [delegate setUserList:userList forChannel:channel];
    }
    
#pragma mark User Icon
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
                userIcon = [[NSData alloc] initWithBase64EncodedString:[TBXML textForElement:childElement] options:0];
            }
        } while ((childElement = childElement->nextSibling));
        
        // Update the user's icon.
        NSMutableDictionary *userInfo = userList[channel][userID];
        userInfo[@"wired.user.icon"] = userIcon;
        userList[channel][userID] = userInfo;
        [delegate setUserList:userList forChannel:channel];
    }
    
#pragma mark User Left
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
        
        nick = userList[channel][userID][@"wired.user.nick"];
        
        // Remove the user from the user list.
        [(NSMutableDictionary *)userList[channel] removeObjectForKey:userID];
        
        [delegate userLeft:nick withID:userID forChannel:channel];
        [delegate setUserList:userList forChannel:channel];
    }
    
#pragma mark User Kicked
    else if ([rootName isEqualToString:@"wired.chat.user_kick"]) {
        NSLog(@"User was kicked from channel.");
        NSString *userID = @"0", *kickerUserID = @"0", *channel = @"1", *reason = @"";
        NSString *nick = @"Unknown", *kicker = @"Unknown";
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.chat.id"]) {
                channel = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.id"]) {
                kickerUserID = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.disconnected_id"]) {
                userID = [TBXML textForElement:childElement];
            }
            
            else if ([childName isEqualToString:@"wired.user.disconnect_message"]) {
                reason = [TBXML textForElement:childElement];
            }
        } while ((childElement = childElement->nextSibling));
        
        nick = userList[channel][userID][@"wired.user.nick"];
        kicker = userList[channel][kickerUserID][@"wired.user.nick"];
        
        [delegate userWasKicked:nick withID:userID byUser:kicker forReason:reason forChannel:channel];
    }
    
#pragma mark User List (Done)
    else if ([rootName isEqualToString:@"wired.chat.user_list.done"]) {
        NSLog(@"Finished receiving a list of users in the channel.");
        NSString *channel = @"1";
        
        do {
            childName = [TBXML valueOfAttributeNamed:@"name" forElement:childElement];
            
            if ([childName isEqualToString:@"wired.chat.id"]) {
                channel = [TBXML textForElement:childElement];
            }
        } while ((childElement = childElement->nextSibling));
        
        [delegate setUserList:userList forChannel:channel];
        
        // If we're already connected then we must be rejoining the channel.
        if (isConnected) {
            [delegate didReconnect];
        } else {
            [delegate didConnectAndLoginSuccessfully];
            isConnected = true;
        }
    }
    
#pragma mark Chat Topic
    else if ([rootName isEqualToString:@"wired.chat.topic"]) {
        NSLog(@"Received channel topic.");
        NSString *topic = @"", *nick = @"Unknown", *channel = @"1";
        NSDate *date;

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

            else if ([childName isEqualToString:@"wired.chat.topic.time"]) {
                double timeDouble = [[TBXML textForElement:childElement] doubleValue];
                date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)timeDouble];
            }
        } while ((childElement = childElement->nextSibling));
        
        // The channel topic needs to be XML decoded before notifying the delegate.
        topic = [[[[[topic stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"]
                       stringByReplacingOccurrencesOfString: @"&quot;" withString: @"\""]
                      stringByReplacingOccurrencesOfString: @"&#39;" withString: @"'"]
                     stringByReplacingOccurrencesOfString: @"&gt;" withString: @">"]
                    stringByReplacingOccurrencesOfString: @"&lt;" withString: @"<"];
        
        [delegate didReceiveTopic:topic fromNick:nick forChannel:channel onDate:date];
    }
    
#pragma mark Chat Message
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
        
        nick = userList[channel][userID][@"wired.user.nick"];
        
        [delegate didReceiveChatMessage:message fromNick:nick withID:userID forChannel:channel];
    }
    
#pragma mark Chat Emote
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
        
        nick = userList[channel][userID][@"wired.user.nick"];
        
        [delegate didReceiveEmote:message fromNick:nick withID:userID forChannel:channel];
    }
    
#pragma mark Private Message
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
        
        nick = userList[@"1"][userID][@"wired.user.nick"];
        
        [delegate didReceiveMessage:message fromNick:nick withID:userID];
    }
    
#pragma mark Broadcast
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
        
        nick = userList[@"1"][userID][@"wired.user.nick"];
        
        [delegate didReceiveBroadcast:message fromNick:nick withID:userID];
    }
    
#pragma mark Everything Else
    else {
        NSString *prettyXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        prettyXML = [prettyXML stringByReplacingOccurrencesOfString:@"<p7:field" withString:@"\n\t<p7:field"];
        prettyXML = [prettyXML stringByReplacingOccurrencesOfString:@"</p7:message>" withString:@"\n</p7:message>"];
        NSLog(@"\n%@",prettyXML);
    }
    
    [self readData];

}

- (void)dealloc
{
    [self disconnect];
    [GCDAsyncSocket dealloc];
}

@end
