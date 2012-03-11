//
//  ServerListViewController.h
//  Mobile Wired
//
//  Created by Matthew Price on 4/11/11.
//  Copyright 2012 Ember Code and Magic Lime Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ServerListViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *serverBookmarks;
}

@property (strong, nonatomic) NSMutableArray *serverBookmarks;

@end
