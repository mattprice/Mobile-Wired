//
//  UserListViewController.m
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import "UserListViewController.h"
#import "IIViewDeckController.h"
#import "UserListTableViewCell.h"


@interface UserListViewController ()

@end

@implementation UserListViewController

@synthesize userListArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initializations
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
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

- (void)setUserList:(NSDictionary *)userList
{
    // User lists are sorted into channels; save only channel 1.
    self.userListArray = [[userList objectForKey:@"1"] allValues];
    
    // Reload the TableView
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark TableView Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Return the number of Users in the list.
    return [self.userListArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UserListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UserListTableViewCell" owner:nil options:nil];
        
        for(id currentObject in topLevelObjects) {
            if([currentObject isKindOfClass:[UserListTableViewCell class]]) {
                cell = (UserListTableViewCell *)currentObject;
                break;
            }
        }
    }
    
    NSDictionary *currentUser = [userListArray objectAtIndex:[indexPath row]];
        
    cell.avatar.image = [UIImage imageWithData:[currentUser objectForKey:@"wired.user.icon"]];
    cell.nickLabel.text = [currentUser objectForKey:@"wired.user.nick"];
    cell.nickLabel.textColor = [currentUser objectForKey:@"wired.account.color"];
    cell.statusLabel.text = [currentUser objectForKey:@"wired.user.status"];
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