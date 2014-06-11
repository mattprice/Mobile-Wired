//
//  MWAppDelegate.m
//  Mobile Wired
//
//  Copyright (c) 2014 Matthew Price, http://mattprice.me/
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

#import "MWAppDelegate.h"

#import "MMDrawerController.h"
#import "ChatViewController.h"
#import "UserListViewController.h"
#import "MWBookmarksViewController.h"
#import "TestFlightTokens.h"

@implementation MWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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

        NSString *defaultStatus = [NSString stringWithFormat:@"On my %@", [[UIDevice currentDevice] model]];

        [[NSUserDefaults standardUserDefaults] setObject:@"Mobile Wired User" forKey:@"UserNick"];
        [[NSUserDefaults standardUserDefaults] setObject:defaultStatus forKey:@"UserStatus"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedBefore"];
        [[NSUserDefaults standardUserDefaults] setObject:@[] forKey:@"Bookmarks"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
#if !TARGET_IPHONE_SIMULATOR
    // Register for remote notifications, but only if we're not in the Simulator.
    // TODO: Register for notifications after they create their first bookmark.
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
#endif
    
    return YES;
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
