//
//  UserListTableViewCell.m
//  Mobile Wired
//
//  Created by Sphinx on 24/02/2012.
//  Copyright (c) 2012 Ember Code and Magic Lime Software. All rights reserved.
//

#import "UserListTableViewCell.h"

@implementation UserListTableViewCell

@synthesize nickLabel, onlyNickLabel, statusLabel, avatar;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self setFrame:CGRectMake(self.frame.origin.x + 50.0, self.frame.origin.y, self.frame.size.width, self.frame.size.height)];

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
