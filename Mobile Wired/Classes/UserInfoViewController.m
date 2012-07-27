//
//  UserInfoViewController.m
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

#import "UserInfoViewController.h"
#import "UserListTableViewCell.h"

@implementation UserInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil userInfo:(NSDictionary *)info
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        userInfo = info;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark TableView Data Sources

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UserListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UserListTableViewCell" owner:nil options:nil];
        
        for (id currentObject in topLevelObjects) {
            if([currentObject isKindOfClass:[UserListTableViewCell class]]) {
                cell = (UserListTableViewCell *)currentObject;
                break;
            }
        }
    }

    // Center the nickname if there's no status.
    if ( [[userInfo objectForKey:@"wired.user.status"] isEqualToString:@""] ) {
        cell.nickLabel.text = @"";
        cell.statusLabel.text = @"";
        
        cell.onlyNickLabel.text = [userInfo objectForKey:@"wired.user.nick"];
        cell.onlyNickLabel.textColor = [userInfo objectForKey:@"wired.account.color"];
    } else {
        cell.onlyNickLabel.text = @"";
        
        cell.nickLabel.text = [userInfo objectForKey:@"wired.user.nick"];
        cell.nickLabel.textColor = [userInfo objectForKey:@"wired.account.color"];
        cell.statusLabel.text = [userInfo objectForKey:@"wired.user.status"];
    }
    
    // Fade information about idle users
    if ( [[userInfo objectForKey:@"wired.user.idle"] isEqualToString:@"1"] ) {
        cell.nickLabel.alpha = 0.3;
        cell.onlyNickLabel.alpha = 0.3;
        cell.statusLabel.alpha = 0.4;
        cell.avatar.alpha = 0.5;
    } else {
        cell.nickLabel.alpha = 1;
        cell.onlyNickLabel.alpha = 1;
        cell.statusLabel.alpha = 1;
        cell.avatar.alpha = 1;
    }
    
    cell.avatar.image = [UIImage imageWithData:[userInfo objectForKey:@"wired.user.icon"]];
    
    return cell;
}

@end
