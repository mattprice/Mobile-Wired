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
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // Add the TestFlight SDK.
#ifndef DEBUG
    #ifdef TF_APP_TOKEN
        [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueItdentifier]];
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
    deckController.delegate = self;
    futureController.delegateMode = IIViewDeckDelegateAndSubControllers;
    futureController.delegate = self;
    
    // Enable the parallax scrolling effect.
    deckController.parallaxAmount = 0.3;
    futureController.parallaxAmount = 0.3;
    
    // Override point for customization after application launch.
    self.window.rootViewController = deckController;
    
#if !TARGET_IPHONE_SIMULATOR
    // Register for remote notifications, but only if we're not in the Simulator.
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
#endif
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)viewDeckController:(IIViewDeckController *)viewDeckController applyShadow:(CALayer *)shadowLayer withBounds:(CGRect)rect
{
    shadowLayer.masksToBounds = NO;
    shadowLayer.shadowRadius = 5;
    shadowLayer.shadowOpacity = 0.35;
    shadowLayer.shadowOffset = CGSizeZero;
    shadowLayer.shadowPath = [[UIBezierPath bezierPathWithRect:rect] CGPath];
}

#pragma mark -
#pragma mark Push Notifications
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    NSString *hexToken = [[[[devToken description] stringByReplacingOccurrencesOfString:@"<" withString:@""]
                                   stringByReplacingOccurrencesOfString:@">" withString:@""]
                                  stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"Device token: %@", hexToken);
    
//    self.registered = YES;
//    [self sendProviderDeviceToken:hexToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    NSLog(@"Error registering remote notifications. Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    /*
     Sent whenever we receive a remote notification.
     */
    
    NSLog(@"*** Received a push notification: %@", [userInfo description]);
}

#pragma mark -
#pragma mark Backgrounding Notifications
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
