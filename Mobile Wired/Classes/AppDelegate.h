//
//  Mobile_WiredAppDelegate.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class ChatViewController;
@class UserListViewController;
@class ServerListViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, AVAudioPlayerDelegate> {
    IBOutlet UIWindow *window;

    IBOutlet ServerListViewController *leftView;
    IBOutlet UserListViewController *rightView;
    IBOutlet ChatViewController *centerView;
    
    AVAudioPlayer *audioPlayer;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;

@property (strong, nonatomic) IBOutlet ServerListViewController *leftView;
@property (strong, nonatomic) IBOutlet UserListViewController *rightView;
@property (strong, nonatomic) IBOutlet ChatViewController *centerView;

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end
