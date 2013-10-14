//
//  ServerListViewController.m
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

#import "ServerListViewController.h"
#import "BookmarkViewController.h"
#import "ChatViewController.h"
#import "IIViewDeckController.h"
#import "SettingsViewController.h"
#import "UserListViewController.h"

#import "BlockAlertView.h"

@implementation ServerListViewController

@synthesize mainTableView = _mainTableView;
@synthesize serverBookmarks, selectedIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Start out by opening the left view.
    // TODO: Use a global #define to set this.
    self.viewDeckController.leftSize = -5.0 * 2.0;
    [self.viewDeckController openLeftViewAnimated:NO];
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
    
    // Resize the server list to fill the whole screen.
    CGRect frame = self.mainTableView.frame;
    frame.size.width = self.view.frame.size.width;
    self.mainTableView.frame = frame;
    
    // Create an array to eventually store connections in.
    currentConnections = [NSMutableDictionary dictionary];
    
    // Create the navigation bar.
    navigationBar.items = @[[[UINavigationItem alloc] init]];
    navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(editButtonWasPressed)];
}

#pragma mark -
#pragma mark TableView Actions

- (void)editButtonWasPressed
{
    if (self.mainTableView.editing) {
        // Disable editing.
        [self.mainTableView setEditing:NO animated:YES];
        
        // Change the Done button back to an Edit button.
        navigationBar.topItem.leftBarButtonItem.title = @"Edit";
        navigationBar.topItem.leftBarButtonItem.style = UIBarButtonItemStylePlain;
        
        // Remove the "Add Bookmark" button. It only exists if there are other bookmarks.
        if ([serverBookmarks count] > 0) {
            NSArray *paths = @[[NSIndexPath indexPathForRow:[serverBookmarks count] inSection:0]];
            [self.mainTableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
        }
    }
    
    else {
        // Enable editing.
        [self.mainTableView setEditing:YES animated:YES];
        
        // Change the Edit button to a Done button.
        navigationBar.topItem.leftBarButtonItem.title = @"Done";
        navigationBar.topItem.leftBarButtonItem.style = UIBarButtonItemStyleDone;
        
        // Insert the "Add Bookmark" button, but only if other bookmarks exist.
        if ([serverBookmarks count] > 0) {
            NSArray *paths = @[[NSIndexPath indexPathForRow:[serverBookmarks count] inSection:0]];
            [self.mainTableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
        }
    }
}

#pragma mark -
#pragma mark TableView Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Section 0 is for server bookmarks.
    if (section == 0) {
        // If we don't have any bookmarks display an "Add Bookmark" button.
        serverBookmarks = [[NSUserDefaults standardUserDefaults] objectForKey:@"Bookmarks"];
        if ([serverBookmarks count] == 0) {
            return 1;
        }
        
        // If we're editing, include an extra space for an "Add Bookmark" button.
        else if (self.mainTableView.editing) {
            return [serverBookmarks count]+1;
        }
        
        return [serverBookmarks count];
    }
    
    // Section 1 is settings.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // Section 0 is for server bookmarks.
    if ([indexPath section] == 0) {
        // If we don't have any bookmarks display an "Add Bookmark" button.
        if ([serverBookmarks count] == 0) {
            cell.textLabel.text = @"Add Bookmark";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        // Else, if we're editing, then bookmark count is the "Add Bookmark" item.
        // This is because indices are 0 based, but array count is not.
        else if ([indexPath row] == [serverBookmarks count]) {
            cell.textLabel.text = @"Add Bookmark";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        // Everything else is a real bookmark!
        else {
            // Get info about the current row's bookmark.
            NSDictionary *currentBookmark = serverBookmarks[[indexPath row]];
            
            // If there's no Server Name, try using the Server Host.
            if ([currentBookmark[@"ServerName"] isEqualToString:@""]) {
                cell.textLabel.text = currentBookmark[@"ServerHost"];
            } else {
                cell.textLabel.text = currentBookmark[@"ServerName"];
            }
            
            // Set the status image.
//            NSString *indexString = [NSString stringWithFormat:@"%d", [indexPath row]];
//            if (currentConnections[indexString]) {
//                cell.imageView.image = [UIImage imageNamed:@"GreenDot.png"];
//            } else {
//                cell.imageView.image = [UIImage imageNamed:@"GrayDot.png"];
//            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    
    // Section 1 is settings.
    else if ([indexPath section] == 1) {
        cell.textLabel.text = @"Settings";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Section 0 is for server bookmarks.
    if ([indexPath section] == 0) {
        return YES;
    }
    
    // Section 1 is the settings.
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Section 0 is for server bookmarks
    if ([indexPath section] == 0) {
        // If we don't have any bookmarks, the only thing is an "Add Bookmark" button.
        if ([serverBookmarks count] == 0) {
            return UITableViewCellEditingStyleInsert;
        }
        
        // Else, if we're editing, then bookmark count is the "Add Bookmark" item.
        // This is because indices are 0 based, but an array count is not.
        else if ([indexPath row] == [serverBookmarks count]) {
            return UITableViewCellEditingStyleInsert;
        }
        
        // Everything else is a real bookmark!
        return UITableViewCellEditingStyleDelete;
    }

    // Section 1 is settings.
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Boolean shouldPan = true;
    
    // Set the selectedIndex so that we know what row to save changes to.
    selectedIndex = [indexPath row];
    NSString *indexString = [NSString stringWithFormat:@"%d",selectedIndex];

    // Section 0 is for server bookmarks.
    if ([indexPath section] == 0) {
        // If we don't have any bookmarks, the only thing is an "Add Bookmark" button.
        if ([serverBookmarks count] == 0) {
            self.viewDeckController.centerController = [[BookmarkViewController alloc] initWithNibName:@"BookmarkView" bundle:nil];
            BookmarkViewController *bookmarkView = (BookmarkViewController *)self.viewDeckController.centerController;
            bookmarkView.serverList = self;
        }
        
        // Else, if we're editing, then bookmark count is the "Add Bookmark" item.
        // This is because indices are 0 based, but an array count is not.
        else if (selectedIndex == [serverBookmarks count]) {
            self.viewDeckController.centerController = [[BookmarkViewController alloc] initWithNibName:@"BookmarkView" bundle:nil];
            BookmarkViewController *bookmarkView = (BookmarkViewController *)self.viewDeckController.centerController;
            bookmarkView.serverList = self;
        }
        
        // Else, this is actually a bookmark!
        else {
            // Check on the connection status.
            Boolean isConnected = false;
            if (currentConnections[indexString]) {
                ChatViewController *object = currentConnections[indexString];
                isConnected = object.isConnected;
            }
                        
            // If we're editing, we need to display the Bookmark view.
            if (self.mainTableView.editing) {
                // Make sure that were aren't currently connected.
                if (!isConnected) {
                    self.viewDeckController.centerController = [[BookmarkViewController alloc] initWithNibName:@"BookmarkView" bundle:nil];
                    BookmarkViewController *bookmarkView = (BookmarkViewController *)self.viewDeckController.centerController;
                    bookmarkView.serverList = self;
                } else {
                    shouldPan = false;
                    
                    BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Server Currently Connected"
                                                                   message:@"Please disconnect from this server before attempting to edit it."];
                    
                    [alert setCancelButtonWithTitle:@"OK" block:nil];
                    [alert show];
                }
            }
            
            // If we're not editing, we need to open up the bookmark in the ChatView.
            else {
                // Check for an existing saved controller.
                if (!isConnected) {
                    // Get info about the current bookmark.
                    NSMutableDictionary *currentBookmark = [serverBookmarks[selectedIndex] mutableCopy];
                    
                    // Check to make sure the bookmark is complete.
                    if (![currentBookmark[@"ServerHost"] isEqualToString:@""]) {
                        // Bookmark is complete and we don't have a saved controller.
                        ChatViewController *controller = [ChatViewController new];
                        controller.userListView = [[UserListViewController alloc] initWithNibName:@"UserListView" bundle:nil];
                        [controller new:selectedIndex];

                        // Save the controller for later and then open it.
                        currentConnections[indexString] = controller;
                        self.viewDeckController.centerController = currentConnections[indexString];
                    }
                    
                    // Display an alert if there's no server address.
                    else {
                        shouldPan = false;
                        
                        BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Missing Server Host"
                                                                       message:@"You need to enter a host for this server before connecting."];
                        
                        [alert setCancelButtonWithTitle:@"OK" block:nil];
                        [alert show];
                    }
                }
                
                // Open the saved ChatViewController object.
                else {
                    self.viewDeckController.centerController = currentConnections[indexString];
                }
            }
        }
    }
    
    // Section 1 is settings.
    else if ([indexPath section] == 1) {
        self.viewDeckController.centerController = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
    }
    
    // Clear selection after pressing.
    [self.mainTableView deselectRowAtIndexPath:indexPath animated:NO];
    
    // Re-enable panning and open the center view.
    if (shouldPan) {
        self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
        [self.viewDeckController closeLeftViewAnimated:YES completion:^(IIViewDeckController *controller, BOOL completed) {
            // If this is the first item we've opened after launch then we need to resize
            // the server list window and change the left ledge size.
            // TODO: Use a global #define to set this.
            CGRect frame = self.mainTableView.frame;
            frame.size.width = frame.size.width - 44.0;
            self.mainTableView.frame = frame;
            self.viewDeckController.leftSize = 44.0;
        }];
    }
}

 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         // Delete the row from the data source
         NSMutableArray *savedBookmarks = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Bookmarks"] mutableCopy];
         [savedBookmarks removeObjectAtIndex:[indexPath row]];
         [[NSUserDefaults standardUserDefaults] setObject:savedBookmarks forKey:@"Bookmarks"];
         [[NSUserDefaults standardUserDefaults] synchronize];
         
         [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
         
         [TestFlight passCheckpoint:@"Deleted Bookmark"];
     }
     
     else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Add a row to the data source.
        [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
         
        [TestFlight passCheckpoint:@"Added Bookmark"];
     }
 }

@end
