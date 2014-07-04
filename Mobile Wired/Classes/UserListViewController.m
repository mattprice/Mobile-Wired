//
//  UserListViewController.m
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

#import "UserListViewController.h"

#import "MWChatViewController.h"
#import "UIImage+MWKit.h"

@implementation UserListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initializations
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.mainTableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.mainTableView reloadData];
    
    [TestFlight passCheckpoint:@"Viewed User List"];
}

#pragma mark -
#pragma mark TableView Actions

- (void)setUserList:(NSDictionary *)userList
{
    // User lists are organized into channels; save only channel 1.
    self.userListArray = [[userList[@"1"] allValues] mutableCopy];
    
    // Sort the user list by status and then by username.
    NSSortDescriptor *idleSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"wired.user.idle" ascending:YES];
    NSSortDescriptor *nickSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"wired.user.nick" ascending:YES];
    [self.userListArray sortUsingDescriptors:@[idleSortDescriptor, nickSortDescriptor]];
    
    [self.mainTableView reloadData];
}

#pragma mark -
#pragma mark TableView Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of Users in the list.
    return (NSInteger)[self.userListArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Get info about the current row's user
    NSDictionary *currentUser = self.userListArray[(NSUInteger)[indexPath row]];
    
    cell.textLabel.text = currentUser[@"wired.user.nick"];
    cell.textLabel.textColor = currentUser[@"wired.account.color"];
    cell.detailTextLabel.text = currentUser[@"wired.user.status"];
    
    // Fade information about idle users
    if ( [currentUser[@"wired.user.idle"] isEqualToString:@"1"] ) {
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
    UIImage *image = [UIImage imageWithData:currentUser[@"wired.user.icon"]];
    image = [image scaleToSize:CGSizeMake(size, size)];
//    image = [image withCornerRadius:size/2];
    cell.imageView.image = image;
    
    // Set a border around the user image.
//    UIColor *borderColor = [UIColor colorWithWhite:0.0 alpha:0.525];
//    cell.imageView.layer.borderColor = borderColor.CGColor;
//    cell.imageView.layer.borderWidth = 0.5;
    cell.imageView.layer.cornerRadius = size/2.0f;
    
    // Display a disclosure indicator if the user has permission to view user info.
    if ( [[self.connection getMyPermissions][@"wired.account.user.get_info"] boolValue] ) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // If the user doesn't have permission, don't let them select the UITableViewCells.
    else {
        cell.userInteractionEnabled = NO;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *currentUser = self.userListArray[(NSUInteger)[indexPath row]];
    
    [self.connection getInfoForUser:currentUser[@"wired.user.id"]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
