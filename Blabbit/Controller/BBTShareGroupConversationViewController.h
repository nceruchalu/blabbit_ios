//
//  BBTShareGroupConversationViewController.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 8/9/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTContactPickerViewController.h"

@class BBTGroupConversation;

/**
 * BBTShareGroupConversationViewController provides the user with a means to
 *   invite more participants to a group conversation.
 */
@interface BBTShareGroupConversationViewController : BBTContactPickerViewController

/**
 * The model for this controller
 */
@property (strong, nonatomic) BBTGroupConversation *conversation;

@end
