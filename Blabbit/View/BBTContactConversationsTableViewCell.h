//
//  BBTContactConversationsTableViewCell.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/11/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BBTBubbleLabel.h"

/**
 * BBTContactConversationsTableViewCell is used in the ContactConversationsCDTVC
 * for representing an ongoing 1-on-1 chat conversation with a BBTUser
 */
@interface BBTContactConversationsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *lastMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet BBTBubbleLabel *unreadMessageCountLabel;

@end
