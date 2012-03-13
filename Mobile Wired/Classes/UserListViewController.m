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
#import "UserListTableViewCell.h"


@interface UserListViewController ()

@end

@implementation UserListViewController

@synthesize userListArray;

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
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setUserList:(NSDictionary *)userList
{
    // User lists are organized into channels; save only channel 1.
    self.userListArray = [[[userList objectForKey:@"1"] allValues] mutableCopy];
    
    // Sort the user list by user ID, which increments each time someone connects.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"wired.user.id" ascending:YES];
    [self.userListArray sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [self.tableView reloadData];
    
    // Reload the TableView
    [self.tableView reloadData];
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
    
    UserListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UserListTableViewCell" owner:nil options:nil];
        
        for(id currentObject in topLevelObjects) {
            if([currentObject isKindOfClass:[UserListTableViewCell class]]) {
                cell = (UserListTableViewCell *)currentObject;
                break;
            }
        }
    }
    
    // Get info about the current row's user
    NSDictionary *currentUser = [userListArray objectAtIndex:[indexPath row]];
    
    // Center the nickname if there's no status.
    if ( [[currentUser objectForKey:@"wired.user.status"] isEqualToString:@""] ) {
        cell.nickLabel.text = @"";
        cell.statusLabel.text = @"";
        
        cell.onlyNickLabel.text = [currentUser objectForKey:@"wired.user.nick"];
        cell.onlyNickLabel.textColor = [currentUser objectForKey:@"wired.account.color"];
    } else {
        cell.onlyNickLabel.text = @"";
        
        cell.nickLabel.text = [currentUser objectForKey:@"wired.user.nick"];
        cell.nickLabel.textColor = [currentUser objectForKey:@"wired.account.color"];
        cell.statusLabel.text = [currentUser objectForKey:@"wired.user.status"];
    }
    
    // Fade information about idle users
    if ( [[currentUser objectForKey:@"wired.user.idle"] isEqualToString:@"1"] ) {
        cell.nickLabel.alpha = 0.3;
        cell.onlyNickLabel.alpha = 0.3;
        cell.statusLabel.alpha = 0.4;
        cell.avatar.alpha = 0.5;
    } else {
        cell.nickLabel.alpha = 1;
        cell.onlyNickLabel.alpha = 1;
        cell.statusLabel.alpha = 1;
        cell.avatar.alpha = 1;
    }
    
    cell.avatar.image = [UIImage imageWithData:[currentUser objectForKey:@"wired.user.icon"]];
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSDictionary *currentUser = [userListArray objectAtIndex:[indexPath row]];
//    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
//                                                    message:[NSString stringWithFormat:@"You selected %@!",[currentUser objectForKey:@"wired.user.nick"]]
//                                                   delegate:nil
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
//    
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//}

@end