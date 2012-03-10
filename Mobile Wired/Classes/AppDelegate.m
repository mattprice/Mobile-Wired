//
//  Mobile_WiredAppDelegate.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import "AppDelegate.h"

#import "IIViewDeckController.h"
#import "ChatViewController.h"
#import "UserListViewController.h"
#import "ServerListViewController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize leftView = _leftView;
@synthesize rightView = _rightView;
@synthesize centerView = _centerView;
@synthesize audioPlayer;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Set the status bar style
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];  
    
    // Setup the sliding UI
//    self.leftView = [[ServerListViewController alloc] initWithNibName:@"ServerListView" bundle:nil];
    self.rightView = [[UserListViewController alloc] initWithNibName:@"UserListView" bundle:nil];
    self.centerView = [[ChatViewController alloc] initWithNibName:@"ChatView" bundle:nil];
    
    self.centerView.userListView = self.rightView;
    
    IIViewDeckController* deckController =  [[IIViewDeckController alloc] initWithCenterViewController:self.centerView 
                                                                                    leftViewController:self.leftView
                                                                                    rightViewController:self.rightView];
    
    // Keep the app running in background indefinitely.
    NSError *error;
    NSURL *defaultTrack = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Default" ofType:@"mp3"]];
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:defaultTrack error:&error];
    audioPlayer.delegate = self;
    audioPlayer.volume = 0;
    audioPlayer.numberOfLoops = 6;
    
    [audioPlayer play];
    
    // Override point for customization after application launch.
    self.window.rootViewController = deckController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    /*
     Sent whenever we receive a notification whilte the application is currently open.
     */
    
    self.centerView.badgeCount = 0;
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state;
     here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     If the application was previously in the background, optionally refresh the user interface.
     */
    
    self.centerView.badgeCount = 0;
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}


@end
