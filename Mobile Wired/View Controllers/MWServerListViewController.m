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

#import "MWServerListViewController.h"

#import "MWBookmarkViewController.h"
#import "MWChatViewController.h"
#import "MWSettingsViewController.h"
#import "MWUserListViewController.h"
#import "UIImage+Radius.h"

#import "BlockAlertView.h"

typedef NS_ENUM(NSInteger, MWServerListTableSections) {
    MWBookmarksSection = 0,
    MWSettingsSection,
    MWNumberOfSections
};

@interface MWServerListViewController ()

@property (strong, nonatomic) NSMutableArray *serverBookmarks;
@property (strong, nonatomic) NSMutableDictionary *currentConnections;

@end

@implementation MWServerListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.currentConnections = [NSMutableDictionary dictionary];
    self.serverBookmarks = [MWDataStore bookmarks];

    [[self navigationItem] setLeftBarButtonItem:[self editButtonItem]];

    // Update the connection status image whenever we're notified.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBookmarks)
                                                 name:MWConnectionChangedNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSNotificationCenter

- (void)updateBookmarks
{
    [self.tableView reloadData];
}

#pragma mark - UITableView Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return MWNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case MWBookmarksSection:
            return (NSInteger)[self.serverBookmarks count];

        case MWSettingsSection:
            return 1;

        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MWBookmarkCell"];

    switch ([indexPath section]) {
        case MWBookmarksSection: {
            // Everything else is a bookmark.
            NSDictionary *bookmark = self.serverBookmarks[(NSUInteger)[indexPath row]];

            // If there's no Server Name, try using the Server Host.
            if ([bookmark[kMWServerName] isEqualToString:@""]) {
                cell.textLabel.text = bookmark[kMWServerHost];
            } else {
                cell.textLabel.text = bookmark[kMWServerName];
            }

            // Set the status image.
            static UIImage *statusCircle = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                CGFloat width = 7.0f;
                CGFloat height = 7.0f;

                UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 1.0f);
                CGContextRef context = UIGraphicsGetCurrentContext();

                CGContextSetFillColorWithColor(context, [UIColor grayColor].CGColor);
                CGContextFillEllipseInRect(context, CGRectMake(0, 0, width, height));

                statusCircle = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();

                statusCircle = [statusCircle imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            });

            cell.imageView.image = statusCircle;

            NSString *indexString = [NSString stringWithFormat:@"%lu", (unsigned long)[indexPath row]];
            if (self.currentConnections[indexString]) {
                UINavigationController *controller = self.currentConnections[indexString];
                MWChatViewController *chatView = controller.viewControllers[0];

                if (chatView.isConnected) {
                    cell.imageView.tintColor = [UIColor greenColor];
                } else if (chatView.isConnecting) {
                    cell.imageView.tintColor = [UIColor orangeColor];
                } else {
                    cell.imageView.tintColor = [UIColor colorWithWhite:0.875f alpha:1.0f];
                }
            } else {
                cell.imageView.tintColor = [UIColor colorWithWhite:0.875f alpha:1.0f];
            }
        }
            break;

        case MWSettingsSection:
            cell.textLabel.text = @"Settings";
            break;

        default:
            break;
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == MWBookmarksSection && [self.serverBookmarks count] == 0) {
        return @"Welcome!";
    }

    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == MWBookmarksSection && [self.serverBookmarks count] == 0) {
        return @"You currently don't have any bookmarks. To add some, use the + button above.";
    }

    return @"";
}

#pragma mark - UITableView Delegates

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Return NO for bookmarks that are connected?
    switch ([indexPath section]) {
        case MWBookmarksSection:
            return YES;

        case MWSettingsSection:
            return NO;

        default:
            return NO;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.tableView.editing) {
        return UITableViewCellEditingStyleNone;
    }

    switch ([indexPath section]) {
        case MWBookmarksSection:
            return UITableViewCellEditingStyleDelete;

        case MWSettingsSection:
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
        self.serverBookmarks = [MWDataStore bookmarks];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

        [TestFlight passCheckpoint:@"Deleted Bookmark"];
    }
}

#pragma mark - IBActions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the selectedIndex so that we know what row to save changes to.
    NSUInteger selectedIndex = (NSUInteger)[indexPath row];
    NSString *indexString = [NSString stringWithFormat:@"%lu",(unsigned long)selectedIndex];

    if ([indexPath section] == MWBookmarksSection) {
        // Check on the connection status.
        Boolean isConnected = NO;
        if (self.currentConnections[indexString]) {
            UINavigationController *controller = self.currentConnections[indexString];
            MWChatViewController *object = controller.viewControllers[0];
            isConnected = object.isConnected;
        }

        // If we're editing, we need to display the Bookmark Settings view.
        if (self.tableView.editing && !isConnected) {
            [self performSegueWithIdentifier:kMWBookmarkSegue sender:self];
            return;
        }

        // If we're not editing, we need to open up the bookmark in the Chat view.
        if (!isConnected) {
            UIStoryboard *centerDrawer = [UIStoryboard storyboardWithName:kMWCenterDrawer bundle:nil];
            UINavigationController *chatController = [centerDrawer instantiateViewControllerWithIdentifier:kMWChatViewController];
            MWChatViewController *chatView = chatController.viewControllers[0];

            UIStoryboard *rightDrawer = [UIStoryboard storyboardWithName:kMWRightDrawer bundle:nil];
            MWUserListViewController *userListView = [rightDrawer instantiateViewControllerWithIdentifier:kMWUserListViewController];

            [chatView loadBookmark:selectedIndex];
            chatView.userListView = userListView;

            self.currentConnections[indexString] = chatController;
        }

        MMDrawerController *drawerController = [self mm_drawerController];
        drawerController.centerViewController = self.currentConnections[indexString];
        drawerController.showsShadow = YES;
        [drawerController closeDrawerAnimated:YES completion:^void(BOOL finished) {
            // We need to change some settings if this is the first centerViewController
            // we've opened since the app launched.
            drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureModeAll;
            drawerController.maximumLeftDrawerWidth = kMWLedgeSize;
        }];
        
        return;
    }

    else if ([indexPath section] == MWSettingsSection) {
        [self performSegueWithIdentifier:kMWSettingsSegue sender:self];
        return;
    }
}

- (IBAction)bookmarkSaveButtonPressed:(UIStoryboardSegue *)seque
{
    self.serverBookmarks = [MWDataStore bookmarks];
    [self.tableView reloadData];
}

- (IBAction)settingsSaveButtonPressed:(UIStoryboardSegue *)seque
{
    // Notify the connections that they should update their settings.
    [self.currentConnections enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id key, id obj, BOOL *stop){
        UINavigationController *controller = (UINavigationController *)obj;
        MWChatViewController *chatView = controller.viewControllers[0];
        [chatView sendUserInformation];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UINavigationController *destination = segue.destinationViewController;

    if ([[segue identifier] isEqualToString:kMWBookmarkSegue]) {
        MWBookmarkViewController *bookmarkSettings = [destination viewControllers][0];

        if (indexPath) {
            // Existing Bookmark
            bookmarkSettings.bookmarkIndex = [indexPath row];
        } else {
            // New Bookmark
            bookmarkSettings.bookmarkIndex = -1;
        }
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
