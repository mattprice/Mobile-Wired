//
//  BookmarkViewController.h
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
#import "IIViewDeckController.h"
#import "PrettyNavigationBar+Defaults.h"
#import "ServerListViewController.h"

@interface BookmarkViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate, IIViewDeckControllerDelegate, UITableViewDataSource> {
    IBOutlet PrettyNavigationBar *navigationBar;
    IBOutlet UITableView *mainTableView;
    
    ServerListViewController *serverList;

    UITextField *serverNameField;
    NSString *oldServerName;
    UITextField *serverHostField;
    NSString *oldServerHost;
    UITextField *serverPortField;
    NSString *oldServerPort;
        
    UITextField *userLoginField;
    NSString *oldUserLogin;
    UITextField *userPassField;
    NSString *oldUserPass;
    
    UITextField *userNickField;
    NSString *oldUserNick;
    UITextField *userStatusField;
    NSString *oldUserStatus;
    UISwitch *pushSettingSwitch;
    Boolean oldPushSetting;
}

@property (strong, nonatomic) IBOutlet UITableView *mainTableView;

@property (strong, nonatomic) ServerListViewController *serverList;

@end
