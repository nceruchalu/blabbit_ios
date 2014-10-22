//
//  BBTContactConversationCDCVC.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTConversationCDCVC.h"

@class XMPPUserCoreDataStorageObject;

/**
 * The BBTContactConversationCDCVC class is a subclass of BBTConversationCDCVC
 *   which displays the conversation with a specific XMPPRoster contact
 */
@interface BBTContactConversationCDCVC : BBTConversationCDCVC

/** 
 * The model for this controller
 */
@property (strong, nonatomic) XMPPUserCoreDataStorageObject *contact;

@end
