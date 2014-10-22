//
//  BBTGroupConversationsTableViewCell.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/11/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTGroupConversationsTableViewCell.h"

@implementation BBTGroupConversationsTableViewCell

- (void)setUnreadIndicatorView:(UIView *)unreadIndicatorView
{
    // want to use rounded view only!
    _unreadIndicatorView = unreadIndicatorView;
    _unreadIndicatorView.layer.cornerRadius = _unreadIndicatorView.frame.size.height/2.0;
    _unreadIndicatorView.layer.masksToBounds = YES;
}

@end
