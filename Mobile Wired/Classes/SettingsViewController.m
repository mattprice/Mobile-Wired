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

@synthesize navigationBar = _navigationBar;
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
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    self.navigationBar.items = [NSArray arrayWithObject:navItem];
    
    // Set up custom navigation bar styling.
    self.navigationBar.topLineColor = [UIColor colorWithRed:0.914 green:0.914 blue:0.914 alpha:1];
    self.navigationBar.gradientStartColor = [UIColor colorWithRed:0.914 green:0.914 blue:0.914 alpha:1];
    self.navigationBar.gradientEndColor = [UIColor colorWithRed:0.718 green:0.722 blue:0.718 alpha:1];
    self.navigationBar.bottomLineColor = [UIColor colorWithRed:0.416 green:0.416 blue:0.416 alpha:.5];
    self.navigationBar.tintColor = [UIColor colorWithWhite:0.65 alpha:1];
    
    // Set up a custom UILabel so that we can change the text color.
    titleLabel = [[UILabel alloc] init];
    titleLabel.frame = CGRectMake(0, 0, 215, 44);
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
    titleLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1];
    titleLabel.textAlignment = UITextAlignmentCenter;
    titleLabel.shadowColor = [UIColor colorWithWhite:0.8 alpha:0.3];
	self.navigationBar.topItem.titleView = titleLabel;

    titleLabel.text = @"Settings";
    
    // Create the Cancel button.
    self.navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                 target:self
                                                                                                 action:@selector(didPressCancel)];
    
    // Create the Save button.
    self.navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
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
    // Close the keyboard.
    [self resignFirstResponder];
    
    // Enable panning, open the left view, and change the center view.
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
    [self.viewDeckController openLeftViewAnimated:YES];
}

- (void)didPressSave
{
    // Close the keyboard.
    [self resignFirstResponder];
    
    // Enable panning, open the left view, and change the center view.
    self.viewDeckController.panningMode = IIViewDeckFullViewPanning;
    [self.viewDeckController openLeftViewAnimated:YES];
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
            cell.settingValue.text = @"Melman";
            break;
            
        case 1:
            cell.settingName.text = @"Status";
            cell.settingValue.text = [NSString stringWithFormat:@"On my %@", [[UIDevice currentDevice] model]];
            break;
            
        default:
            cell.settingName.text = @"";
            cell.settingValue.text = @"";
            break;
    }
    
    return cell;
}

@end
