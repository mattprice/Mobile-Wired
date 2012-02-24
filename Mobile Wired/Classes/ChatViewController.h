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


@interface ChatViewController : UIViewController <WiredConnectionDelegate> {
    WiredConnection *connection;
    IBOutlet UINavigationItem *serverTitle;
    IBOutlet UITextView *serverTopic;
    IBOutlet UserListViewController *userListView;
}

@property (strong, nonatomic) WiredConnection *connection;
@property (strong, nonatomic) IBOutlet UserListViewController *userListView;


@property (strong, nonatomic) IBOutlet UINavigationItem *serverTitle;
@property (strong, nonatomic) IBOutlet UITextView *serverTopic;

@end
