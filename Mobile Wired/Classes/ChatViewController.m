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

- (void)wiredConnectionDidFinish
{
    // TODO: None of these check to make sure it was successful.
    [connection sendLogin:@"guest" withPassword:@"guest"];
    [connection setNick:@"Mobile"];
    [connection joinChannel:@"1"];
    [connection sendChatMessage:@"Testing the delegate code." toChannel:@"1"];
    [connection readData];   
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
