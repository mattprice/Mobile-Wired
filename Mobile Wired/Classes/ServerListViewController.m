//
//  ServerListViewController.m
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

#import "ServerListViewController.h"
#import "ServerListTableViewCell.h"

@implementation ServerListViewController

@synthesize navigationBar = _navigationBar;
@synthesize mainTableView = _mainTableView;

@synthesize serverBookmarks;

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
    
    // Create the edit button
    self.navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                                 target:self
                                                                                                  action:@selector(editButtonWasPressed)];
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
#pragma mark TableView Actions

- (void)editButtonWasPressed
{
    NSLog(@"*** Edit button was pressed.");
    if (self.mainTableView.editing) {
        NSLog(@"*** Server is about to stop editing.");
        [self.mainTableView setEditing:NO animated:YES];
    } else {
        NSLog(@"*** Server is about to edit.");
        [self.mainTableView setEditing:YES animated:YES];
    }
}

#pragma mark -
#pragma mark TableView Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Section 0 is the server bookmarks.
    if (section == 0) {
        return [serverBookmarks count];
    }
    
    // Section 1 is the settings.
    else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    ServerListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ServerListTableViewCell" owner:nil options:nil];
        
        for (id currentObject in topLevelObjects) {
            if([currentObject isKindOfClass:[ServerListTableViewCell class]]) {
                cell = (ServerListTableViewCell *)currentObject;
                break;
            }
        }
    }
    
    // Section 0 is for server bookmarks
    else if ([indexPath section] == 0) {
        // Get info about the current row's user
//        NSDictionary *currentBookmark = [serverBookmarks objectAtIndex:[indexPath row]];
    }
    
    
    // Section 1 is Settings
    else if ([indexPath section] == 1) {
        cell.bookmarkLabel.text = @"Settings";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Section 0 is the server bookmarks.
    if ([indexPath section] == 0) {
        return YES;
    }
    
    // Section 1 is the settings.
    else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Section 0 is for server bookmarks
    if ([indexPath section] == 0) {
        // Get info about the current bookmark.
        //        NSDictionary *currentBookmark = [serverBookmarks objectAtIndex:[indexPath row]];
    }
    
    // Section 1 is Settings
    else if ([indexPath section] == 1) {
        NSLog(@"*** Pressed settings!");
    }
}

@end
