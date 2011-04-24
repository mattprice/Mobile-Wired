//
//  WiredConnection.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/16/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import "WiredConnection.h"
#import "TBXML.h"
#import "ChatViewController.h"
#import <CommonCrypto/CommonHMAC.h>

#define TIMEOUT     -1
#define DATA_END    @"</p7:message>"

@implementation WiredConnection

@synthesize socket, delegate;

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
 * This method also handles sending the handshake.
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
    // TODO: Check to make sure the password/user was accepted.
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

- (void)joinChannel:(NSString *)channel
{
    NSLog(@"Attempting to join channel %@...",channel);
    
    // TODO: Check to make sure the channel was joined successfully.
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:channel forKey:@"wired.chat.id"];
    [self sendTransaction:@"wired.chat.join_chat" withParameters:parameters];
    [self readData];
}

- (void)sendChatMessage:(NSString *)message toChannel:(NSString *)channel
{
    NSLog(@"Attempting to send chat message...");
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                channel,  @"wired.chat.id",
                                message, @"wired.chat.say",
                                nil];
    [self sendTransaction:@"wired.chat.send_say" withParameters:parameters];
    [self readData];
}

#pragma mark Connection Helpers

/*
 * Sends a compatibility check to the server.
 *
 * Reads in MobileWired_Spec.xml and sends it to the server. Wired requires that
 * certain characters be encoded before sending. To save processing time, it
 * is now pre-encoded. The orginal code is left in only for reference.
 *
 */
- (void)sendCompatibilityCheck
{
    // TODO: Check server response to make sure it's required.
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

- (void)sendClientInformation
{
    NSLog(@"Sending client information...");
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Mobile Wired",  @"wired.info.application.name",
                                @"0.1",           @"wired.info.application.version",
                                @"10",             @"wired.info.application.build",
                                [[UIDevice currentDevice] systemName],    @"wired.info.os.name",
                                [[UIDevice currentDevice] systemVersion], @"wired.info.os.version",
                                [[UIDevice currentDevice] model],         @"wired.info.arch",
                                @"false",         @"wired.info.supports_rsrc",
                                nil];
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

- (void)readData
{
    [socket readDataToData:[DATA_END dataUsingEncoding:NSUTF8StringEncoding] withTimeout:TIMEOUT tag:0];
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
    [socket writeData:[generatedXML dataUsingEncoding:NSUTF8StringEncoding] withTimeout:TIMEOUT tag:0];
}

- (void)sendTransaction:(NSString *)transaction
{
    [self sendTransaction:transaction withParameters:nil];
}

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
        [delegate didReceiveServerInfo];
    }
    
    else if ([rootName isEqualToString:@"wired.login"]) {
        NSLog(@"Login was successful.");
        [delegate didLoginSuccessfully];
    }
    
    else if ([rootName isEqualToString:@"wired.account.privileges"]) {
        NSLog(@"Received account priviledges.");
    }
    
    else if ([rootName isEqualToString:@"wired.okay"]) {
        NSLog(@"The last command was successful.");
    }
    
    else if ([rootName isEqualToString:@"wired.chat.user_list"]) {
        NSLog(@"Received info about a user in the channel.");
    }
    
    else if ([rootName isEqualToString:@"wired.chat.user_list.done"]) {
        NSLog(@"Finished receiving a list of users in the channel.");
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
        
        [delegate didReceiveMessage:message fromNick:nick withID:userID forChannel:channel];
        [self sendOkay];
    }
    
    [socket readDataToData:[DATA_END dataUsingEncoding:NSUTF8StringEncoding] withTimeout:TIMEOUT tag:0];
    [doc release];

}

- (void)dealloc
{
    // Disconnect the socket and then release.
    [socket setDelegate:nil];
    [socket disconnectAfterWriting];
    [socket release];
    
    [super dealloc];
    [GCDAsyncSocket dealloc];
}

@end
