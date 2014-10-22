//
//  BBTGroupConversationsTableViewCell.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/11/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * BBTGroupConversationsTableViewCell represents a group conversation in a TVC
 * dedicated to showing a selection of groupchats.
 */
@interface BBTGroupConversationsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *expiryTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *likesCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoAttachedImageView;
@property (weak, nonatomic) IBOutlet UIView *unreadIndicatorView;

@end
