//
//  BBTConversation.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/11/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BBTMessage;

/**
 * Any class that wants to be treated as a conversation (chat or groupchat) has
 * to conform to the BBTConversation protocol.
 */
@protocol BBTConversation <NSObject>
@required

/**
 * Add BBTMessage object to this conversation
 *
 * @param message      BBTMessage object to be added to conversation
 */
- (void)addMessage:(BBTMessage *)message;

/**
 * Send message to this conversation and create corresponding BBTMessage object
 * that will be added to this conversation
 *
 * @param messageBody  text string of outgoing message
 */
- (void)sendMessageWithBody:(NSString *)messageBody;

/**
 * Send chatstate to this conversation .
 *
 * @param chatState  chat state to be sent
 */
- (void)sendChatState:(BBTChatState)chatState;

/**
 * This method is called when a conversation finishes receiving a message
 * while in the active chat window
 */
- (void)finishReceivingMessage;

@end
