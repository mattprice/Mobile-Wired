//
//  MWSettingsViewController.m
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

#import "MWSettingsViewController.h"
#import "UITableView+Subviews.h"

@interface MWSettingsViewController ()

@property (nonatomic) IBOutlet UITextField *nicknameTextField;
@property (nonatomic) IBOutlet UITextField *statusTextField;

@end

@implementation MWSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _nicknameTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserNick"];
    _statusTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserStatus"];

    [TestFlight passCheckpoint:@"Viewed Settings"];
}

#pragma mark - View Actions

- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveButtonPressed:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:_nicknameTextField.text forKey:@"UserNick"];
    [[NSUserDefaults standardUserDefaults] setObject:_statusTextField.text forKey:@"UserStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [TestFlight passCheckpoint:@"Modified Settings"];

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Text Field Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSIndexPath *indexPath = [[self tableView] indexPathForCellContainingView:textField];
    if (indexPath) {
        [[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _nicknameTextField) {
        [_statusTextField becomeFirstResponder];
    } else if (textField == _statusTextField) {
        [_statusTextField resignFirstResponder];
    }

    return YES;
}

@end