//
//  ChatViewController.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "WiredConnection.h"
#import "UserListViewController.h"


@interface ChatViewController : UIViewController <WiredConnectionDelegate, MBProgressHUDDelegate, UIGestureRecognizerDelegate> {
    WiredConnection *connection;
    MBProgressHUD *progressHUD;
    IBOutlet UserListViewController *userListView;
    Boolean isReconnecting;
    int badgeCount;
    
    IBOutlet UINavigationBar *navigationBar;
    IBOutlet UITextView *serverTopic;
    
    IBOutlet UITextView *chatTextView;
    IBOutlet UITextField* chatTextField;
    IBOutlet UIView *accessoryView;
    
    UIView* keyboard;
    UIPanGestureRecognizer *panRecognizer;
    int originalKeyboardY;
    int lastLocation;
}

@property (strong, nonatomic) WiredConnection *connection;
@property (strong, nonatomic) IBOutlet UserListViewController *userListView;
@property (nonatomic) Boolean isReconnecting;
@property (nonatomic) int badgeCount;

@property (strong, nonatomic) UINavigationBar *navigationBar;

- (IBAction)sendButtonPressed:(id)sender;

@end
