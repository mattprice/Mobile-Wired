//
//  UserListViewController.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2011 Ember Code and Magic Lime Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UserListViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
    NSArray *userListArray;
}

@property (strong, nonatomic) NSArray *userListArray;

- (void)setUserList:(NSDictionary *)userList;

@end
