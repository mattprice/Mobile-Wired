//
//  MWChatViewController.h
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

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "WiredConnection.h"

typedef NS_ENUM(NSInteger, MWChatMessageTypes) {
    MWChatMessage = 0,
    MWEmoteMessage,
    MWStatusMessage
};

@class UserListViewController;

@interface ChatMessage : NSObject;
@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) NSString *time;
@property (nonatomic) NSInteger type;

@end

@interface MWChatViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate, WiredConnectionDelegate, UIGestureRecognizerDelegate> {
    NSDictionary *bookmark;
    MBProgressHUD *progressHUD;
    NSString *serverTopic;
    
    NSMutableArray *chatMessages;}

@property (strong, nonatomic) WiredConnection *connection;
@property (strong, nonatomic) UserListViewController *userListView;

- (void)loadBookmark:(NSUInteger)indexRow;
- (Boolean)isConnected;
- (IBAction)sendButtonPressed:(id)sender;
- (void)getInfoForUser:(NSString *)userID;

@end
