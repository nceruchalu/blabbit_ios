//
//  BBTRosterTableViewCell.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/16/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * BBTRosterTableViewCell represents a row in a table view controller used to
 * display a user on the site. 
 * This can be subclassed to add more specific controls like "add" or "remove 
 * user buttons.
 */
@interface BBTRosterTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *onlineStatusLabel;

@end
