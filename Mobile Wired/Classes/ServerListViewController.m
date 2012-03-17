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

@interface ServerListViewController ()

@end

@implementation ServerListViewController

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
    // Do any additional setup after loading the view from its nib.
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
#pragma mark TableView Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Section 0 is server bookmarks
    if (section == 0) {
        return [serverBookmarks count];
    }
    
    // Section 1 is for Settings
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
    if ([indexPath section] == 0) {
        // Get info about the current row's user
//        NSDictionary *currentBookmark = [serverBookmarks objectAtIndex:[indexPath row]];
    }
    
    
    // Section 1 is for Settings
    if ([indexPath section] == 1) {
        cell.bookmarkLabel.text = @"Settings";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSDictionary *currentUser = [userListArray objectAtIndex:[indexPath row]];
//    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
//                                                    message:[NSString stringWithFormat:@"You selected %@!",[currentUser objectForKey:@"wired.user.nick"]]
//                                                   delegate:nil
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
//    
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//}

@end
