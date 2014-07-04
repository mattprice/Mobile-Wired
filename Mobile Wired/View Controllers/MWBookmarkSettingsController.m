//
//  MWBookmarkSettingsController.m
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

#import "MWBookmarkSettingsController.h"
#import "NSString+Hashes.h"

@interface MWBookmarkSettingsController ()

@property (nonatomic) IBOutlet UITextField *serverNameField;
@property (nonatomic) IBOutlet UITextField *serverHostField;
@property (nonatomic) IBOutlet UITextField *serverPortField;

@property (nonatomic) IBOutlet UITextField *userLoginField;
@property (nonatomic) IBOutlet UITextField *userPassField;

@property (nonatomic) IBOutlet UITextField *userNicknameField;
@property (nonatomic) IBOutlet UITextField *userStatusField;
@property (nonatomic) IBOutlet UISwitch *notificationSwitch;

@end

@implementation MWBookmarkSettingsController

static BOOL isNewBookmark;

- (void)viewDidLoad
{
    [super viewDidLoad];

    isNewBookmark = (self.bookmarkIndex == -1);

    if (isNewBookmark) {
        [self navigationItem].title = @"Add Bookmark";
    } else {
        [self navigationItem].title = @"Edit Bookmark";

        NSDictionary *bookmark = [MWDataStore bookmarkAtIndex:(NSUInteger)self.bookmarkIndex];

        _serverNameField.text   = bookmark[kMWServerName];
        _serverHostField.text   = bookmark[kMWServerHost];
        _serverPortField.text   = bookmark[kMWServerPort];
        _userLoginField.text    = bookmark[kMWUserLogin];
        _userPassField.text     = bookmark[kMWUserPass];
        _userNicknameField.text = bookmark[kMWUserNick];
        _userStatusField.text   = bookmark[kMWUserStatus];
        _notificationSwitch.on  = (BOOL)bookmark[kMWNotifications][kMWOnMention];
    }

    // Set the nickname and status placeholders to their global defaults.
    _userNicknameField.placeholder = [MWDataStore optionForKey:kMWUserNick];
    _userStatusField.placeholder = [MWDataStore optionForKey:kMWUserStatus];
}

#pragma mark - View Actions

- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    BOOL shouldReturn = YES;

    NSMutableDictionary *bookmark = [NSMutableDictionary dictionary];

    // Turn the "Host" label red if no host is given.
    if ([_serverHostField.text isEqualToString:@""]) {
        for (id obj in [_serverHostField.superview subviews]) {
            if ([obj isMemberOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)obj;
                label.textColor = [UIColor redColor];
            }
        }

        shouldReturn = NO;
    }

    // Turn the "Login" field red if there is a password but no username.
    if ([_userLoginField.text isEqualToString:@""] && ![_userPassField.text isEqualToString:@""]) {
        for (id obj in [_userLoginField.superview subviews]) {
            if ([obj isMemberOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)obj;
                label.textColor = [UIColor redColor];
            }
        }

        shouldReturn = NO;
    }

    if (!shouldReturn) {
        return NO;
    }

    bookmark[kMWServerName]    = _serverNameField.text;
    bookmark[kMWServerHost]    = _serverHostField.text;
    bookmark[kMWServerPort]    = _serverPortField.text;
    bookmark[kMWUserLogin]     = _userLoginField.text;
    bookmark[kMWUserPass]      = _userPassField.text;
    bookmark[kMWUserNick]      = _userNicknameField.text;
    bookmark[kMWUserStatus]    = _userStatusField.text;
    bookmark[kMWNotifications] = @{ kMWOnMention: @(_notificationSwitch.on) };

    if (isNewBookmark) {
        [MWDataStore addBookmark:bookmark];
    } else {
        [MWDataStore setBookmark:bookmark forIndex:(NSUInteger)self.bookmarkIndex];
    }

    return YES;
}

#pragma mark - Text Field Delegates

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // TODO: I don't like this UIColor being hardcoded.
    for (id obj in [textField.superview subviews]) {
        if ([obj isMemberOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)obj;
            label.textColor = [UIColor colorWithRed:0.0f green:0.569f blue:1.0f alpha:1.0f];
        }
    }

    // Set placeholder text for the server name field on each change.
    if (textField == _serverHostField) {
        _serverNameField.placeholder = _serverHostField.text;
    }

    // If the previous field was the password field, generate a SHA1 hash of the password.
    else if (textField == _userPassField && ![_userPassField.text isEqualToString:@""]) {
        _userPassField.text = [_userPassField.text SHA1Value];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _serverNameField) {
        [_serverHostField becomeFirstResponder];
    } else if (textField == _serverHostField) {
        [_serverPortField becomeFirstResponder];
    } else if (textField == _serverPortField) {
        [_userLoginField becomeFirstResponder];
    } else if (textField == _userLoginField) {
        [_userPassField becomeFirstResponder];
    } else if (textField == _userPassField) {
        [_userNicknameField becomeFirstResponder];
    } else if (textField == _userNicknameField) {
        [_userStatusField becomeFirstResponder];
    } else if (textField == _userStatusField) {
        [_userStatusField resignFirstResponder];
    }

    return YES;
}

@end
