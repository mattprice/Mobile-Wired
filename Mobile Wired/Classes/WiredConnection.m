//
//  WiredConnection.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/16/11.
//  Copyright 2011 Ember Code. All rights reserved.
//

#import "WiredConnection.h"
#import "GDataXMLNode.h"


@implementation WiredConnection

@synthesize socket;

/*
 * Initiates a socket connection object.
 *
 */
- (id)init
{
    if((self = [super init])) {
        // Create a new socket connection using the main dispatch queue.
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    }
    
    return self;
}

/*
 * Connects to the given server and port specified.
 *
 * This method also handles sending the initial Wired connection requirements,
 * such as sending the handshake, compatibility check, and sending the client info.
 *
 */
- (BOOL)connectToServer:(NSString *)server onPort:(UInt16)port
{
    NSError *error = nil;
    
    // Attempt a socket connection to the server.
    NSLog(@"Beginning socket connection...");
    if(![socket connectToHost:server onPort:port withTimeout:10 error:&error]) {
        // Connection failed.
        NSLog(@"Connection error: %@",error);
        return false;
    }
    
    // Start sending Wired connection info.
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"p7.handshake.version",            @"1.0",
                                @"p7.handshake.protocol.name",      @"Wired",
                                @"p7.handshake.protocol.version",   @"2.0",
                                nil];
    [self sendTransaction:@"p7.handshake.client_handshake" withParameters:parameters];
    
    // TODO: Read response and verify.
    
    // Send acknowledgement.
    [self sendTransaction:@"p7.handshake.acknowledge"];
    
    return true;
}

/*
 * Sends a transaction message and its parameters to the Wired server.
 *
 * The message and paramaters could also be created using an XML framework,
 * but the replies are always so simple that it's not worth the processing power.
 */
- (void)sendTransaction:(NSString *)transaction withParameters:(NSDictionary *)parameters
{
    // Create a mutable string with the messages as XML.
    NSMutableString *generatedXML = [NSMutableString string];
    [generatedXML appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    [generatedXML appendString:[NSString stringWithFormat:@"[<p7:message name=\"%@\" xmlns:p7=\"http://www.zankasoftware.com/P7/Message\">",transaction]];
    
    if (parameters != nil) {
        for(id aParameter in parameters) {
            NSString *key = aParameter;
            NSString *value = [parameters valueForKey:key];
            [generatedXML appendString:[NSString stringWithFormat:@"<p7:field name=\"%@\">%@</p7:field>",key,value]];
        }
    }
    
    NSLog(@"%@",generatedXML);
    
    [socket writeData:[generatedXML dataUsingEncoding:NSUTF8StringEncoding] withTimeout:15 tag:0];
}

- (void)sendTransaction:(NSString *)transaction
{
    [self sendTransaction:transaction withParameters:nil];
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
