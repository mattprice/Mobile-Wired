//
//  MWBookmarksViewController.m
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

#import "MWBookmarksViewController.h"
#import "MWBookmarkSettingsController.h"
#import "MWChatViewController.h"
#import "MWSettingsViewController.h"
#import "UserListViewController.h"

#import "BlockAlertView.h"

typedef NS_ENUM(NSInteger, MWDrawerTableSections) {
    kBookmarksSection = 0,
    kSettingsSection,
    kNumberOfSections
};

@implementation MWBookmarksViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create an array to eventually store connections in.
    currentConnections = [NSMutableDictionary dictionary];
    serverBookmarks = [MWDataStore bookmarks];

    [[self navigationItem] setLeftBarButtonItem:[self editButtonItem]];
}

#pragma mark - TableView Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kBookmarksSection:
            return (NSInteger)[serverBookmarks count];

        case kSettingsSection:
            return 1;

        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MWBookmarkCell"];

    switch ([indexPath section]) {
        case kBookmarksSection:
        {
            // Everything else is a bookmark.
            NSDictionary *bookmark = serverBookmarks[(NSUInteger)[indexPath row]];

            // If there's no Server Name, try using the Server Host.
            if ([bookmark[kMWServerName] isEqualToString:@""]) {
                cell.textLabel.text = bookmark[kMWServerHost];
            } else {
                cell.textLabel.text = bookmark[kMWServerName];
            }

            // Set the status image.
//            NSString *indexString = [NSString stringWithFormat:@"%d", [indexPath row]];
//            if (currentConnections[indexString]) {
//                cell.imageView.image = [UIImage imageNamed:@"GreenDot.png"];
//            } else {
//                cell.imageView.image = [UIImage imageNamed:@"GrayDot.png"];
//            }
        }
            break;

        case kSettingsSection:
            cell.textLabel.text = @"Settings";
            break;

        default:
            break;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kBookmarksSection && [serverBookmarks count] == 0) {
        return @"Welcome!";
    }

    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == kBookmarksSection && [serverBookmarks count] == 0) {
        return @"You currently don't have any bookmarks. To add some, use the + button above.";
    }

    return @"";
}

#pragma mark - TableView Styles

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Return NO for bookmarks that are connected?
    switch ([indexPath section]) {
        case kBookmarksSection:
            return YES;

        case kSettingsSection:
            return NO;

        default:
            return NO;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath section]) {
        case kBookmarksSection:
            return UITableViewCellEditingStyleDelete;

        case kSettingsSection:
            return UITableViewCellEditingStyleNone;

        default:
            return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the bookmark and update the table.
        [MWDataStore removeBookmarkAtIndex:(NSUInteger)[indexPath row]];
        serverBookmarks = [MWDataStore bookmarks];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

        [TestFlight passCheckpoint:@"Deleted Bookmark"];
    }
}

#pragma mark - TableView Actions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the selectedIndex so that we know what row to save changes to.
    NSUInteger selectedIndex = (NSUInteger)[indexPath row];
    NSString *indexString = [NSString stringWithFormat:@"%lu",(unsigned long)selectedIndex];

    if ([indexPath section] == kBookmarksSection) {
        // Check on the connection status.
        Boolean isConnected = false;
        if (currentConnections[indexString]) {
            UINavigationController *controller = currentConnections[indexString];
            MWChatViewController *object = controller.viewControllers[0];
            isConnected = object.isConnected;
        }

        // If we're editing, we need to display the Bookmark Settings view.
        if (self.tableView.editing && !isConnected) {
            [self performSegueWithIdentifier:kMWBookmarkSettingsSegue sender:self];
            return;
        }

        // If we're not editing, we need to open up the bookmark in the Chat view.
        if (!isConnected) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kMWCenterDrawer bundle:nil];
            UINavigationController *controller = [storyboard instantiateViewControllerWithIdentifier:kMWChatViewController];

            MWChatViewController *chatView = controller.viewControllers[0];
            [chatView loadBookmark:selectedIndex];
//            chatView.userListView = [[UserListViewController alloc] initWithNibName:@"UserListView" bundle:nil];

            currentConnections[indexString] = controller;
        }

        MMDrawerController *drawerController = [self mm_drawerController];
        drawerController.centerViewController = currentConnections[indexString];
        drawerController.showsShadow = YES;
        [drawerController closeDrawerAnimated:YES completion:^void(BOOL finished) {
            // We need to change some settings if this is the first centerViewController
            // we've opened since the app launched.
            drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureModeAll;
            drawerController.maximumLeftDrawerWidth = kMWLedgeSize;
        }];
        
        return;
    }

    else if ([indexPath section] == kSettingsSection) {
        [self performSegueWithIdentifier:kMWSettingsSegue sender:self];
        return;
    }
}

- (IBAction)saveButtonPressed:(UIStoryboardSegue *)seque
{
    serverBookmarks = [MWDataStore bookmarks];
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *destination = segue.destinationViewController;

    if ([[segue identifier] isEqualToString:kMWBookmarkSettingsSegue]) {
        MWBookmarkSettingsController *bookmarkSettings = [destination viewControllers][0];

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath == nil) {
            // New Bookmark
            bookmarkSettings.bookmarkIndex = -1;
        } else {
            // Existing Bookmark
            bookmarkSettings.bookmarkIndex = [indexPath row];
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

@end
