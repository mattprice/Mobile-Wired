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
#import "ChatViewController.h"
#import "MWSettingsViewController.h"
#import "UserListViewController.h"

#import "BlockAlertView.h"

NS_ENUM(NSInteger, MWDrawerTableSections) {
    kBookmarksSection = 0,
    kSettingsSection,
    kNumberOfSections
};

@implementation MWBookmarksViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Start out by opening the left view.
    // TODO: Use a global #define to set this.
//    self.viewDeckController.leftSize = -5.0 * 2.0;
//    [self.viewDeckController openLeftViewAnimated:NO];
//    self.viewDeckController.panningMode = IIViewDeckNoPanning;

    // Resize the server list to fill the whole screen.
//    CGRect frame = self tableView].frame;
//    frame.size.width = self.view.frame.size.width;
//    self tableView].frame = frame;

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
            return [serverBookmarks count];
            break;

        case kSettingsSection:
            return 1;
            break;

        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MWBookmarkCell"];

    switch ([indexPath section]) {
        case kBookmarksSection:
        {
            // Everything else is a bookmark.
            NSDictionary *bookmark = serverBookmarks[[indexPath row]];

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
            break;

        case kSettingsSection:
            return NO;
            break;

        default:
            return NO;
            break;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath section]) {
        case kBookmarksSection:
            return UITableViewCellEditingStyleDelete;
            break;

        case kSettingsSection:
            return UITableViewCellEditingStyleNone;
            break;

        default:
            return UITableViewCellEditingStyleNone;
            break;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the bookmark and update the table.
        [MWDataStore removeBookmarkAtIndex:[indexPath row]];
        serverBookmarks = [MWDataStore bookmarks];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

        [TestFlight passCheckpoint:@"Deleted Bookmark"];
    }
}

#pragma mark - TableView Actions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Boolean shouldPan = true;

    // Set the selectedIndex so that we know what row to save changes to.
    NSUInteger selectedIndex = [indexPath row];
    NSString *indexString = [NSString stringWithFormat:@"%lu",(unsigned long)selectedIndex];

    if ([indexPath section] == kBookmarksSection) {
        // Check on the connection status.
        Boolean isConnected = false;
        if (currentConnections[indexString]) {
            ChatViewController *object = currentConnections[indexString];
            isConnected = object.isConnected;
        }

        // If we're editing, we need to display the Bookmark view.
        if (self.tableView.editing && !isConnected) {
            [self performSegueWithIdentifier:kMWBookmarkSettingsSegue sender:self];
        }

        // If we're not editing, we need to open up the bookmark in the ChatView.
        else {
            // Check for an existing saved controller.
            if (!isConnected) {
                // Get info about the current bookmark.
                NSMutableDictionary *currentBookmark = [serverBookmarks[selectedIndex] mutableCopy];

                // Bookmark is complete and we don't have a saved controller.
//                ChatViewController *controller = [ChatViewController new];
//                controller.userListView = [[UserListViewController alloc] initWithNibName:@"UserListView" bundle:nil];
//                [controller new:selectedIndex];
//
                // Save the controller for later and then open it.
//                currentConnections[indexString] = controller;
//                self.viewDeckController.centerController = currentConnections[indexString];
            }

            // Open the saved ChatViewController object.
            else {
//                    self.viewDeckController.centerController = currentConnections[indexString];
            }
        }
    }

    else if ([indexPath section] == kSettingsSection) {
        [self performSegueWithIdentifier:kMWSettingsSegue sender:self];
    }

    // Re-enable panning and open the center view.
    if (shouldPan) {
//        self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
//        [self.viewDeckController closeLeftViewAnimated:YES completion:^(IIViewDeckController *controller, BOOL completed) {
//            // If this is the first item we've opened after launch then we need to resize
//            // the server list window and change the left ledge size.
//            // TODO: Use a global #define to set this.
//            CGRect frame = self tableView].frame;
//            frame.size.width = [[UIScreen mainScreen] bounds].size.width - 44.0;
//            self tableView].frame = frame;
//            self.viewDeckController.leftSize = 44.0;
//        }];
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
        MWBookmarkSettingsController *bookmarkSettings = [[destination viewControllers] objectAtIndex:0];

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
