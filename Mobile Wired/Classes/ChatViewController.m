//
//  ChatViewController.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import "ChatViewController.h"


@implementation ChatViewController

@synthesize connection;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the server name.
    [serverTitle setTitle:@"Code Monkey"];
    
    // Create a new WiredConnection.
    connection = [[WiredConnection alloc] init];
    connection.delegate = self;
    [connection connectToServer:@"chat.embercode.com" onPort:2359];
}

/*
 * Connection to server was successful.
 *
 * The server requires a login, nick, status, or icon after sending us its life story.
 * The specs suggest sending the nick/status/icon before sending the login info, but
 * any order we want would technically work.
 *
 */
- (void)didReceiveServerInfo
{
    // Set up the DefaultUserIcon if the user hasn't selected one of their one.
    NSData *userIcon = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultUserIcon" ofType:@"png"]];

    [connection setNick:@"Melman"];
    [connection setStatus:[NSString stringWithFormat:@"On my %@", [[UIDevice currentDevice] model]]];
    [connection setIcon:userIcon];
    [connection sendLogin:@"guest" withPassword:@""];
}

/*
 * Login to the server was successful.
 *
 * The server doesn't actually require us to send anything next, so we can really do
 * anything that we want. Download a file, join a channel, play with ourselves...
 *
 */
- (void)didLoginSuccessfully
{
    [connection joinChannel:@"1"];
//    [connection sendChatMessage:@"Test..." toChannel:@"1"];
    
//    [connection sendChatEmote:@"is having fun!" toChannel:@"1"];
//    [connection sendChatMessage:@"/me is testing slash commands!" toChannel:@"1"];
    
//    [connection sendChatMessage:@"/afk" toChannel:@"1"];
//    [connection setIdle];
//    [connection disconnect];
    
//    [connection sendBroadcast:@"Broadcast"];
}

/*
 * Received channel topic from server.
 *
 * Occurs on first joining the channel and on each time the topic is changed thereafter.
 * Only the subsequent changes should notify the user that the topic has changed.
 *
 */
- (void)didReceiveTopic:(NSString *)topic fromNick:(NSString *)nick forChannel:(NSString *)channel
{
    // Initial connection.
    if (serverTopic == nil) {
        NSLog(@"Channel #%@ topic: %@ (set by %@)",channel,topic,nick);
    }
    
    // Subsequent topic changes, so we should notify the user.
    else {
        NSLog(@"%@ | <<< %@ changed topic to '%@' >>>",channel,nick,topic);
    }
    
    [serverTopic setText:topic];
}

- (void)didReceiveChatMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
    // Message could be from anyone, including yourself.
    NSLog(@"%@ | %@ (%@) : %@",channel,nick,userID,message);
}

- (void)didReceiveMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID
{
    // Message could be from anyone, including yourself.
    NSLog(@"%@ (%@) : %@",nick,userID,message);
}

- (void)didReceiveBroadcast:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID
{
    // Message could be from anyone, including yourself.
    NSLog(@"%@ (%@) : %@",nick,userID,message);
}

- (void)didReceiveEmote:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
    // Emote could be from anyone, including yourself.
    NSLog(@"%@ | %@ (%@) %@",channel,nick,userID,message);
}

- (void)didReceiveLeaveFromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
    NSLog(@"%@ | <<< %@ has left. >>>",channel,nick);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload
{
    [serverTitle release], serverTitle = nil;
    [serverTopic release], serverTopic = nil;
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    [serverTitle release];
    [serverTopic release];
    [connection release];
    
    [super dealloc];
}

@end
