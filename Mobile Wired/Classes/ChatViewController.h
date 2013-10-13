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
#import "WiredConnection.h"

@class UserListViewController;

@interface ChatMessage : NSObject;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *message;

@end

@interface ChatViewController : UIViewController <MBProgressHUDDelegate, WiredConnectionDelegate, UIGestureRecognizerDelegate> {
    NSDictionary *bookmark;
    MBProgressHUD *progressHUD;
    NSString *serverTopic;
    
    IBOutlet UINavigationBar *navigationBar;
    IBOutlet UIToolbar *toolBar;
    
    NSMutableArray *chatMessages;
    IBOutlet UITableView *chatTableView;
    IBOutlet UITextField *chatTextField;
    IBOutlet UIView *accessoryView;
}

@property (strong, nonatomic) WiredConnection *connection;
@property (strong, nonatomic) UserListViewController *userListView;

- (void)new:(NSInteger)indexRow;
- (Boolean)isConnected;
- (IBAction)sendButtonPressed:(id)sender;
- (void)getInfoForUser:(NSString *)userID;

@end
