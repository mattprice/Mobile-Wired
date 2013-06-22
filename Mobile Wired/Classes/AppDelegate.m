//
//  AppDelegate.m
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

#import "AppDelegate.h"

#import "IIViewDeckController.h"
#import "ChatViewController.h"
#import "UserListViewController.h"
#import "ServerListViewController.h"
#import "TestFlightTokens.h"

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Set the status bar style
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    
    // Add the TestFlight SDK.
#ifndef DEBUG
    #ifdef TF_APP_TOKEN
        [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
        [TestFlight takeOff:TF_APP_TOKEN];
    #endif
#endif
    
    // Set up user defaults if they haven't run the app before.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedBefore"])
    {
        NSLog(@"Setting up user defaults for the first time.");
        
        [[NSUserDefaults standardUserDefaults] setObject:@"Melman" forKey:@"UserNick"];
        
        NSString *defaultStatus = [NSString stringWithFormat:@"On my %@", [[UIDevice currentDevice] model]];
        [[NSUserDefaults standardUserDefaults] setObject:defaultStatus forKey:@"UserStatus"];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedBefore"];
        
        [[NSUserDefaults standardUserDefaults] setObject:@[] forKey:@"Bookmarks"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // Setup all the possible views.
    serverListView = [[ServerListViewController alloc] initWithNibName:@"ServerListView" bundle:nil];
    
    IIViewDeckController *futureController = [[IIViewDeckController alloc] initWithCenterViewController:nil
                                                                                    rightViewController:nil];
    
    IIViewDeckController *deckController =  [[IIViewDeckController alloc] initWithCenterViewController:nil
                                                                                    leftViewController:serverListView
                                                                                   rightViewController:futureController];
    
    deckController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractive;
    
    // Let each ViewDeck subcontroller receive delegate calls.
    deckController.delegateMode = IIViewDeckDelegateAndSubControllers;
    futureController.delegateMode = IIViewDeckDelegateAndSubControllers;
    
    // Override point for customization after application launch.
    self.window.rootViewController = deckController;
    
    // Fade out the splash screen image.
    // The image is shifted 20 pixels down from where it should be, so correct its position.
    // TODO: If this 20px is related to the status bar then we should calculate its height programmatically.
    UIImageView *splashImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
    CGRect frame = CGRectMake(splashImage.frame.origin.x,
                               splashImage.frame.origin.y - 20,
                               splashImage.frame.size.width,
                               splashImage.frame.size.height);
    [splashImage setFrame:frame];
    [self.window.rootViewController.view addSubview:splashImage];
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         splashImage.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [splashImage removeFromSuperview];
                     }];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    /*
     Sent whenever we receive a notification while the application is currently open.
     */
    
    chatView.badgeCount = 0;
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
    
    chatView.badgeCount = 0;
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
