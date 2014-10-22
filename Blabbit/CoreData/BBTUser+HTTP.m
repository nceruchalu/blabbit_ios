//
//  BBTUser+HTTP.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/29/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTUser+HTTP.h"
#import "BBTUtilities.h"
#import "BBTHTTPManager.h"
#import "BBTXMPPManager.h"
#import "XMPPUserCoreDataStorageObject+BBTUserModel.h"
#import "BBTMessage+XMPP.h"
#import "XMPPMessage+XEP_0085.h"

@implementation BBTUser (HTTP)

#pragma mark - Class Methods
#pragma mark Private

/**
 * Create a new user
 *
 * @param userDictionary    User object with all attributes from server
 * @param context           handle to database
 */
+ (instancetype)newUserWithUserInfo:(NSDictionary *)userDictionary
             inManagedObjectContext:(NSManagedObjectContext *)context
{
    // if the date formatters isn't already setup, create it and cache for reuse.
    //   It's important to cache formatter for performance as creating it isn't cheap.
    static NSDateFormatter *rfc3339DateFormatter = nil;
    if (!rfc3339DateFormatter) {
        rfc3339DateFormatter = [BBTUtilities generateRFC3339DateFormatter];
    }
    
    // call description incase dictionary values are NULL
    NSString *username = [userDictionary[kBBTRESTUserUsernameKey] description];
    
    NSString *rfc3339LastModifiedString = [userDictionary[kBBTRESTUserLastModifiedKey] description];
    NSDate *lastModified = [rfc3339DateFormatter dateFromString:rfc3339LastModifiedString];
    
    NSString *displayName = [userDictionary[kBBTRESTUserDisplayNameKey] description];
    NSString *avatarThumbnailURL = [userDictionary[kBBTRESTUserAvatarThumbnailKey] description];
    
    BBTUser *newUser = [NSEntityDescription insertNewObjectForEntityForName:@"BBTUser" inManagedObjectContext:context];
    
    newUser.friendship = @(BBTUserFriendshipNone);
    newUser.username = [username lowercaseString];
    newUser.displayName = displayName;
    newUser.avatarThumbnailURL = avatarThumbnailURL;
    newUser.lastModified = lastModified;
    newUser.unreadMessageCount = @(0);
    
    return newUser;
}

/**
 * Update an existing user with a given user object from server
 *
 * @param existingUser      Existing BBTUser object to be updated
 * @param userDictionary    User object with all attributes from server
 * @param context           handle to database
 */
+ (void)syncUser:(BBTUser *)existingUser
            withUserInfo:(NSDictionary *)userDictionary
            inManagedObjectContext:(NSManagedObjectContext *)context
{
    // if the date formatters isn't already setup, create it and cache for reuse.
    //   It's important to cache formatter for performance as creating it isn't cheap.
    static NSDateFormatter *rfc3339DateFormatter = nil;
    if (!rfc3339DateFormatter) {
        rfc3339DateFormatter = [BBTUtilities generateRFC3339DateFormatter];
    }
    
    // get lastModified date which is used for sync
    NSString *rfc3339LastModifiedString = [userDictionary[kBBTRESTUserLastModifiedKey] description];
    NSDate *lastModified = [rfc3339DateFormatter dateFromString:rfc3339LastModifiedString];
    
    // only perform a sync if there are any changes
    if (![lastModified isEqualToDate:existingUser.lastModified]) {
        
        // get properties that will be sync'd
        NSString *displayName = [userDictionary[kBBTRESTUserDisplayNameKey] description];
        NSString *avatarThumbnailURL = [userDictionary[kBBTRESTUserAvatarThumbnailKey] description];
        
        // only change displayname if it changed
        if (![displayName isEqualToString:existingUser.displayName]) {
            existingUser.displayName = displayName;
        }
        
        // only change thumbnail data if thumbnail URL changes
        if (![avatarThumbnailURL isEqualToString:existingUser.avatarThumbnailURL]) {
            existingUser.avatarThumbnailURL = avatarThumbnailURL;
            existingUser.avatarThumbnail = nil;
        }
        
        // finally update lastModified
        existingUser.lastModified = lastModified;
    }
    
    // Not syncing friendship at this time so revert to the ever-safe "Not friends"
    // as sending multiple friend requests causes no harm.
    // Probably want to call checkUsersAgainstRoster: to do the sync at some time.
    existingUser.friendship = @(BBTUserFriendshipNone);
}


#pragma mark Public
+ (instancetype)userWithUserInfo:(NSDictionary *)userDictionary
          inManagedObjectContext:(NSManagedObjectContext *)context
{
    BBTUser *user = nil;
    // get the user object unique identifier
    // call description incase dictionary values are NULL
    NSString *username = [userDictionary[kBBTRESTUserUsernameKey] description];
    
    // first perform a query to determine if object needs to be retrieved or created
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTUser"];
    request.predicate = [NSPredicate predicateWithFormat:@"username ==[c] %@", username];
    // don't need sort descriptors since we expect just 1.
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || ([matches count] > 1)) {
        // handle error
        
    } else if ([matches count] == 0) {
        // couldn't find user in database so create one.
        user = [BBTUser newUserWithUserInfo:userDictionary inManagedObjectContext:context];
        
    } else {
        // only 1 match in DB... so just retrieve
        user = [matches lastObject];
        [BBTUser syncUser:user withUserInfo:userDictionary inManagedObjectContext:context];
    }
    
    return user;
}


+ (NSArray *)usersWithUserInfoArray:(NSArray *)userDicts
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    // BBTUsers (new and existing) based on userDicts
    NSMutableArray *matchedUsers = [NSMutableArray array];
    
    // The strategy here will be to create managed objects for the entire set and
    // weed out (delete) any duplicates using a single large IN predicate.
    //
    // I do need to follow a find-or-create pattern because photo thumbnail data
    // is cached so don't want to throw all that away. So will optimize how I find
    // existing data by reducing to a minimum the number of fetches I execute.
    //
    //
    // First, get the users to parse in sorted order (by username)
    //
    // Note the use of localizedCompare: in both sort descriptors in this
    // method. This is important as without it we get outputs like
    //      sort("nce", "nce2")         -> ["nce",     "nce2"]
    //      sort("nce@lo", "nce2@lo"]   -> ["nce2@lo", "nce@lo"]
    // AND
    //      sort("nce.l", "nce2.l")     -> ["nce.l",    "nce2.l"]
    //      sort("ncE.l", "nCE2.l"]     -> ["nCE2.l",   "ncE.l"]
    //
    // This of course breaks the basic rule of the algorithm below that both arrays
    // have same sort. This is why it's important to specify localizedCompare:
    // sort the passed in list of users
    
    userDicts = [userDicts sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:kBBTRESTUserUsernameKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    NSMutableArray *userDictionaries = [NSMutableArray arrayWithArray:userDicts];
  
    // also get the sorted usernames
    NSMutableArray *usernames = [[NSMutableArray alloc] init];
    for (NSDictionary *userDictionary in userDictionaries) {
        [usernames addObject:[userDictionary[kBBTRESTUserUsernameKey] description]];
    }
    
    // Next, create a predicate using IN with the array of usernames strings,
    // with a sort descriptor which ensures the results are returned with the same
    // sorting as the array of username strings.
    
    // Create the fetch request to get all Users matching the usernames.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"BBTUser" inManagedObjectContext:context]];
    [fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(username IN[c] %@)", usernames]];
    
    // make sure the results are sorted as well with the same sort algo.
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    
    // finally, execute the fetch
    NSError *error;
    NSArray *usersMatchingUsernames = [context executeFetchRequest:fetchRequest error:&error];
    [matchedUsers addObjectsFromArray:usersMatchingUsernames];
    
    // Now we have 2 sorted arrays - one with the users whose usernames were passed
    // into the fetch request, and one with the managed objects that matched them.
    // To process them, you walk through the sorted lists following these steps:
    //   1. Get the next username and User. If the User doesn't match the
    //      User's username, create a new User for that username.
    //   2. Get the next User: if the usernames match, do a data sync then move
    //      to the next username and User
    
    // Create a list of items to be discarded because I'd rather not do
    // book-keeping involved in deleting items while iterating
    NSMutableArray *discardedUserDictionaries = [NSMutableArray array];
    
    // [usersMatchingUsernames count] <= [userDictionaries count] so have
    // outerloop be pulling BBTUsers.
    for (BBTUser *existingUser in usersMatchingUsernames) {
        
        // then get users till there is a match in username
        for (NSDictionary *userDictionary in userDictionaries) {
           // discard of this item now that we are about to analyze it
            [discardedUserDictionaries addObject:userDictionary];
            
            // grab username
            NSString *username = [userDictionary[kBBTRESTUserUsernameKey] description];

            // do we create or update user?
            if ([existingUser.username caseInsensitiveCompare:username] == NSOrderedSame) {
                // this username already exists so do a sync and proceed to getting
                // next user and usernames
                [BBTUser syncUser:existingUser withUserInfo:userDictionary inManagedObjectContext:context];
                break;
                
            } else {
                // create a new user as this username doesn't exist.
                BBTUser *newUser = [BBTUser newUserWithUserInfo:userDictionary inManagedObjectContext:context];
                [matchedUsers addObject:newUser];
            }
        }
        
        // now remove user dictionaries that have already been processed.
        [userDictionaries removeObjectsInArray:discardedUserDictionaries];
    }
    
    // at this point we are done with users already in database but there could
    // still be unmatched userDictionaries so process those here and simply create
    // new users
    for (NSDictionary *userDictionary in userDictionaries) {
        BBTUser *newUser = [BBTUser newUserWithUserInfo:userDictionary
              inManagedObjectContext:context];
        [matchedUsers addObject:newUser];
    }
    
    // return the matched users
    return matchedUsers;
}


/**
 * Update a given list of users' friendship status to indicate not friends, 
 * friends, inbound/outbound friend requests.
 *
 * Not sure about the efficiency of this method so call with caution.
 *
 * @param users array of BBTUser objects to check
 */
+ (void)checkUsersAgainstRoster:(NSArray *)users
{
    // Note the use of localizedCompare: in both sort descriptors. This is
    // important as without it we get outputs like
    //      sort("nce", "nce2")         -> ["nce",     "nce2"]
    //      sort("nce@lo", "nce2@lo"]   -> ["nce2@lo", "nce@lo"]
    // AND
    //      sort("nce.l", "nce2.l")     -> ["nce.l",    "nce2.l"]
    //      sort("ncE.l", "nCE2.l"]     -> ["nCE2.l",   "ncE.l"]
    //
    // This of course breaks the basic rule of the algorithm below that both arrays
    // have same sort. This is why it's important to specify localizedCompare:
    // sort the passed in list of users
    NSArray *sortedUsers = [users sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    NSMutableArray *sortedBBTUsers = [NSMutableArray arrayWithArray:sortedUsers];
    
    // get a sorted list of JIDS of users
    NSMutableArray *userJIDs = [NSMutableArray array];
    for (BBTUser *user in sortedBBTUsers) {
        [userJIDs addObject:user.jidStr];
    }
    
    // Do a single fetch for all XMPPUsers with these usernames
    NSManagedObjectContext *context = [BBTXMPPManager sharedManager].managedObjectContextRoster;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:context]];
    [fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(jidStr IN[cd] %@)", userJIDs]];
    
    // make sure the results are sorted as well with the same sort algo.
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"jidStr" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    
    NSArray *xmppUserMatches = [context executeFetchRequest:fetchRequest error:NULL];
    
    // Create a list of items to be discarded because I'd rather not do
    // book-keeping involved in deleting items while iterating
    NSMutableArray *discardedBBTUsers = [NSMutableArray array];
    
    // [xmppUserMatches count] <= [sortedUsers count] so have
    // outerloop be pulling XMPPUsers.
    for (XMPPUserCoreDataStorageObject *xmppUser in xmppUserMatches) {
       
        // then get BBTUsers till there is a match in username
        for (BBTUser *httpUser in sortedBBTUsers) {
            // discard of this item now that we are about to analyze it
            [discardedBBTUsers addObject:httpUser];
            
            if ([xmppUser.jidStr isEqualToString:[httpUser jidStr]]) {
                // this BBTUser is already in our roster so we will proceed to
                // getting next XMPPUser and BBTUser after checking my
                // relationship with roster user
                
                BOOL isConfirmedFriend = ([xmppUser.subscription isEqualToString:@"both"] ||
                                          ([xmppUser.subscription isEqualToString:@"from"] && ([xmppUser.ask isEqualToString:@"subscribe"])));
                
                BOOL isInboundRequest = [xmppUser.subscription isEqualToString:@"from"] && (xmppUser.ask == nil);
                
                BOOL isOutboundRequest = ([xmppUser.subscription isEqualToString:@"to"] ||
                                          ([xmppUser.subscription isEqualToString:@"none"] && ([xmppUser.ask isEqualToString:@"subscribe"])));

                if (isConfirmedFriend) {
                    httpUser.friendship = @(BBTUserFriendshipBoth);
                    
                } else if (isInboundRequest) {
                    httpUser.friendship = @(BBTUserFriendshipFrom);
                    
                } else if (isOutboundRequest) {
                    httpUser.friendship = @(BBTUserFriendshipTo);
                }
                // there really shouldn't be an else case here
                
                break;
                
            } else {
                // This BBT User is not in our roster
                httpUser.friendship = @(BBTUserFriendshipNone);
            }
        }
        
        // now remove BBTUsers that have already been processed.
        [sortedBBTUsers removeObjectsInArray:discardedBBTUsers];
    }
    
    // at this point we are done with BBTUsers that had matches in the Roster but
    // there could still be unmatched BBTUsers so process those here and simply
    // assume they aren't in the roster
    for (BBTUser *httpUser in sortedBBTUsers) {
        httpUser.friendship = @(BBTUserFriendshipNone);
    }
}


+ (instancetype)conversationWithContact:(XMPPUserCoreDataStorageObject *)contact
                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    BBTUser *conversationContact = nil;
    
    NSString *contactUsername = [contact username];
    if ([contactUsername length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTUser"];
        request.predicate = [NSPredicate predicateWithFormat:@"username ==[c] %@", contactUsername];
        request.fetchBatchSize = 20;
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || [matches count] > 1) {
            // handle error
        } else if ([matches count]) {
            // it exists!
            conversationContact = [matches firstObject];
        } else {
            // create new one
            conversationContact = [NSEntityDescription insertNewObjectForEntityForName:@"BBTUser" inManagedObjectContext:context];
            // populate default values
            conversationContact.unreadMessageCount = @(0);
            conversationContact.friendship = @(BBTUserFriendshipNone);
            conversationContact.username = [contactUsername lowercaseString];
            
            // since conversation is being created, this is a good time to update
            // user with data from webserver
            [conversationContact refreshUserData];
        }
    }
    
    return conversationContact;
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Update user object with data from webserver
 */
- (void)refreshUserData
{
    NSString *userDetailURL = [NSString stringWithFormat:@"%@%@/",kBBTRESTUsers, self.username];
    [[BBTHTTPManager sharedManager] request:BBTHTTPMethodGET
                                     forURL:userDetailURL
                                 parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
     {
         // username is valid, so update appropriate user.
         [BBTUser userWithUserInfo:responseObject inManagedObjectContext:self.managedObjectContext];
     }
                                    failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject)
     {
         // username is invalid, do nothing
         
     }];
}

#pragma mark Public
- (NSString *)jidStr
{
    return [NSString stringWithFormat:@"%@@%@", self.username, kBBTXMPPServer];
}

- (XMPPJID *)jid
{
    return [XMPPJID jidWithString:[self jidStr]];
}

- (NSString *)formattedName
{
    // Title is either vCard's formated name or @<username>
    return [self.displayName length] ? self.displayName : [NSString stringWithFormat:@"@%@",self.username];
}

/**
 * Download and save thumbnail image data of user if there is a download URL
 */
- (void)updateThumbnailImage
{
    if (!self.avatarThumbnail) {
        [[BBTHTTPManager sharedManager] imageFromURL:self.avatarThumbnailURL
                                             success:^(NSURLSessionDataTask *task, id responseObject)
         {
             // update thumbnail-sized avatar image
             if ([responseObject isKindOfClass:[UIImage class]]) {
                 [self.managedObjectContext performBlock:^{
                     self.avatarThumbnail = responseObject;
                 }];
             }
         }
                                             failure:nil];
    }
}


#pragma mark - BBTConversation protocol
- (void)addMessage:(BBTMessage *)message
{
    // add message to contact's messages and set it as last message in conversation
    message.contact = self;
    self.lastMessage = message;
    
    // update number of unread messages
    if (![message.isRead boolValue]) {
        NSUInteger unreadMessageCount = [self.unreadMessageCount unsignedIntegerValue];
        self.unreadMessageCount = @(unreadMessageCount+1);
        
        // now set message as read since this is now being tracked in conversation object
        message.isRead = @(YES);
    }
}


- (void)sendMessageWithBody:(NSString *)messageBody
{
    // Save outgoing message to CoreData and grab the unique identifier
    BBTMessage *message = [BBTMessage outgoingMessage:messageBody
                                       inConversation:self
                               inManagedObjectContext:self.managedObjectContext];
    
    // Create XMPPMessage with an id (for receipt request) and active chat state
    XMPPMessage* xmppMessage = [XMPPMessage messageWithType:@"chat"
                                                         to:[self jid]
                                                  elementID:message.identifier];
    [xmppMessage addBody:messageBody];
    [xmppMessage addActiveChatState];
    
    // Send Message to contact
    [[BBTXMPPManager sharedManager].xmppStream sendElement:xmppMessage];
}


- (void)sendChatState:(BBTChatState)chatState
{
    [[BBTXMPPManager sharedManager] sendChatState:chatState to:self.jidStr];
}

- (void)finishReceivingMessage
{
    self.unreadMessageCount = @(0);
}


@end
