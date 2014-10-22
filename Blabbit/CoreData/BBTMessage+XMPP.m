//
//  BBTMessage+XMPP.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/22/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTMessage+XMPP.h"
#import "XMPPMessage.h"
#import "BBTGroupConversation+XMPP.h"
#import "BBTUtilities.h"
#import "BBTXMPPManager.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPRoom.h"
#import "BBTModelManager.h"
#import "BBTHTTPManager.h"
#import "BBTUser+HTTP.h"

@implementation BBTMessage (XMPP)

#pragma mark - Class Methods (private)
+ (instancetype)messageWithContact:(NSString *)username
                        andMessage:(NSString *)messageBody
                        isIncoming:(BOOL)incoming
                    inConversation:(BBTUser *)conversation
            inManagedObjectContext:(NSManagedObjectContext *)context
{
    BBTMessage *message = nil;
    
    // this is assumed to be a new message else we would have checked if it
    // already existed by executing a fetch based on a unique attribute like
    // identifier. If there was any object matched it would be returned else a new
    // one will be created. In this case we will just go ahead and do a creation.
    message = [NSEntityDescription insertNewObjectForEntityForName:@"BBTMessage"
                                            inManagedObjectContext:context];
    message.localTimestamp = [NSDate date];
    message.remoteTimestamp = nil;
    message.hasMedia = @(NO);
    message.identifier = [BBTUtilities uniqueString];
    message.isIncoming = @(incoming);
    message.isRead = @(!incoming);      // only incoming messages are unread when first saved
    
    //  incoming messages are delivered and outgoing messages are sent
    message.status = incoming ? @(BBTMessageStatusDelivered) : @(BBTMessageStatusSent);
    
    message.body = messageBody;
    message.user = incoming ? username : [[BBTXMPPManager sharedManager].xmppStream.myJID user];
    message.isSystemEvent = @(NO);
    
    // assign message to appropriate conversation
    [conversation addMessage:message];
    
    return message;
}

+ (instancetype)groupMessageWithOccupant:(NSString *)nickname
                              andMessage:(NSString *)messageBody
                     withRemoteTimestamp:(NSDate *)remoteTimestamp
                              isIncoming:(BOOL)incoming
                          inConversation:(BBTGroupConversation *)conversation
                  inManagedObjectContext:(NSManagedObjectContext *)context
{
    BBTMessage *message = nil;
    
    // create message
    message = [NSEntityDescription insertNewObjectForEntityForName:@"BBTMessage"
                                            inManagedObjectContext:context];
    message.localTimestamp = remoteTimestamp ? remoteTimestamp : [NSDate date];
    message.remoteTimestamp = remoteTimestamp;
    message.hasMedia = @(NO);
    message.identifier = [BBTUtilities uniqueString];
    message.isIncoming = @(incoming);
    message.isRead = @(!incoming);  // only incoming messages are unread on receipt
    message.status = incoming ? @(BBTMessageStatusDelivered) : @(BBTMessageStatusSent);
    message.body = messageBody;
    message.user = incoming ? nickname : [[BBTXMPPManager sharedManager].xmppStream.myJID user];
    message.isSystemEvent = @(NO);
    
    // assign message to appropriate conversation
    [conversation addMessage:message];
    
    return message;
}


#pragma mark - Class Methods (public)
+ (instancetype)incomingMessage:(NSString *)messageBody
                    fromContact:(XMPPJID *)contactJID
                 inConversation:(BBTUser *)conversation
         inManagedObjectContext:(NSManagedObjectContext *)context;
{
    return [BBTMessage messageWithContact:[[contactJID user] lowercaseString]
                               andMessage:messageBody
                               isIncoming:YES
                           inConversation:conversation
                   inManagedObjectContext:context];
}

+ (instancetype)outgoingMessage:(NSString *)messageBody
                 inConversation:(id<BBTConversation>)conversation
         inManagedObjectContext:(NSManagedObjectContext *)context
{
    if ([conversation isKindOfClass:[BBTGroupConversation class]]) {
        return [BBTMessage groupMessageWithOccupant:nil
                                         andMessage:messageBody
                                withRemoteTimestamp:nil
                                         isIncoming:NO
                                     inConversation:conversation
                             inManagedObjectContext:context];
        
    } else {
        return [BBTMessage messageWithContact:nil
                                   andMessage:messageBody
                                   isIncoming:NO
                               inConversation:conversation
                       inManagedObjectContext:context];
    }
}

+ (instancetype)incomingGroupMessage:(NSString *)messageBody
                        fromOccupant:(NSString *)nickname
                 withRemoteTimestamp:(NSDate *)remoteTimestamp
                      inConversation:(BBTGroupConversation *)conversation
              inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [BBTMessage groupMessageWithOccupant:nickname
                                     andMessage:messageBody
                            withRemoteTimestamp:remoteTimestamp
                                     isIncoming:YES
                                 inConversation:conversation
                         inManagedObjectContext:context];
}

+ (void)receivedDeliveryReceiptForMessageWithIdentifier:(NSString *)identifier
                                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTMessage"];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        // ideally would check for (!matches || [matches count] > 1) for an
        // error situation, but something tells me that my unique string generator
        // isn't perfect...
        
        // handle error
        
    } else {
        // set status to delivered for all matches. Again, there really should
        // only be one match
        [matches enumerateObjectsUsingBlock:^(BBTMessage *message, NSUInteger idx, BOOL *stop) {
            message.status = @(BBTMessageStatusDelivered);
        }];
    }
}


+ (BOOL)existsGroupMessage:(XMPPMessage *)message inRoom:(XMPPJID *)roomJID;
{
    
	NSString *occupantNickname = [[message from] resource];
    NSString *myNickname = [BBTXMPPManager sharedManager].xmppNickname;
    
    if ([occupantNickname isEqualToString:myNickname]) {
        // if this message comes from an occupant with my nickname then it was
        //   an outgoing message from me to the group that's reflected back at me
        //   so it's a duplicate.
        // Note that we check this first as this is important regardless of presence
        //   of a delayed delivery date.
        return YES;
    }
    
	NSDate *remoteTimestamp = [message delayedDeliveryDate];
	
	if (remoteTimestamp == nil)
	{
		// When the xmpp server sends us a room message, it will always timestamp
        //   delayed messages.
		// For example, when retrieving the discussion history, all messages
        //   will include the original timestamp. If a message doesn't include
        //   such timestamp, then we know we're getting it in "real time".
		return NO;
	}
    
    // Does this message already exist in the database?
	// How can we tell if two XMPPRoomMessages are the same?
	//
	// 1. Same body
	// 2. Same sender
	// 3. Approximately the same timestamps
	// 4. Same room
	//
	// This is actually a rather difficult question.
	// What if the same user sends the exact same message multiple times?
	//
	// If we first received the message while already in the room, it won't contain
    //   a remoteTimestamp.
	// Returning to the room later and downloading the discussion history will
	//   return the same message, this time with a remote timestamp.
	//
	// So if the message doesn't have a remoteTimestamp, but it's localTimestamp
	//   is approximately the same as the remoteTimestamp, then this is enough
	//   evidence to consider the messages the same.
	//
	// Note: Predicate order matters. Most unique key should be first, least unique should be last.
	
	NSString *messageBody = [message body];
	NSDate *minLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval:-60];
	NSDate *maxLocalTimestamp = [remoteTimestamp dateByAddingTimeInterval: 60];
    NSString *roomName = [roomJID user];
	
    // Note: Predicate order matters.
    // Most unique key should be first, least unique should be last.
	NSString *predicateFormat = @"    body == %@ "
                                @"AND user ==[c] %@ "
                                @"AND "
                                @"("
                                @"     (remoteTimestamp == %@) "
                                @"  OR (remoteTimestamp == NIL && localTimestamp BETWEEN {%@, %@})"
                                @")"
                                @"AND groupConversation.roomName ==[c] %@";
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat,
                              messageBody,
                              occupantNickname,
                              remoteTimestamp, minLocalTimestamp, maxLocalTimestamp,
                              roomName];
	
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTMessage"];
	[request setPredicate:predicate];
	[request setFetchLimit:1];
    NSManagedObjectContext *moc = [BBTModelManager sharedManager].managedObjectContext;
	NSArray *matches = [moc executeFetchRequest:request error:NULL];
	
	return ([matches count] > 0);
}


#pragma mark - Instance Methods (public)
- (NSAttributedString *)systemMessage
{
    return [[NSAttributedString alloc] initWithString:@"system message"];
}

@end
