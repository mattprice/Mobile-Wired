//
//  UserListTableViewCell.h
//  Mobile Wired
//
//  Created by Sphinx on 24/02/2012.
//  Copyright (c) 2012 Ember Code and Magic Lime Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserListTableViewCell : UITableViewCell
{
    IBOutlet UILabel *nickLabel, *onlyNickLabel, *statusLabel;
    IBOutlet UIImageView *avatar;
}

@property (nonatomic, retain) IBOutlet UIImageView *avatar;
@property (nonatomic, retain) IBOutlet UILabel *nickLabel, *onlyNickLabel, *statusLabel;
@end
