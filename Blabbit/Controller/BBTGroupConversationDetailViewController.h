//
//  BBTGroupConversationDetailViewController.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/19/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTScrollViewContainer.h"

@class BBTGroupConversation;

/**
 * BBTGroupConversatioDetailViewController shows the content of any given
 * Group conversation which includes:
 * - Subject
 * - Number of likes
 * - Expiry time
 * - Photo (if present)
 */
@interface BBTGroupConversationDetailViewController : BBTScrollViewContainer

/**
 * The model for this controller
 */
@property (strong, nonatomic) BBTGroupConversation *conversation;

@end
