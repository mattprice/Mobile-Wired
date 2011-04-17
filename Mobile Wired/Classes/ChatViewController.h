//
//  ChatViewController.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WiredConnection.h"


@interface ChatViewController : UIViewController {

    IBOutlet UINavigationItem *serverTitle;
}

@property (nonatomic, retain) WiredConnection *connection;

@end
