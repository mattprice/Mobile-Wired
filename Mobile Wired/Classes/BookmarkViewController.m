//
//  BookmarkViewController.m
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

#import "BookmarkViewController.h"
#import "IIViewDeckController.h"
#import "SettingsTextCell.h"
#import "NSString+Hashes.h"

@implementation BookmarkViewController

@synthesize mainTableView = _mainTableView;
@synthesize serverList;

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
    
    // Register an event for when a keyboard pops up
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textfieldWasSelected:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    
    // Create the navigation bar.
    navigationBar.items = [NSArray arrayWithObject:[[UINavigationItem alloc] init]];
    [navigationBar setTitle:@"Edit Bookmark"];
    
    // Create the reset button.
    navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset"
                                                                                style:UIBarButtonItemStyleDone
                                                                               target:self
                                                                               action:@selector(didPressReset)];
    
    // Notify us when the keyboard is hidden.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(adjustMainTableView)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
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

#pragma mark -
#pragma mark ViewDeck Delegates

- (BOOL)viewDeckController:(IIViewDeckController*)viewDeckController shouldOpenViewSide:(IIViewDeckSide)viewDeckSide
{
    // Don't let users swipe to the right side. It's either empty or a user list.
    if ( viewDeckSide == IIViewDeckRightSide ) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark Table View Actions

- (void)didPressReset
{
    // We need to call resignFirstResponder for all possible UITextFields.
    [serverNameField resignFirstResponder];
    [serverHostField resignFirstResponder];
    [serverPortField resignFirstResponder];
    [userLoginField resignFirstResponder];
    [userPassField resignFirstResponder];
    
    // Reset the view to its previous values.
    serverNameField.text = oldServerName;
    serverHostField.text = oldServerHost;
    serverPortField.text = oldServerPort;
    userLoginField.text = oldUserLogin;
    userPassField.text = oldUserPass;
    
    [self saveBookmark];
}

- (void)deleteBookmark
{
    // Store the bookmark.
    NSMutableArray *savedBookmarks = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Bookmarks"] mutableCopy];
    [savedBookmarks removeObjectAtIndex:serverList.selectedIndex];
    [[NSUserDefaults standardUserDefaults] setObject:savedBookmarks forKey:@"Bookmarks"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveBookmark
{
    [self saveBookmark:nil];
}

- (void)saveBookmark:(UITextField *)textField
{
    // Create a dictionary to store the bookmark in.
    NSMutableDictionary *bookmark = [NSMutableDictionary dictionary];
    
    if (serverHostField.text) {
        [bookmark setValue:serverHostField.text forKey:@"ServerHost"];
    } else {
        [bookmark setValue:@"" forKey:@"ServerHost"];
    }
    
    if (serverNameField.text) {
        [bookmark setValue:serverNameField.text forKey:@"ServerName"];
    } else {
        [bookmark setValue:@"" forKey:@"ServerName"];
    }
    
    // Set placeholder text for the server name field on each change.
    serverNameField.placeholder = serverHostField.text;
    
    if (serverPortField.text) {
        [bookmark setValue:serverPortField.text forKey:@"ServerPort"];
    } else {
        [bookmark setValue:@"" forKey:@"ServerPort"];
    }
    
    if (userLoginField.text) {
        [bookmark setValue:userLoginField.text forKey:@"UserLogin"];
    } else {
        [bookmark setValue:@"" forKey:@"UserLogin"];
    }
    
    if (textField == userPassField && ![userPassField.text isEqualToString:@""]) {
        // If the current field is the password field, create a SHA1 hash.
        [bookmark setValue:[userPassField.text SHA1Value] forKey:@"UserPass"];
    } else if (![userPassField.text isEqualToString:@""]) {
        // If this is not the password field and we already have a SHA1'd password, use it.
        [bookmark setValue:userPassField.text forKey:@"UserPass"];
    } else {
        // In all other cases, the password should be a blank string.
        [bookmark setValue:@"" forKey:@"UserPass"];
    }
    
    if (userNickField.text) {
        [bookmark setValue:userNickField.text forKey:@"UserNick"];
    } else {
        [bookmark setValue:@"" forKey:@"UserNick"];
    }
    
    if (userStatusField.text) {
        [bookmark setValue:userStatusField.text forKey:@"UserStatus"];
    } else {
        [bookmark setValue:@"" forKey:@"UserStatus"];
    }
    
    // Store the new bookmark list.
    NSMutableArray *savedBookmarks = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Bookmarks"] mutableCopy];
    [savedBookmarks setObject:bookmark atIndexedSubscript:serverList.selectedIndex];
    [[NSUserDefaults standardUserDefaults] setObject:savedBookmarks forKey:@"Bookmarks"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Reload the server list view.
    [serverList.mainTableView reloadData];
}

#pragma mark -
#pragma mark Text Field Delegates

- (void)textfieldWasSelected:(NSNotification *)notification
{
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // Resize the main UITableView.
                         self.mainTableView.frame = CGRectMake(self.mainTableView.frame.origin.x,
                                                               self.mainTableView.frame.origin.y,
                                                               self.mainTableView.frame.size.width,
                                                               200.0);
                         
                         // Scroll the table view to the selected text field.
                         UITextField *textField = [notification object];
                         UITableViewCell *tableCell = (UITableViewCell*)textField.superview.superview;
                         NSIndexPath *indexPath = [self.mainTableView indexPathForCell:tableCell];
                         
                         [self.mainTableView scrollToRowAtIndexPath:indexPath
                                                   atScrollPosition:UITableViewScrollPositionMiddle
                                                           animated:YES];
                     }
     
                     completion:^(BOOL finished){
                         // Do nothing.
                     }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    // Re-enable panning of view.
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Disable panning view while typing.
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    [self saveBookmark:textField];
    
    return YES;
}

- (void)adjustMainTableView
{
    [UIView animateWithDuration:.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // Resize the main UITableView.
                         self.mainTableView.frame = CGRectMake(self.mainTableView.frame.origin.x,
                                                               self.mainTableView.frame.origin.y,
                                                               self.mainTableView.frame.size.width,
                                                               416.0);
                     }
     
                     completion:^(BOOL finished){
                         // Do nothing.
                     }];
}

#pragma mark -
#pragma mark Table View Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Server Info
    if (section == 0) {
        return 3;
    }
    
    // Login Info
    else if (section == 1) {
        return 2;
    }
    
    // Settings
    else if (section == 2) {
        return 2;
//        return 3;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Server Info";
    }
    
    else if (section == 1) {
        return @"Login Info";
    }

    else if (section == 2) {
        return @"Settings";
    }
    
    else {
        return @"";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 2) {
        return @"";
//        return @"To enable notifications, all messages must be routed through our server.";
    }
    
    else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    SettingsTextCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SettingsTextCell" owner:nil options:nil];
        
        for (id currentObject in topLevelObjects) {
            if([currentObject isKindOfClass:[SettingsTextCell class]]) {
                cell = (SettingsTextCell *)currentObject;
                break;
            }
        }
    }
    
    // Set the UITextField's delegate.
    cell.settingValue.delegate = self;
    
    // Because selectedIndex starts counting at 0, the only time it will ever
    // equal the number of saved bookmarks is if we are creating a new bookmark.
    // Ex: If we have 4 bookmarks, the highest bookmark index is 3. Add Bookmark is index 4.
    NSMutableDictionary *bookmark = [NSMutableDictionary dictionary];
    if ( [[[NSUserDefaults standardUserDefaults] objectForKey:@"Bookmarks"] count] != serverList.selectedIndex ) {
        bookmark = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Bookmarks"] objectAtIndex:serverList.selectedIndex];
    }

    // Server Info
    if ([indexPath section] == 0) {
        switch ([indexPath row]) {
            case 0:
                cell.settingName.text = @"Name";
                serverNameField = cell.settingValue;
                
                if (bookmark != nil) {
                    oldServerName = [bookmark objectForKey:@"ServerName"];
                    cell.settingValue.text = oldServerName;
                } else {
                    cell.settingValue.text = @"";
                }
                
                cell.settingValue.placeholder = [bookmark objectForKey:@"ServerHost"];
                
                break;
                
            case 1:
                cell.settingName.text = @"Host";
                cell.settingValue.keyboardType = UIKeyboardTypeURL;
                serverHostField = cell.settingValue;
                
                if (bookmark != nil) {
                    oldServerHost = [bookmark objectForKey:@"ServerHost"];
                    cell.settingValue.text = oldServerHost;
                } else {
                    cell.settingValue.text = @"";
                }
                
                break;
                
            case 2:
                cell.settingName.text = @"Port";
                cell.settingValue.keyboardType = UIKeyboardTypeNumberPad;
                serverPortField = cell.settingValue;
                
                if (bookmark != nil) {
                    oldServerPort = [bookmark objectForKey:@"ServerPort"];
                    cell.settingValue.text = oldServerPort;
                } else {
                    cell.settingValue.text = @"";
                }
                
                cell.settingValue.placeholder = @"4871";
                
                break;
                
            default:
                cell.settingName.text = @"Name";
                cell.settingValue.text = @"Value";
                break;
        }
    }
    
    // Login Info
    else if ([indexPath section] == 1) {
        switch ([indexPath row]) {
            case 0:
                cell.settingName.text = @"Login";
                userLoginField = cell.settingValue;
                
                if (bookmark != nil) {
                    oldUserLogin = [bookmark objectForKey:@"UserLogin"];
                    cell.settingValue.text = oldUserLogin;
                    
//                    cell.settingValue.enabled = NO;
//                    cell.settingValue.textColor = [UIColor grayColor];
//                    cell.settingName.textColor = [UIColor grayColor];
                } else {
                    cell.settingValue.text = @"";
                }
                
                cell.settingValue.placeholder = @"guest";
                
                break;
                
            case 1:
                cell.settingName.text = @"Pass";
                userPassField = cell.settingValue;
                
                if (bookmark != nil) {
                    oldUserPass = [bookmark objectForKey:@"UserPass"];
                    cell.settingValue.secureTextEntry = YES;
                    cell.settingValue.text = oldUserPass;
                    
//                    cell.settingValue.enabled = NO;
//                    cell.settingValue.textColor = [UIColor grayColor];
//                    cell.settingName.textColor = [UIColor grayColor];
                } else {
                    cell.settingValue.text = @"";
                }
                
                cell.settingValue.placeholder = @"none";
                
                break;
                
            default:
                cell.settingName.text = @"Name";
                cell.settingValue.text = @"Value";
                break;
        }
    }
    
    // Settings
    else if ([indexPath section] == 2) {
        switch ([indexPath row]) {
            case 0:
                cell.settingName.text = @"Nick";
                userNickField = cell.settingValue;
                
                if (bookmark != nil) {
                    oldUserNick = [bookmark objectForKey:@"UserNick"];
                    cell.settingValue.text = oldUserNick;
                } else {
                    cell.settingValue.text = @"";
                }
                
                cell.settingValue.placeholder = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserNick"];
                
                break;
                
            case 1:
                cell.settingName.text = @"Status";
                userStatusField = cell.settingValue;
                
                if (bookmark != nil) {
                    oldUserStatus = [bookmark objectForKey:@"UserStatus"];
                    cell.settingValue.text = oldUserStatus;
                } else {
                    cell.settingValue.text = @"";
                }
                
                cell.settingValue.placeholder = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserStatus"];
                
                break;
                
            case 2:
                cell.settingName.text = @"Notifications";
                cell.settingName.textColor = [UIColor grayColor];
                cell.settingName.alpha = 0.6;
                
                cell.settingValue.text = @"Disabled";
                cell.settingValue.textColor = [UIColor grayColor];
                cell.settingValue.enabled = NO;
                cell.settingValue.alpha = 0.6;

                break;
                
            default:
                cell.settingName.text = @"Name";
                cell.settingValue.text = @"Value";
                break;
        }
    }
    
    return cell;
}

@end
