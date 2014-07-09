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

#import "MWBookmarkViewController.h"

#import "NSString+Hashes.h"
#import "UIImage+Scale.h"

@interface MWBookmarkViewController ()

// Server Info
@property (weak, nonatomic) IBOutlet UITextField *serverNameField;
@property (weak, nonatomic) IBOutlet UITextField *serverHostField;
@property (weak, nonatomic) IBOutlet UITextField *serverPortField;

// Login Info
@property (weak, nonatomic) IBOutlet UITextField *userLoginField;
@property (weak, nonatomic) IBOutlet UITextField *userPassField;

// Settings
@property (weak, nonatomic) IBOutlet UITextField *userNicknameField;
@property (weak, nonatomic) IBOutlet UITextField *userStatusField;
@property (weak, nonatomic) IBOutlet UIImageView *userIconView;
@property (weak, nonatomic) IBOutlet UISwitch *notificationSwitch;

@end

@implementation MWBookmarkViewController

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

        self.serverNameField.text   = bookmark[kMWServerName];
        self.serverHostField.text   = bookmark[kMWServerHost];
        self.serverPortField.text   = bookmark[kMWServerPort];

        self.userLoginField.text    = bookmark[kMWUserLogin];
        self.userPassField.text     = bookmark[kMWUserPass];

        self.userNicknameField.text = bookmark[kMWUserNick];
        self.userStatusField.text   = bookmark[kMWUserStatus];
        self.userIconView.image     = bookmark[kMWUserIcon];
        self.notificationSwitch.on  = (BOOL)bookmark[kMWNotifications][kMWOnMention];
    }

    // Set the nickname, status, and icon placeholders to their global defaults.
    self.userNicknameField.placeholder = [MWDataStore optionForKey:kMWUserNick];
    self.userStatusField.placeholder = [MWDataStore optionForKey:kMWUserStatus];
    if (!self.userIconView.image) {
        self.userIconView.image = [MWDataStore optionForKey:kMWUserIcon];
        self.userIconView.alpha = 0.5f;
    }
}

#pragma mark - IBActions

- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openImagePicker:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.allowsEditing = YES;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;

    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // The maximum size Wired for Mac allows is 64x64.
    UIImage *userIcon = info[UIImagePickerControllerEditedImage];
    userIcon = [userIcon scaleToSize:CGSizeMake(64.0f, 64.0f)];
    self.userIconView.image = userIcon;
    self.userIconView.alpha = 1.0f;

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    BOOL shouldReturn = YES;

    NSMutableDictionary *bookmark = [NSMutableDictionary dictionary];

    // Turn the "Host" label red if no host is given.
    if ([self.serverHostField.text isEqualToString:@""]) {
        for (id obj in [self.serverHostField.superview subviews]) {
            if ([obj isMemberOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)obj;
                label.textColor = [UIColor redColor];
            }
        }

        shouldReturn = NO;
    }

    // Turn the "Login" field red if there is a password but no username.
    if ([self.userLoginField.text isEqualToString:@""] && ![self.userPassField.text isEqualToString:@""]) {
        for (id obj in [self.userLoginField.superview subviews]) {
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

    bookmark[kMWServerName]    = self.serverNameField.text;
    bookmark[kMWServerHost]    = self.serverHostField.text;
    bookmark[kMWServerPort]    = self.serverPortField.text;

    bookmark[kMWUserLogin]     = self.userLoginField.text;
    bookmark[kMWUserPass]      = self.userPassField.text;

    bookmark[kMWUserNick]      = self.userNicknameField.text;
    bookmark[kMWUserStatus]    = self.userStatusField.text;
    if (self.userIconView.alpha == 1.0f) {
        // If the imageView isn't opaque, we were only showing the default image as a placeholder.
        bookmark[kMWUserIcon]  = self.userIconView.image;
    }
    bookmark[kMWNotifications] = @{ kMWOnMention: @(self.notificationSwitch.isOn) };

    if (isNewBookmark) {
        [MWDataStore addBookmark:bookmark];
    } else {
        [MWDataStore setBookmark:bookmark forIndex:(NSUInteger)self.bookmarkIndex];
    }

    return YES;
}

#pragma mark - UITextField Delegates

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
    if (textField == self.serverHostField) {
        self.serverNameField.placeholder = self.serverHostField.text;
    }

    // If the previous field was the password field, generate a SHA1 hash of the password.
    else if (textField == self.userPassField && ![self.userPassField.text isEqualToString:@""]) {
        self.userPassField.text = [self.userPassField.text SHA1Value];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.serverNameField) {
        [self.serverHostField becomeFirstResponder];
    } else if (textField == self.serverHostField) {
        [self.serverPortField becomeFirstResponder];
    } else if (textField == self.serverPortField) {
        [self.userLoginField becomeFirstResponder];
    } else if (textField == self.userLoginField) {
        [self.userPassField becomeFirstResponder];
    } else if (textField == self.userPassField) {
        [self.userNicknameField becomeFirstResponder];
    } else if (textField == self.userNicknameField) {
        [self.userStatusField becomeFirstResponder];
    } else if (textField == self.userStatusField) {
        [self.userStatusField resignFirstResponder];
    }

    return YES;
}

@end
