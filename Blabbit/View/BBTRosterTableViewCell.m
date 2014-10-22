//
//  BBTRosterTableViewCell.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/16/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTRosterTableViewCell.h"

@implementation BBTRosterTableViewCell

- (void)setAvatarImageView:(UIImageView *)avatarImageView
{
    // want to use rounded images only!
    _avatarImageView = avatarImageView;
    _avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.height/2.0;
    _avatarImageView.layer.masksToBounds = YES;
}

@end
