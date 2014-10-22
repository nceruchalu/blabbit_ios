//
//  BBTCreateGroupConversationViewController.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/30/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTContactPickerViewController.h"

@class BBTGroupConversation;

/**
 * BBTCreateGroupConversationViewController provides the user with a means to
 *   provide the initial data required in setting up a group: subject, photo, participants.
 */
@interface BBTCreateGroupConversationViewController : BBTContactPickerViewController

// configure the contacts @property on segue. This will be the input

/**
 * The created group conversation. This will be one of the outputs of this VC.
 * It complements the inherited output, `selectedContacts`
 */
@property (strong, nonatomic, readonly) BBTGroupConversation *createdConversation;

@end
