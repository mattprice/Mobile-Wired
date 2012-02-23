//
//  ChatViewController.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WiredConnection.h"


@interface ChatViewController : UIViewController <WiredConnectionDelegate>;

@property (strong, nonatomic) WiredConnection *connection;
@property (strong, nonatomic) IBOutlet UINavigationItem *serverTitle;
@property (strong, nonatomic) IBOutlet UITextView *serverTopic;

@end
