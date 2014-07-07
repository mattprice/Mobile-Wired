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

#import "UIImage+Scale.h"
#import "UITableView+Subviews.h"

@interface MWSettingsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField;
@property (weak, nonatomic) IBOutlet UITextField *statusTextField;
@property (weak, nonatomic) IBOutlet UIImageView *userIconView;

@end

@implementation MWSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.nicknameTextField.text = [MWDataStore optionForKey:kMWUserNick];
    self.statusTextField.text = [MWDataStore optionForKey:kMWUserStatus];
    self.userIconView.image = [MWDataStore optionForKey:kMWUserIcon];

    [TestFlight passCheckpoint:@"Viewed Settings"];
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

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    [MWDataStore setOption:self.nicknameTextField.text forKey:kMWUserNick];
    [MWDataStore setOption:self.statusTextField.text forKey:kMWUserStatus];
    [MWDataStore setOption:self.userIconView.image forKey:kMWUserIcon];
    [MWDataStore save];

    [TestFlight passCheckpoint:@"Modified Settings"];

    return YES;
}

#pragma mark - TextField Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSIndexPath *indexPath = [[self tableView] indexPathForCellContainingView:textField];
    if (indexPath) {
        [[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.nicknameTextField) {
        [self.statusTextField becomeFirstResponder];
    } else if (textField == self.statusTextField) {
        [self.statusTextField resignFirstResponder];
    }

    return YES;
}

@end
