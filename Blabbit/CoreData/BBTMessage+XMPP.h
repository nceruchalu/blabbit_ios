//
//  BBTMessage+XMPP.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/22/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//
/**
 *  Using this file as a location to document the BBTMessage model which represents
 *  text, media and system event messages. All 3 message types are mutually-exclusive
 *
 *  Property           Purpose
 *  identifier          UniqueID for each message
 *  isIncoming          Is the message incoming/outgoing?
 *  isRead              Is this a message read yet? All outgoing messages are!
 *  localTimestamp      When the message was sent/received (as recorded by us)
 *  remoteTimestamp     When the message was sent/received (as recorded by the server)
 *  status              Code indicating message send/delivery status
 *  user                message sender:
 *                      - username in chat
 *                      - nickname in groupchat.
 *                      - reference for user performing a systemEvent
 *  
 *  // Text (chat & groupchat) messages specific
 *  body                Body of the message
 *
 *  // Media messages specific
 *  hasMedia            Is there media involved (file)
 *  imageThumbnail      UIImage populated from imageThumbnailURL.
 *  imageThumbnailURL   URL of thubmnail version of image at imageURL.
 *  imageURL            URL of sent image file on remote storage
 *
 *  // System Event messages specific
 *  isSystemEvent       Is this a system event?
 *  systemEventType     Code indicating the type of systemEvent this is
 *
 *
 *  @see BBTSystemEvent enum
 */

#import "BBTMessage.h"
#import "BBTConversation.h"

@class XMPPMessage;
@class XMPPRoom;
@class XMPPJID;
@class BBTGroupConversation;

@interface BBTMessage (XMPP)

#pragma mark - Class Methods
/**
 * Create an incoming chat message and add to associated conversation
 *
 * @param messageBody  text string in incoming message
 * @param contactJID   bare JID of message sender
 * @param conversation BBTUser conversation that message is in
 * @param context      handle to Chats database
 *
 * @return Initialized BBTMessage instance
 */
+ (instancetype)incomingMessage:(NSString *)messageBody
                    fromContact:(XMPPJID *)contactJID
                 inConversation:(BBTUser *)conversation
         inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Create an outgoing chat/groupchat message and add to associated conversation
 *
 * @param messageBody  text string in outgoing message
 * @param conversation BBTConversation that message belongs in
 * @param context      handle to Chats database
 *
 * @return Initialized BBTMessage instance
 */
+ (instancetype)outgoingMessage:(NSString *)messageBody
                    inConversation:(id<BBTConversation>)conversation
            inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Create an incoming groupchat message and add to associated conversation
 *
 * @param messageBody       text string in incoming message
 * @param nickname          nickname of message sender
 * @param remoteTimestamp   time this message was first sent by server
 * @param conversation      BBTGroupConversation that message belongs in
 * @param context           handle to Chats database
 *
 * @return Initialized BBTMessage instance
 */
+ (instancetype)incomingGroupMessage:(NSString *)messageBody
                        fromOccupant:(NSString *)nickname
                 withRemoteTimestamp:(NSDate *)remoteTimestamp
                      inConversation:(BBTGroupConversation *)conversation
              inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Mark a message as delivered
 *
 * @param identifier   identifer of message that has been delivered
 * @param context      handle to Chats database
 */
+ (void)receivedDeliveryReceiptForMessageWithIdentifier:(NSString *)identifier
                                 inManagedObjectContext:(NSManagedObjectContext *)context;


/**
 * Does this groupchat message already exist in the database?
 * This question arises when working with XMPPRooms that have messages coming via
 *   room history and reflected back at us after we send them out.
 *
 * @param message       XMPPMessage to check as a duplicate
 * @param roomJID       JID of room to check message against
 *
 * @return BOOL indicating if this message already exists in database or not.
 */
+ (BOOL)existsGroupMessage:(XMPPMessage *)message inRoom:(XMPPJID *)roomJID;

#pragma mark - Instance Methods
/**
 * Generate an attributed string for a BBTMessage that isSystemEvent.
 */
- (NSAttributedString *)systemMessage;
@end
