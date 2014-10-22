//
//  BBTSearchRosterTableViewCell.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTRosterTableViewCell.h"

/**
 * BBTSearchRosterTableViewCell is a roster cell that is used specifically
 * for showing results for a search of Blabbit users. This has the additional
 * button for controlling if you should add a search result user as a friend.
 */
@interface BBTSearchRosterTableViewCell : BBTRosterTableViewCell

@property (weak, nonatomic) IBOutlet UIButton *toggleFriendshipButton;

@end
