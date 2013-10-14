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
#import "ChatViewController.h"
#import "IIViewDeckController.h"

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
    [self.mainTableView reloadData];
    
    [TestFlight passCheckpoint:@"Viewed User List"];
}

#pragma mark -
#pragma mark ViewDeck Delegate Methods
- (IIViewDeckController *)topViewDeckController
{
    return self.viewDeckController.viewDeckController;
}

- (void)viewDeckController:(IIViewDeckController*)viewDeckController willOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated
{
    if ( viewDeckSide == IIViewDeckRightSide ) {
        // TODO: Use a global #define to set this.
        self.topViewDeckController.rightSize = 22;
    }
}

- (void)viewDeckController:(IIViewDeckController*)viewDeckController willCloseViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated
{
    if ( viewDeckSide == IIViewDeckRightSide ) {
        // TODO: Use a global #define to set this.
        self.topViewDeckController.rightSize = 44;
    }
    
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
    return [self.userListArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Get info about the current row's user
    NSDictionary *currentUser = self.userListArray[[indexPath row]];
    
    cell.textLabel.text = currentUser[@"wired.user.nick"];
    cell.textLabel.textColor = currentUser[@"wired.account.color"];
    cell.detailTextLabel.text = currentUser[@"wired.user.status"];
    
    // Fade information about idle users
    if ( [currentUser[@"wired.user.idle"] isEqualToString:@"1"] ) {
        cell.textLabel.alpha = 0.3;
        cell.detailTextLabel.alpha = 0.4;
        cell.imageView.alpha = 0.5;
    } else {
        cell.textLabel.alpha = 1;
        cell.detailTextLabel.alpha = 1;
        cell.imageView.alpha = 1;
    }
    
    cell.imageView.image = [UIImage imageWithData:currentUser[@"wired.user.icon"]];
    
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
    NSDictionary *currentUser = self.userListArray[[indexPath row]];
    
    [self.connection getInfoForUser:currentUser[@"wired.user.id"]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end