//
//  BBTGroupConversation+XMPP.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/11/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTGroupConversation+XMPP.h"
#import "BBTGroupConversation+CLLocation.h"
#import "BBTUtilities.h"
#import "BBTXMPPManager.h"
#import "BBTMessage+XMPP.h"
#import "BBTHTTPManager.h"

@implementation BBTGroupConversation (XMPP)

#pragma mark - Class Methods
#pragma mark Private
/**
 * Create a new group conversation
 *
 * @param roomDictionary    Room object with all attributes from server
 * @param context           handle to database
 */
+ (instancetype)newGroupConversationWithRoomInfo:(NSDictionary *)roomDictionary
                          inManagedObjectContext:(NSManagedObjectContext *)context
{
    // if the date formatters isn't already setup, create it and cache for reuse.
    //   It's important to cache formatter for performance as creating it isn't cheap.
    static NSDateFormatter *rfc3339DateFormatter = nil;
    if (!rfc3339DateFormatter) {
        rfc3339DateFormatter = [BBTUtilities generateRFC3339DateFormatter];
    }
    
    
    NSString *rfc3339LastModifiedString = [roomDictionary[kBBTRESTRoomLastModifiedKey] description];
    NSDate *lastModified = [rfc3339DateFormatter dateFromString:rfc3339LastModifiedString];
    
    NSString *rfc3339CreationDateString = [roomDictionary[kBBTRESTRoomCreationDateKey] description];
    NSDate *creationDate = [rfc3339DateFormatter dateFromString:rfc3339CreationDateString];
    
    // call description incase dictionary values are NULL
    NSString *roomName = [roomDictionary[kBBTRESTRoomNameKey] description];
    
    NSString *subject = [roomDictionary[kBBTRESTRoomSubjectKey] description];
    NSString *photoThumbnailURL = [roomDictionary[kBBTRESTRoomPhotoThumbnailKey] description];
    NSString *photoURL = [roomDictionary[kBBTRESTRoomPhotoKey] description];
    BOOL isOwner = [[roomDictionary objectForKey:kBBTRESTRoomIsOwnerKey] boolValue];
    
    BBTGroupConversation *newGroupChat = [NSEntityDescription insertNewObjectForEntityForName:@"BBTGroupConversation" inManagedObjectContext:context];
    
    newGroupChat.creationDate = creationDate;
    
    // a groupchat owner is also a member
    newGroupChat.membership = isOwner ? @(BBTGroupConversationMembershipMember) : @(BBTGroupConversationMembershipNone);
    
    newGroupChat.isOwner = @(isOwner);
    newGroupChat.roomName = [roomName lowercaseString];
    newGroupChat.subject = subject;
    newGroupChat.liked = @(NO);
    newGroupChat.likesCount = [roomDictionary objectForKey:kBBTRESTRoomLikesCountKey];
    newGroupChat.photoThumbnailURL = photoThumbnailURL;
    newGroupChat.photoURL = photoURL;
    // photoThumbnail is implicitly set to nil
   
    // groups coming from the server have been created, configured and synced
    newGroupChat.status = @(BBTGroupConversationStatusSynced);
    
    newGroupChat.lastModified = lastModified;
    
    // update location fields
    newGroupChat.location = [BBTGroupConversation locationFromJSON:[roomDictionary objectForKey:kBBTRESTRoomLocationKey]];
    //locationAddress is implicityly set to nil
    
    return newGroupChat;
}


/**
 * Update an existing groupchat with a given room object from server by syncing
 * the following fields:
 *      subject, likesCount, photoThumbnail, photoThumbnailURL, photoURL, status
 *      lastModified, location, locationAddress
 *
 * So following fields are purposely left untouched:
 *      creationDate, membership, isOwner, roomName, liked
 *
 * @param existingConversation  Existing groupchat conversation to be updated
 * @param roomDictionary        Room object with all attributes from server
 * @param context               handle to database
 */
+ (void)syncGroupConversation:(BBTGroupConversation *)existingConversation
                 withRoomInfo:(NSDictionary *)roomDictionary
       inManagedObjectContext:(NSManagedObjectContext *)context
{
    // if the date formatters isn't already setup, create it and cache for reuse.
    //   It's important to cache formatter for performance as creating it isn't cheap.
    static NSDateFormatter *rfc3339DateFormatter = nil;
    if (!rfc3339DateFormatter) {
        rfc3339DateFormatter = [BBTUtilities generateRFC3339DateFormatter];
    }
    
    // get lastModified date which is used for sync
    NSString *rfc3339LastModifiedString = [roomDictionary[kBBTRESTRoomLastModifiedKey] description];
    NSDate *lastModified = [rfc3339DateFormatter dateFromString:rfc3339LastModifiedString];
    
    // only perform a sync if there are any changes
    if (![lastModified isEqualToDate:existingConversation.lastModified]) {
        
        
        NSString *photoThumbnailURL = [roomDictionary[kBBTRESTRoomPhotoThumbnailKey] description];
        
        // only change thumbnail data if thumbnail URL changes
        if (![photoThumbnailURL isEqualToString:existingConversation.photoThumbnailURL]) {
            existingConversation.photoThumbnailURL = photoThumbnailURL;
            existingConversation.photoThumbnail = nil;
        }
        
        // change all other fields as object is about to be made 'dirty' anyways
        // by changing its last modified.
        existingConversation.subject = [roomDictionary[kBBTRESTRoomSubjectKey] description];
        existingConversation.photoURL = [roomDictionary[kBBTRESTRoomPhotoKey] description];
        existingConversation.likesCount = [roomDictionary objectForKey:kBBTRESTRoomLikesCountKey];
        
        // getting data from server means the room is fully configured and synced
        existingConversation.status = @(BBTGroupConversationStatusSynced);
        
        // update location fields if there's a change
        CLLocation *location = [BBTGroupConversation locationFromJSON:[roomDictionary objectForKey:kBBTRESTRoomLocationKey]];
        if ((location.coordinate.longitude != existingConversation.location.coordinate.longitude) ||
            (location.coordinate.latitude != existingConversation.location.coordinate.latitude)) {
            existingConversation.location = location;
            existingConversation.locationAddress = nil; // clear cached value
        }
        
        // finally update lastModified
        existingConversation.lastModified = lastModified;
    }
}

#pragma mark Public
+ (instancetype)groupConversationWithSubject:(NSString *)subject
                                        name:(NSString *)roomName
                                    location:(CLLocation *)location
                                     address:(NSDictionary *)locationAddress
                      inManagedObjectContext:(NSManagedObjectContext *)context
{
    BBTGroupConversation *newGroupChat = [NSEntityDescription insertNewObjectForEntityForName:@"BBTGroupConversation" inManagedObjectContext:context];
    
    newGroupChat.creationDate = [NSDate date];
    // member and owner of group you create
    newGroupChat.membership = @(BBTGroupConversationMembershipMember);
    newGroupChat.isOwner = @(YES);
    newGroupChat.roomName = [roomName lowercaseString];
    newGroupChat.subject = subject;
    newGroupChat.liked = @(NO);
    newGroupChat.likesCount = @(0);
    
    // groups being created start out with a status of none.
    newGroupChat.status = @(BBTGroupConversationStatusNone);
    
    // location attributes
    newGroupChat.location = location;
    newGroupChat.locationAddress = locationAddress;
    
    return newGroupChat;
}


+ (instancetype)groupConversationWithJID:(XMPPJID *)roomJID
                  inManagedObjectContext:(NSManagedObjectContext *)context
{
    BBTGroupConversation *conversation = nil;
    
    NSString *roomName = [roomJID user];
    
    if ([roomName length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTGroupConversation"];
        // have to do a case-insensitive comparison as XMPP server changes cases
        request.predicate = [NSPredicate predicateWithFormat:@"roomName ==[c] %@", roomName];
        request.fetchBatchSize = 20;
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        if (!matches || [matches count] > 1) {
            // handle error
        } else if ([matches count]) {
            // it exists!
            conversation = [matches firstObject];
        } else {
            // doesn't exist so leave conversation as nil.
        }
    }
    
    return conversation;
}


+ (instancetype)groupConversationWithRoomInfo:(NSDictionary *)roomDictionary
                       inManagedObjectContext:(NSManagedObjectContext *)context
{
    BBTGroupConversation *conversation = nil;
    
    // get the room object's unique identifier
    // call description incase dictionary values are NULL
    NSString *roomName = [roomDictionary[kBBTRESTRoomNameKey] description];
    
    // first perform a query to determine if object needs to be retrieved or created
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTGroupConversation"];
    // have to do a case-insensitive comparison as XMPP server changes cases
    request.predicate = [NSPredicate predicateWithFormat:@"roomName ==[c] %@", roomName];
    // don't need sort descriptors since we expect just 1.
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {
        // only 1 match in DB... so just retrieve
        conversation = [matches firstObject];
        [BBTGroupConversation syncGroupConversation:conversation withRoomInfo:roomDictionary inManagedObjectContext:context];
        
    } else {
        // couldn't find conversation in database so create one.
        conversation = [BBTGroupConversation newGroupConversationWithRoomInfo:roomDictionary inManagedObjectContext:context];
    }
    
    return conversation;
}


+ (NSArray *)groupConversationsWithRoomInfoArray:(NSArray *)roomDicts
                          inManagedObjectContext:(NSManagedObjectContext *)context
{
    // BBTGroupConversations (groupchats) (new and existing) based on roomDicts
    NSMutableArray *matchedGroupChats = [NSMutableArray array];
    
    // The strategy here will be to create managed objects for the entire set and
    // weed out (delete) any duplicates using a single large IN predicate.
    //
    // I do need to follow a find-or-create pattern because photo thumbnail data
    // is cached so don't want to throw all that away. So will optimize how I find
    // existing data by reducing to a minimum the number of fetches I execute.
    //
    
    // First, get the rooms to parse in sorted order (by room name)
    roomDicts = [roomDicts sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:kBBTRESTRoomNameKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    NSMutableArray *roomDictionaries = [NSMutableArray arrayWithArray:roomDicts];
    
    // also get the sorted room Names
    NSMutableArray *roomNames = [[NSMutableArray alloc] init];
    for (NSDictionary *roomDictionary in roomDictionaries) {
        NSString *roomName = [roomDictionary[kBBTRESTRoomNameKey] description];
        [roomNames addObject:roomName];
    }
    
    // Next, create a predicate using IN with the array of roomName strings,
    // with a sort descriptor which ensures the results are returned with the same
    // sorting as the array of roomNames/roomDicts.
    
    // Create the fetch request to get all groupchats matching the roomNames.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BBTGroupConversation" inManagedObjectContext:context]];
    [fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(roomName IN[c] %@)", roomNames]];
    
    // make sure the results are sorted as well with the same sort algo.
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"roomName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    
    // finally, execute the fetch
    NSError *error;
    NSArray *groupchatsMatchingRoomNames = [context executeFetchRequest:fetchRequest error:&error];
    [matchedGroupChats addObjectsFromArray:groupchatsMatchingRoomNames];
    
    // Now we have 2 sorted arrays - one with the Room Dictionaries whose names
    // were passed into the fetch request, and one with the BBTGroupConversation
    // groupchat objects that matched them.
    // To process them, you walk through the sorted lists following these steps:
    //   1. Get the next name and groupchat. If the name doesn't match the groupchat's
    //      name, create a new BBTGroupConversation groupchat for that name.
    //   2. Get the next groupchat: if the roomName matches the current room
    //      name, do a data sync then move to the next room name and groupchat
    
    // Create a list of items to be discarded because I'd rather not do
    // book-keeping involved in deleting items while iterating
    NSMutableArray *discardedRoomDictionaries = [NSMutableArray array];
    
    // [groupchatsMatchingRoomNames count] <= [roomDictionaries count] so have
    // outerloop be pulling BBTGroupConversation groupchats
    for (BBTGroupConversation *existingGroupChat in groupchatsMatchingRoomNames) {
        
        // then get room names till there is a match between a dictionary object's
        // room's name and the BBTGroupConversation room name
        for (NSDictionary *roomDictionary in roomDictionaries) {
            // discard of this item now that we are about to analyze it
            [discardedRoomDictionaries addObject:roomDictionary];
            
            // grab room name
            NSString *roomName = [roomDictionary[kBBTRESTRoomNameKey] description];
            
            // do we create or update a groupchat?
            if ([existingGroupChat.roomName caseInsensitiveCompare:roomName] == NSOrderedSame) {
                // this groupchat already exists so do a sync and proceed to getting
                // next groupchat and room name
                [BBTGroupConversation syncGroupConversation:existingGroupChat withRoomInfo:roomDictionary inManagedObjectContext:context];
                break;
                
            } else {
                // create a new groupchat as this room name doesn't exist.
                BBTGroupConversation *newGroupChat = [BBTGroupConversation newGroupConversationWithRoomInfo:roomDictionary inManagedObjectContext:context];
                [matchedGroupChats addObject:newGroupChat];
            }
        }
        
        // now remove room dictionaries that have already been processed.
        [roomDictionaries removeObjectsInArray:discardedRoomDictionaries];
    }
    
    // at this point we are done with groupchats already in database but there
    // could still be unmatched roomDictionaries so process those here and simply
    // create new groupchats
    for (NSDictionary *roomDictionary in roomDictionaries) {
        BBTGroupConversation *newGroupChat =  [BBTGroupConversation newGroupConversationWithRoomInfo:roomDictionary inManagedObjectContext:context];
        [matchedGroupChats addObject:newGroupChat];
    }
    
    // return the matched groupchats
    return matchedGroupChats;
}

+ (NSArray *)removeMembershipOfGroupConversationsNotInRoomInfoArray:(NSArray *)roomDicts
                                             inManagedObjectContext:(NSManagedObjectContext *)context
{
    // Get the room names
    NSMutableArray *roomNames = [[NSMutableArray alloc] init];
    for (NSDictionary *roomDictionary in roomDicts) {
        NSString *roomName = [roomDictionary[kBBTRESTRoomNameKey] description];
        [roomNames addObject:roomName];
    }
    
    // Create the fetch request to get all groupchats not matching the roomNames
    // that user is a member of but doesn't own
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BBTGroupConversation" inManagedObjectContext:context]];
    [fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(NOT (roomName IN[c] %@)) AND (membership == %lu) AND (isOwner == NO)", roomNames, BBTGroupConversationMembershipMember]];
    
    // finally, execute the fetch
    NSError *error;
    NSArray *groupchatsNotMatchingRoomNames = [context executeFetchRequest:fetchRequest error:&error];
    
    // now go in and remove membership from all objects
    for (BBTGroupConversation *groupchat in groupchatsNotMatchingRoomNames) {
        groupchat.membership = @(BBTGroupConversationMembershipNone);
    }
    
    return groupchatsNotMatchingRoomNames;
}

+ (NSString *)jidForRoomName:(NSString *)name
{
    return [NSString stringWithFormat:@"%@@%@", name, kBBTXMPPConferenceServer];
}


#pragma mark - Instance Methods
#pragma mark Public
- (NSString *)jidStr
{
    return [BBTGroupConversation jidForRoomName:self.roomName];
}

- (XMPPJID *)jid
{
    return [XMPPJID jidWithString:[self jidStr]];
}

- (NSTimeInterval)expiryTime
{
    NSTimeInterval timeSinceCreation = -1 * [self.creationDate timeIntervalSinceNow];
    return (kBBTGroupConversationExpiryTime - timeSinceCreation);
}

- (void)revokeMembership
{
    // revoke membership locally. This will be irrelevant if you own the group
    // as it will be deleted. However we do this here so that the groupchat
    // goes out of the table view immediately.
    self.membership = @(BBTGroupConversationMembershipNone);
    
    if ([self.isOwner boolValue]) {
        // if you own group then ensure it was actually created on servers
        // before attempting to delete there. Do this by checking the status is
        // not still BBTGroupConversationStatusNone
        if ([self.status integerValue] == BBTGroupConversationStatusNone) {
            [self deleteAndPostNotification];
            // terminate function now
            return;
        }
    }
    
    // Can only perform server operations if authenticated
    if ([BBTHTTPManager sharedManager].httpAuthenticated) {
        // Revoke room membership on servers and destroy room if you own it
        // Interesting fact is that Whatsapp actually doesn't destroy the room on the
        // servers so if a whatsapp group owner deletes its record of the room all
        // participants can continue the groupchat.
        [[BBTXMPPManager sharedManager] revokeGroupConversationMembership:[self jid]
                                                               andDestroy:[self.isOwner boolValue]];
    }
}

/**
 * If app user is not already a conversation member, grant app user membership
 * of this group conversation locally and on server (if authenticated).
 */
- (void)grantMembership
{
    // only grant membership if not already a conversation member
    if ([self.membership integerValue] != BBTGroupConversationMembershipMember) {
        
        if (![BBTHTTPManager sharedManager].httpAuthenticated) {
            // If not authenticated perform local grant only
            self.membership = @(BBTGroupConversationMembershipMember);
            
        } else {
            // grant membership on server and if that's successful, grant it locally
            NSString *username = [BBTHTTPManager sharedManager].username;
            NSString *roomDetailMemberURL = [BBTHTTPManager roomDetailURL:self.roomName
                                                                   member:username];
            
            [[BBTHTTPManager sharedManager] request:BBTHTTPMethodPOST forURL:roomDetailMemberURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                self.membership = @(BBTGroupConversationMembershipMember);
            } failure:nil];
        }
    }
    
    
}

/**
 * Delete this conversation and post a kBBTConversationDeleteNotification
 * notification for any view controllers currently using it.
 */
- (void)deleteAndPostNotification
{
    // delete this conversation
    [self.managedObjectContext deleteObject:self];
    // Send out a notification incase a View Controller is currently
    //   using this conversation
    [[NSNotificationCenter defaultCenter] postNotificationName:kBBTConversationDeleteNotification
                                                        object:self
                                                      userInfo:@{@"roomName":self.roomName}];
}


#pragma mark - BBTConversation protocol

- (void)addMessage:(BBTMessage *)message
{
    // add message to conversation's messages
    message.groupConversation = self;
    // set message as read since this is irrelevant for groupchats
    message.isRead = @(YES);
}


- (void)sendMessageWithBody:(NSString *)messageBody
{
    // Save outgoing message to CoreData and grab the unique identifier
    BBTMessage *message = [BBTMessage outgoingMessage:messageBody
                                       inConversation:self
                               inManagedObjectContext:self.managedObjectContext];
    
    // Create XMPPMessage with an id (for receipt request) and active chat state
    XMPPMessage* xmppMessage = [XMPPMessage messageWithType:@"groupchat"
                                                         to:[self jid]
                                                  elementID:message.identifier];
    [xmppMessage addBody:messageBody];
    
    // Send Message to contact
    [[BBTXMPPManager sharedManager].xmppStream sendElement:xmppMessage];
}


- (void)sendChatState:(BBTChatState)chatState
{
    // don't send chatstate's for groupchats
    return;
}

- (void)finishReceivingMessage
{
    // nothing to do here
    return;
}

@end
