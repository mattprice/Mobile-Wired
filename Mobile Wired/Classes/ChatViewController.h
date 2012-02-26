//
//  ChatViewController.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WiredConnection.h"
#import "UserListViewController.h"


@interface ChatViewController : UIViewController <WiredConnectionDelegate,UIGestureRecognizerDelegate> {
    WiredConnection *connection;
    IBOutlet UserListViewController *userListView;
    
    IBOutlet UINavigationItem *serverTitle;
    IBOutlet UITextView *serverTopic;
    
    IBOutlet UITextView *chatTextView;
    IBOutlet UIView *accessoryView;
    IBOutlet UITextField* textField;
    
    UIView* keyboard;
    UIPanGestureRecognizer *panRecognizer;
    int originalKeyboardY;
    int lastLocation;
}

@property (strong, nonatomic) WiredConnection *connection;
@property (strong, nonatomic) IBOutlet UserListViewController *userListView;

@end
