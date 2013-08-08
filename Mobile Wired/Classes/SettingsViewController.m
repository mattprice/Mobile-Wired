//
//  SettingsViewController.m
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

#import "SettingsViewController.h"
#import "SettingsTextCell.h"
#import "IIViewDeckController.h"

@implementation SettingsViewController

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
    
    // Create the navigation bar.
    navigationBar.items = @[[[UINavigationItem alloc] init]];
    [[navigationBar topItem] setTitle:@"Settings"];

    // Create the reset button.
    navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset"
                                                                                style:UIBarButtonItemStyleDone
                                                                               target:self
                                                                               action:@selector(didPressReset)];
    
    [TestFlight passCheckpoint:@"Viewed Settings"];
}

#pragma mark -
#pragma mark Table View Actions

- (void)didPressReset
{
    // We need to call resignFirstResponder for all possible UITextFields.
    [nickField resignFirstResponder];
    [statusField resignFirstResponder];
    
    // Reset the view to its previous values.
    nickField.text = oldNick;
    statusField.text = oldStatus;
    
    // Re-save the previous values.
    [[NSUserDefaults standardUserDefaults] setObject:oldNick forKey:@"UserNick"];
    [[NSUserDefaults standardUserDefaults] setObject:oldStatus forKey:@"UserStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [TestFlight passCheckpoint:@"Reset Settings"];
}

#pragma mark -
#pragma mark ViewDeck Delegates

- (void)viewDeckController:(IIViewDeckController*)viewDeckController
 didShowCenterViewFromSide:(IIViewDeckSide)viewDeckSide
                  animated:(BOOL)animated
{
    // Store the current nickname and status.
    oldNick = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserNick"];
    oldStatus = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserStatus"];
}

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
#pragma mark Text Field Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    // Save the settings.
    [[NSUserDefaults standardUserDefaults] setObject:nickField.text forKey:@"UserNick"];
    [[NSUserDefaults standardUserDefaults] setObject:statusField.text forKey:@"UserStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [TestFlight passCheckpoint:@"Modified Settings"];
    
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    switch ([indexPath row]) {
        case 0:
        {
            cell.textLabel.text = @"Nick";
        
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(120, 20, 150, 20)];
            textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserNick"];
            
            cell.accessoryView = textField;
            nickField = textField;
            
            break;
        }
            
        case 1:
        {
            cell.textLabel.text = @"Status";
            
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(120, 20, 150, 20)];
            textField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserStatus"];
            
            cell.accessoryView = textField;
            statusField = textField;
            
            break;
        }
            
        default:
        {
            cell.textLabel.text = @"Name";
        
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(120, 20, 150, 20)];
            textField.text = @"Value";

            cell.accessoryView = textField;
        
            break;
        }
    }
    
    return cell;
}

@end
