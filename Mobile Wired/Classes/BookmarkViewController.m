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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldWasSelected:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    
    // Create the navigation bar.
    navigationBar.items = @[[[UINavigationItem alloc] init]];
    [[navigationBar topItem] setTitle:@"Edit Bookmark"];
    
    // Create the reset button.
    navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset"
                                                                                style:UIBarButtonItemStyleDone
                                                                               target:self
                                                                               action:@selector(didPressReset)];
    
    // Notify us when the keyboard is hidden.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
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
    
    [pushSettingSwitch setOn:oldPushSetting animated:YES];
    
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
    // Set placeholder text for the server name field on each change.
    serverNameField.placeholder = serverHostField.text;
    
    // Create a dictionary to store the bookmark in.
    NSMutableDictionary *bookmark = [NSMutableDictionary dictionary];
    
    bookmark[@"ServerHost"]    = (serverHostField.text) ? serverHostField.text : @"";
    bookmark[@"ServerName"]    = (serverNameField.text) ? serverNameField.text : @"";
    bookmark[@"ServerPort"]    = (serverPortField.text) ? serverPortField.text : @"";
    bookmark[@"UserNick"]      = (userNickField.text)   ? userNickField.text   : @"";
    bookmark[@"UserStatus"]    = (userStatusField.text) ? userStatusField.text : @"";
    bookmark[@"UserLogin"]     = (userLoginField.text)  ? userLoginField.text  : @"";
    bookmark[@"Notifications"] = @(pushSettingSwitch.on);
    
    // Storing the password requires a little more effort because of SHA1 hashing.
    if (textField == userPassField && ![userPassField.text isEqualToString:@""]) {
        // If the current field is the password field, create a SHA1 hash.
        bookmark[@"UserPass"] = [userPassField.text SHA1Value];
    } else if (![userPassField.text isEqualToString:@""]) {
        // If this is not the password field and we already have a SHA1'd password, use it.
        bookmark[@"UserPass"] = userPassField.text;
    } else {
        // In all other cases, the password should be a blank string.
        bookmark[@"UserPass"] = @"";
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

- (void)textFieldWasSelected:(NSNotification *)notification
{
    [UIView animateWithDuration:[[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0
                        options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] doubleValue]
                     animations:^{
                         // Resize the main UITableView.
                         // TODO: Don't hardcode the height.
                         self.mainTableView.frame = CGRectMake(self.mainTableView.frame.origin.x,
                                                               self.mainTableView.frame.origin.y,
                                                               self.mainTableView.frame.size.width,
                                                               308.0);
                         
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
    [self saveBookmark:textField];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Disable panning view while typing.
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Re-enable panning of view.
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
}

- (void)notificationSettingChanged:(UIControl *)sender
{
    [self saveBookmark];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:[[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0
                        options:[[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] doubleValue]
                     animations:^{
                         // Resize the main UITableView.
                         // TODO: Don't hardcode the height.
                         self.mainTableView.frame = CGRectMake(self.mainTableView.frame.origin.x,
                                                               self.mainTableView.frame.origin.y,
                                                               self.mainTableView.frame.size.width,
                                                               [[UIScreen mainScreen] bounds].size.height - 44);
                     }
     
                     completion:^(BOOL finished){
                         // Do nothing.
                     }];
}

#pragma mark -
#pragma mark Table View Data Sources

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

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
        return 3;
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
        return @"To enable offline notifications, all messages must be routed through our server.";
    }
    
    else {
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // Create a UITextField and set its delegate.
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(70, 20, 200, 20)];
    textField.delegate = self;
    
    // Because selectedIndex starts counting at 0, the only time it will ever
    // equal the number of saved bookmarks is if we are creating a new bookmark.
    // Ex: If we have 4 bookmarks, the highest bookmark index is 3. Add Bookmark is index 4.
    NSMutableDictionary *bookmark = [NSMutableDictionary dictionary];
    if ( [(NSDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:@"Bookmarks"] count] != serverList.selectedIndex ) {
        bookmark = [[NSUserDefaults standardUserDefaults] objectForKey:@"Bookmarks"][serverList.selectedIndex];
    }

    // Server Info
    if ([indexPath section] == 0) {
        switch ([indexPath row]) {
            case 0:
                cell.textLabel.text = @"Name";
                cell.accessoryView = textField;
                serverNameField = textField;
            
                if (bookmark != nil) {
                    oldServerName = bookmark[@"ServerName"];
                    textField.text = oldServerName;
                } else {
                    textField.text = @"";
                }
                
                textField.placeholder = bookmark[@"ServerName"];
                
                break;
                
            case 1:
                cell.textLabel.text = @"Host";
                cell.accessoryView = textField;
                serverHostField = textField;

                if (bookmark != nil) {
                    oldServerHost = bookmark[@"ServerHost"];
                    textField.text = oldServerHost;
                } else {
                    textField.text = @"";
                }
                
                textField.keyboardType = UIKeyboardTypeURL;
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.placeholder = bookmark[@"ServerHost"];
                
                break;
                
            case 2:
                cell.textLabel.text = @"Port";
                cell.accessoryView = textField;
                serverPortField = textField;
            
                if (bookmark != nil) {
                    oldServerPort = bookmark[@"ServerPort"];
                    textField.text = oldServerPort;
                } else {
                    textField.text = @"";
                }
                
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.placeholder = @"4871";
            
                break;
                
            default:
                break;
        }
    }
    
    // Login Info
    else if ([indexPath section] == 1) {
        switch ([indexPath row]) {
            case 0:
                cell.textLabel.text = @"Login";
                cell.accessoryView = textField;
                userLoginField = textField;
                
                if (bookmark != nil) {
                    oldUserLogin = bookmark[@"UserLogin"];
                    textField.text = oldUserLogin;
                    
//                    textField.enabled = NO;
//                    textField.textColor = [UIColor grayColor];
//                    cell.textLabel.textColor = [UIColor grayColor];
                } else {
                    textField.text = @"";
                }
                
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.placeholder = @"guest";
                
                break;
                
            case 1:
                cell.textLabel.text = @"Pass";
                cell.accessoryView = textField;
                userPassField = textField;
                
                if (bookmark != nil) {
                    oldUserPass = bookmark[@"UserPass"];
                    textField.secureTextEntry = YES;
                    textField.text = oldUserPass;
                    
//                    textField.enabled = NO;
//                    textField.textColor = [UIColor grayColor];
//                    cell.textLabel.textColor = [UIColor grayColor];
                } else {
                    textField.text = @"";
                }
                
                textField.autocorrectionType = UITextAutocorrectionTypeNo;
                textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                textField.placeholder = @"none";
                
                break;
                
            default:
                cell.textLabel.text = @"Name";
                textField.text = @"Value";
                break;
        }
    }
    
    // Settings
    else if ([indexPath section] == 2) {
        switch ([indexPath row]) {
            case 0:
                cell.textLabel.text = @"Nick";
                cell.accessoryView = textField;
                userNickField = textField;
                
                if (bookmark != nil) {
                    oldUserNick = bookmark[@"UserNick"];
                    textField.text = oldUserNick;
                } else {
                    textField.text = @"";
                }
                
                textField.placeholder = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserNick"];
                
                break;
                
            case 1:
                cell.textLabel.text = @"Status";
                cell.accessoryView = textField;
                userStatusField = textField;
                
                if (bookmark != nil) {
                    oldUserStatus = bookmark[@"UserStatus"];
                    textField.text = oldUserStatus;
                } else {
                    textField.text = @"";
                }
                
                textField.placeholder = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserStatus"];
                
                break;
                
            case 2:
            {
                // The size components of the CGRect are ignored by UISwitch.
                UISwitch *settingSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                [settingSwitch addTarget:self action:@selector(notificationSettingChanged:) forControlEvents:UIControlEventValueChanged];
            
                cell.textLabel.text = @"Notifications";
                cell.accessoryView = settingSwitch;
                pushSettingSwitch = settingSwitch;
                
                if (bookmark != nil) {
                    oldPushSetting = [bookmark[@"Notifications"] boolValue];
                    [pushSettingSwitch setOn:oldPushSetting animated:NO];
                } else {
                    [pushSettingSwitch setOn:NO animated:NO];
                }
            
                break;
            }
            
            default:
                cell.textLabel.text = @"Name";
                break;
        }
    }
    
    return cell;
}

@end
