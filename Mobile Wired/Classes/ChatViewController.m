//
//  ChatViewController.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import "ChatViewController.h"
#import "NSString+Hashes.h"


@implementation ChatViewController

@synthesize connection;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set the server name.
    [serverTitle setTitle:@"Cunning Giraffe"];

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
- (void)didReceiveServerInfo:(NSDictionary *)serverInfo
{
    // Set up the DefaultUserIcon if the user hasn't selected one of their one.
    NSData *userIcon = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultUserIcon" ofType:@"png"]];

    [connection setNick:@"Melman"];
    [connection setStatus:[NSString stringWithFormat:@"On my %@", [[UIDevice currentDevice] model]]];
    [connection setIcon:userIcon];
    [connection sendLogin:@"guest" withPassword:[@"" SHA1Value]];
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

- (void)userStatusDidChange:(NSString *)newStatus withNick:(NSString *)nick withID:(NSString *)userID
{

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
    NSLog(@"%@",[[connection getMyUserInfo] description]);
}

- (void)didReceiveChatMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
    // Message could be from anyone, including yourself.
    NSLog(@"%@ | %@ (%@) : %@",channel,nick,userID,message);
}

/*
 * Received a private message from some user.
 *
 * Message could be from anyone, including yourself.
 *
 */
- (void)didReceiveMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID
{
    NSLog(@"%@ (%@) : %@",nick,userID,message);
}

/*
 * Received a broadcast from someone.
 *
 * Message could be from anyone, including yourself.
 *
 */
- (void)didReceiveBroadcast:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID
{
    NSLog(@"%@ (%@) : %@",nick,userID,message);
}

- (void)didReceiveEmote:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
    // Emote could be from anyone, including yourself.
    NSLog(@"%@ | %@ (%@) %@",channel,nick,userID,message);
}

- (void)userJoined:(NSString *)nick withID:(NSString *)userID
{
    NSLog(@"<<< %@ has joined >>>",nick);
    // [self.chatViewController printServerMessage:[NSString stringWithFormat:@"%@ has joined", nick]];
}

- (void)userLeft:(NSString *)nick withID:(NSString *)userID
{
    NSLog(@"<<< %@ has left >>>",nick);
    // [self.chatViewController printServerMessage:[NSString stringWithFormat:@"%@ has left", nick]];
}

- (void)updateConnectionProcessWithString:(NSString *)process
{
//    NSLog(@"%@",process);
}

- (void)didFailLoginWithReason:(NSString *)reason
{
//    NSLog(@"%@",reason);
}

/*
 * Received information about a user.
 *
 * This method is called when we receive specifically requested information about a user.
 *
 */
- (void)didReceiveUserInfo:(NSDictionary *)info
{

}

- (void)setUserList:(NSDictionary *)userList
{

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
    serverTitle = nil;
    serverTopic = nil;
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


@end
