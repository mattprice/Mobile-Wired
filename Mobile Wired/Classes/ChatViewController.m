//
//  ChatViewController.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code. All rights reserved.
//

#import "ChatViewController.h"


@implementation ChatViewController

@synthesize connection;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create a new WiredConnection.
    connection = [[WiredConnection alloc] init];
    [connection connectToServer:@"chat.embercode.com" onPort:2359];
    
    // Set the server name.
    [serverTitle setTitle:@"Code Monkey"];
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
