//
//  ServerListTableViewCell.m
//  Mobile Wired
//
//  Created by Matthew Price on 3/11/12.
//  Copyright (c) 2012 Ember Code and Magic Lime Software. All rights reserved.
//

#import "ServerListTableViewCell.h"

@implementation ServerListTableViewCell

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
