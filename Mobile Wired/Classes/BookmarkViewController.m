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
    // Create a dictionary to store the bookmark in.
    NSMutableDictionary *bookmark = [NSMutableDictionary dictionary];
    if (serverNameField.text) {
        [bookmark setObject:serverNameField.text forKey:@"ServerName"];
    } else {
        [bookmark setObject:@"" forKey:@"ServerName"];
    }
    
    if (serverHostField.text) {
        [bookmark setObject:serverHostField.text forKey:@"ServerHost"];
    } else {
        [bookmark setObject:@"" forKey:@"ServerHost"];
    }
    
    if (serverPortField.text) {
        [bookmark setObject:serverPortField.text forKey:@"ServerPort"];
    } else {
        [bookmark setObject:@"" forKey:@"ServerPort"];
    }
    
    if (userLoginField.text) {
        [bookmark setObject:userLoginField.text forKey:@"UserLogin"];
    } else {
        [bookmark setObject:@"" forKey:@"UserLogin"];
    }
    
    if (userPassField.text) {
        [bookmark setObject:[userPassField.text SHA1Value] forKey:@"UserPass"];
    } else {
        [bookmark setObject:[@"" SHA1Value] forKey:@"UserPass"];
    }
    
    // Store the new bookmark list.
    NSMutableArray *savedBookmarks = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Bookmarks"] mutableCopy];
    [savedBookmarks insertObject:bookmark atIndex:serverList.selectedIndex];
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
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         self.mainTableView.frame = CGRectMake(self.mainTableView.frame.origin.x,
                                                               self.mainTableView.frame.origin.y,
                                                               self.mainTableView.frame.size.width,
                                                               200.0);
                         [self.mainTableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionBottom animated:NO];
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
    [self saveBookmark];
    
    return YES;
}

- (void)adjustMainTableView
{
    // Lengthen the chat view.
    [UIView animateWithDuration:.25
                          delay:0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         self.mainTableView.frame = CGRectMake(self.mainTableView.frame.origin.x,
                                                               self.mainTableView.frame.origin.y,
                                                               self.mainTableView.frame.size.width,
                                                               416.0);
                         [self.mainTableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionBottom animated:NO];
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
    
    // Delete Button
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Server Info";
    }
    
    else if (section == 1) {
        return @"Login Info";
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
                } else {
                    cell.settingValue.text = @"";
                }
                
                break;
                
            case 1:
                cell.settingName.text = @"Pass";
                userPassField = cell.settingValue;
                
                if (bookmark != nil) {
                    oldUserPass = [bookmark objectForKey:@"UserPass"];
                    cell.settingValue.secureTextEntry = YES;
                    cell.settingValue.text = oldUserPass;
                } else {
                    cell.settingValue.text = @"";
                }
                
                break;
                
            default:
                cell.settingName.text = @"Name";
                cell.settingValue.text = @"Value";
                break;
        }
    }
    
    // Delete Button
    else if ([indexPath section] == 2) {
        // Create the button.
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(9, 0, 302, 45);
        
        // Set the button title.
        [button setTitle:@"Delete Bookmark" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
        button.titleLabel.shadowColor = [UIColor colorWithWhite:0.8 alpha:0.3];
        button.titleLabel.shadowOffset = CGSizeMake(0, -1);
        
        // Set the button background image.
        UIImage *buttonImage = [UIImage imageNamed:@"UIButton_Red.png"];
        [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
        
        // Set the button action.
        [button addTarget:self action:@selector(deleteBookmark) forControlEvents:UIControlEventTouchUpInside];
        
        // Add the button as a subview.
        [cell addSubview:button];
    }
    
    return cell;
}

@end
