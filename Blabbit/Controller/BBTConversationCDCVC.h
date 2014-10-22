//
//  BBTConversationCDCVC.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "MessagesCoreDataCollectionViewController.h"
#import "JSQMessages.h"
#import "BBTConversation.h"


/**
 * The `BBTConversationCDVC` class represents a view controller whose content
 * consists of a `JSQMessagesCollectionView` and `JSQMessagesInputToolbar` and
 * is specialized to display a messaging interface.
 *
 * @note subclasses should override -setupConversation if the conversation property
 * isn't explicitly set on segue.
 */
@interface BBTConversationCDCVC : MessagesCoreDataCollectionViewController <UITextViewDelegate>

/** 
 * need this property to get a handle to the database
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

/** 
 * set the conversation, which could be a chat or a groupchat
 * This should be done before seguing to this VC. If you don't want to do that
 * then you need to implement the abstract function `setupConversation`
 *
 * @see setupConversation
 */
@property (strong, nonatomic) id <BBTConversation> conversation;

/**
 * Avatar images are to be created one time and reused for good performance
 * So will track all avatars for this conversation in the avatars dictionary
 */
@property (strong, nonatomic) NSMutableDictionary *avatars;

/**
 * This forces you to setup the conversation property if not already done.
 * This could happen if managedObjectContext wasn't configured when subclass was
 *   ready to do set the conversation property.
 *
 * This is an abstract method optionally be implemented by subclasses if necessary
 *
 * @see conversation
 */
- (void)setupConversation; // abstract for subclasses


/**
 * Start populating the avatars property with any users we know are in
 *   conversation
 * It's safe to assume this function is only called when there's a managedObjectContext
 */
- (void)setupAvatarsForConversation;

@end
