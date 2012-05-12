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
#import "SettingsTextCell.h"
#import "IIViewDeckController.h"

@implementation BookmarkViewController

@synthesize mainTableView = _mainTableView;

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
    
    // Store the current nickname and status.
//    oldNick = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserNick"];
//    oldStatus = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserStatus"];
    
    // Create the reset button.
    navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset"
                                                                                style:UIBarButtonItemStyleDone
                                                                               target:self
                                                                               action:@selector(didPressReset)];}

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
    
    // Re-save the previous values.
//    [[NSUserDefaults standardUserDefaults] setObject:oldServerName forKey:@"ServerName"];
//    [[NSUserDefaults standardUserDefaults] setObject:oldServerHost forKey:@"ServerHost"];
//    [[NSUserDefaults standardUserDefaults] setObject:oldServerPort forKey:@"ServerPort"];
//    [[NSUserDefaults standardUserDefaults] setObject:oldUserLogin forKey:@"UserLogin"];
//    [[NSUserDefaults standardUserDefaults] setObject:oldUserPass forKey:@"UserPass"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark View Deck Delegates

- (void)viewDeckControllerDidShowCenterView:(IIViewDeckController*)viewDeckController animated:(BOOL)animated
{
    // Store the current nickname and status.
//    oldNick = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserNick"];
//    oldStatus = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserStatus"];
}

#pragma mark -
#pragma mark Text Field Delegates

- (void)textfieldWasSelected:(NSNotification *)notification
{
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         self.mainTableView.frame = CGRectMake(self.mainTableView.frame.origin.x, self.mainTableView.frame.origin.y, self.mainTableView.frame.size.width, 200.0);
                         [self.mainTableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionBottom animated:NO];
                     }
     
                     completion:^(BOOL finished){
                         // Do nothing.
                     }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    // Save the settings.
//    [[NSUserDefaults standardUserDefaults] setObject:serverNameField.text forKey:@"ServerName"];
//    [[NSUserDefaults standardUserDefaults] setObject:serverHostField.text forKey:@"ServerHost"];
//    [[NSUserDefaults standardUserDefaults] setObject:serverPortField.text forKey:@"ServerPort"];
//    [[NSUserDefaults standardUserDefaults] setObject:userLoginField.text forKey:@"UserLogin"];
//    [[NSUserDefaults standardUserDefaults] setObject:userPassField.text forKey:@"UserPass"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    
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
    // Re-enable panning of view.
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
    
    return YES;
}

#pragma mark -
#pragma mark Table View Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Server Info
    if (section == 0) {
        return 3;
    }
    
    // Login Info
    return 2;
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
    
    if ([indexPath section] == 0) {
        switch ([indexPath row]) {
            case 0:
                cell.settingName.text = @"Name";
//                cell.settingValue.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserNick"];
                serverNameField = cell.settingValue;
                break;
                
            case 1:
                cell.settingName.text = @"Host";
//                cell.settingValue.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserStatus"];
                cell.settingValue.keyboardType = UIKeyboardTypeURL;
                serverHostField = cell.settingValue;
                break;
                
            case 2:
                cell.settingName.text = @"Port";
//                cell.settingValue.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserStatus"];
                cell.settingValue.keyboardType = UIKeyboardTypeNumberPad;
                serverPortField = cell.settingValue;
                break;
                
            default:
                cell.settingName.text = @"Name";
                cell.settingValue.text = @"Value";
                break;
        }
    }
    
    else if ([indexPath section] == 1) {
        switch ([indexPath row]) {
            case 0:
                cell.settingName.text = @"Login";
//                cell.settingValue.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserNick"];
                userLoginField = cell.settingValue;
                break;
                
            case 1:
                cell.settingName.text = @"Password";
//                cell.settingValue.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserStatus"];
                userPassField = cell.settingValue;
                break;
                
            default:
                cell.settingName.text = @"Name";
                cell.settingValue.text = @"Value";
                break;
        }
    }
    
    // TODO: TEMPORARY.
    cell.settingValue.text = @"";
    
    cell.settingValue.delegate = self;
    
    return cell;
}

@end
