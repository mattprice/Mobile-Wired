//
//  ChatViewController.h
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

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "PrettyNavigationBar.h"
#import "WiredConnection.h"
#import "UserListViewController.h"


@interface ChatViewController : UIViewController <WiredConnectionDelegate, MBProgressHUDDelegate, UIGestureRecognizerDelegate> {
    WiredConnection *connection;
    MBProgressHUD *progressHUD;
    IBOutlet UserListViewController *userListView;
    int badgeCount;
    
    IBOutlet PrettyNavigationBar *navigationBar;
    IBOutlet UITextView *serverTopic;
    UILabel *titleLabel;
    
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
@property (nonatomic) int badgeCount;

@property (strong, nonatomic) PrettyNavigationBar *navigationBar;

- (IBAction)sendButtonPressed:(id)sender;

@end
