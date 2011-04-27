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

    [connection setNick:@"Mobile"];
    [connection setStatus:[NSString stringWithFormat:@"On my %@", [[UIDevice currentDevice] model]]];
    [connection setIcon:userIcon];
    [connection sendLogin:@"guest" withPassword:@""];
}

- (void)didLoginSuccessfully
{
    // Server does not expect anything next, so do anything you want:
    // Joining channel could fail.
    [connection joinChannel:@"1"];
    [connection sendChatMessage:@"Test..." toChannel:@"1"];
    [connection sendChatEmote:@"is having fun!" toChannel:@"1"];
}

- (void)didReceiveTopic:(NSString *)topic fromNick:(NSString *)nick forChannel:(NSString *)channel
{
    // Occurs on first joining a channel and each time the topic is changed thereafter.
    NSLog(@"%@ | <<< %@ changed topic to '%@' >>>",channel,nick,topic);
}

- (void)didReceiveMessage:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
    // Message could be from anyone, including yourself.
    NSLog(@"%@ | %@ (%@) : %@",channel,nick,userID,message);
}

- (void)didReceiveEmote:(NSString *)message fromNick:(NSString *)nick withID:(NSString *)userID forChannel:(NSString *)channel
{
    // Emote could be from anyone, including yourself.
    NSLog(@"%@ | %@ (%@) %@",channel,nick,userID,message);
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
    [serverTitle release];
    serverTitle = nil;
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    [serverTitle release];
    [connection release];
    
    [super dealloc];
}

@end
