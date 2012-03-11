//
//  ServerListViewController.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2012 Ember Code and Magic Lime Software. All rights reserved.
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
        
        for(id currentObject in topLevelObjects) {
            if([currentObject isKindOfClass:[ServerListTableViewCell class]]) {
                cell = (ServerListTableViewCell *)currentObject;
                break;
            }
        }
    }
    
    // Get info about the current row's user
    NSDictionary *currentBookmark = [serverBookmarks objectAtIndex:[indexPath row]];
    
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
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
