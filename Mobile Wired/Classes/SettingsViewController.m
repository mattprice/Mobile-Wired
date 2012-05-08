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
    navigationBar.items = [NSArray arrayWithObject:[[UINavigationItem alloc] init]];
    [navigationBar setTitle:@"Settings"];
    
    // Create the Cancel button.
    navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                            target:self
                                                                                            action:@selector(didPressCancel)];
    
    // Create the Save button.
    navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                             target:self
                                                                                             action:@selector(didPressSave)];
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

- (void)didPressCancel
{
    // We need to call resignFirstResponder for all possible UITextFields.
    [nickField resignFirstResponder];
    [statusField resignFirstResponder];
    
    // Reset the view to default values just incase something changed.
    nickField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserNick"];
    statusField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserStatus"];
    
    // Re-open the left view.
    [self.viewDeckController openLeftViewAnimated:YES];
}

- (void)didPressSave
{
    // We need to call resignFirstResponder for all possible UITextFields.
    [nickField resignFirstResponder];
    [statusField resignFirstResponder];
    
    // Save all the settings, changed or not.
    [[NSUserDefaults standardUserDefaults] setObject:nickField.text forKey:@"UserNick"];
    [[NSUserDefaults standardUserDefaults] setObject:statusField.text forKey:@"UserStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Re-open the left view.
    [self.viewDeckController openLeftViewAnimated:YES];
}

#pragma mark -
#pragma mark Text Field Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.viewDeckController.panningMode = IIViewDeckNoPanning;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
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
    
    switch ([indexPath row]) {
        case 0:
            cell.settingName.text = @"Nick";
            cell.settingValue.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserNick"];
            nickField = cell.settingValue;
            break;
            
        case 1:
            cell.settingName.text = @"Status";
            cell.settingValue.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserStatus"];
            statusField = cell.settingValue;
            break;
            
        default:
            cell.settingName.text = @"Name";
            cell.settingValue.text = @"Value";
            break;
    }
    
    cell.settingValue.delegate = self;
    
    return cell;
}

@end
