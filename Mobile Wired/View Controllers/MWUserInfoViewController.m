//
//  MWUserInfoViewController.m
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

#import "MWUserInfoViewController.h"

#import "UIImage+Scale.h"
#import "UIImage+Radius.h"

typedef NS_ENUM(NSInteger, MWUserInfoTableSections) {
    MWGeneralSection = 0,
    MWDetailSection,
    MWNumberOfSections
};

@implementation MWUserInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IBActions

- (IBAction)doneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return only 1 section whlie we're waiting on user data.
    if (![self.userInfo count]) {
        return 1;
    } else {
        return MWNumberOfSections;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return 0 while we're waiting on user data.
    if (![self.userInfo count]) {
        return 0;
    }

    switch (section) {
        case MWGeneralSection:
            return 1;

        case MWDetailSection:
            return 6;

        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (![self.userInfo count]) {
        return @"Loading details...";
    }

    switch (section) {
        case MWGeneralSection:
            return @"General";

        case MWDetailSection:
            return @"Details";

        default:
            return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;

    switch ([indexPath section]) {
        case MWGeneralSection: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MWUserInfoCell"];

            cell.textLabel.text = self.userInfo[@"wired.user.nick"];
            cell.textLabel.textColor = self.userInfo[@"wired.account.color"];
            cell.detailTextLabel.text = self.userInfo[@"wired.user.status"];

            // Fade information about idle users
            if ( [self.userInfo[@"wired.user.idle"] isEqualToString:@"1"] ) {
                cell.textLabel.alpha = 0.3f;
                cell.detailTextLabel.alpha = 0.4f;
                cell.imageView.alpha = 0.5f;
            } else {
                cell.textLabel.alpha = 1.0f;
                cell.detailTextLabel.alpha = 1.0f;
                cell.imageView.alpha = 1.0f;
            }

            // Resize the user image and make it circular.
            CGFloat size = 32.0f;
            UIImage *image = [UIImage imageWithData:self.userInfo[@"wired.user.icon"]];
            image = [image scaleToSize:CGSizeMake(size, size)];
//            image = [image withCornerRadius:size/2];
            cell.imageView.image = image;

            break;
        }

        case MWDetailSection: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"MWUserInfoCell"];

            NSString *version = [NSString stringWithFormat:@"%@ %@ (%@) on %@ %@ (%@)",
                                 self.userInfo[@"wired.info.application.name"],
                                 self.userInfo[@"wired.info.application.version"],
                                 self.userInfo[@"wired.info.application.build"],
                                 self.userInfo[@"wired.info.os.name"],
                                 self.userInfo[@"wired.info.os.version"],
                                 self.userInfo[@"wired.info.arch"]];

            switch ([indexPath row]) {
                case 0:
                    cell.textLabel.text = @"Username";
                    cell.detailTextLabel.text = self.userInfo[@"wired.user.login"];
                    break;

                case 1:
                    cell.textLabel.text = @"IP Address";
                    cell.detailTextLabel.text = self.userInfo[@"wired.user.ip"];
                    break;

                case 2:
                    cell.textLabel.text = @"Hostname";
                    cell.detailTextLabel.text = self.userInfo[@"wired.user.host"];
                    break;

                case 3:
                    cell.textLabel.text = @"Client Version";
                    cell.detailTextLabel.text = version;
                    break;

                case 4:
                    cell.textLabel.text = @"Login Time";
                    cell.detailTextLabel.text = [self.userInfo[@"wired.user.login_time"] description];
                    break;

                case 5:
                    cell.textLabel.text = @"Idle Time";
                    cell.detailTextLabel.text = [self.userInfo[@"wired.user.idle_time"] description];
                    break;

                default:
                    cell.textLabel.text = @"Label";
                    cell.detailTextLabel.text = @"Detail Text";
                    break;
            }

            break;
        }
    }

    return cell;
}

@end
