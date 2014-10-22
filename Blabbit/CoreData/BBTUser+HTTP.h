//
//  BBTUser+HTTP.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/29/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTUser.h"
#import "BBTConversation.h"

@class XMPPJID;
@class BBTMessage;
@class XMPPUserCoreDataStorageObject;

@interface BBTUser (HTTP) <BBTConversation>

/**
 *  Using this file as a location to document the BBTUser model which is what
 *  the 1-on-1 chat messages are linked with. For this reason a BBTUser is also
 *  a BBTConversation. I possibly could have called this model BBTContactConversation
 *  but this name is clearer.
 *
 *  Property            Purpose
 *  username            User's unique identifier on server
 *  displayName         User's display name
 *  avatarThumbnailURL  URL where thumbnail image can be downloaded
 *  avatarThumbnail     cached thumbnail image
 *  friendship          user's relationship with app user (periodically sync'd with Roster)
  * unreadMessageCount  Number of messages sent by user that have isRead == NO
 *  lastModified        this attribute will automatically be updated with the
 *                        current date and time by the server whenever anything
 *                        changes on a User record. It is used for sync purposes
 *
 *  @see http://stackoverflow.com/a/5052208 for more on lastModified
 */

/**
 * Find-or-Create a user object
 *
 * @param userDictionary    User object with all attributes from server
 * @param context           handle to database
 *
 * @return Initialized BBTUser instance
 */
+ (instancetype)userWithUserInfo:(NSDictionary *)userDictionary
          inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a batch of user objects.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param userDicts         Array of userDictionary objects, where each contains
 *                          JSON data as expected from server.
 * @param context           handle to database
 *
 * @return Initiailized BBTUser instances (of course based on passed in userDicts)
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)usersWithUserInfoArray:(NSArray *)userDicts
   inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Update a given list of users' friendship statuses by comparing to same users
 * in your roster.
 *
 * Not sure about the efficiency of this method so call with caution.
 *
 * @param users array of BBTUser objects to check
 */
+ (void)checkUsersAgainstRoster:(NSArray *)users;


/**
 * Find-or-Create User to be used for a chat conversation with provided contact
 *
 * @param contact   XMPPRoster user object
 * @param context   handle to Chats database
 *
 * @return Initialized BBTConversation instance
 */
+ (instancetype)conversationWithContact:(XMPPUserCoreDataStorageObject *)contact
                 inManagedObjectContext:(NSManagedObjectContext *)context;


/**
 * Compose a JID string for this user, i.e. of the form <username>@<xmpp-server>
 */
- (NSString *)jidStr;

/**
 * Compose an XMPPJID string for this user where Bare JID string is of the form
 * <username>@<xmpp-server>
 */
- (XMPPJID *)jid;

/**
 * Formatted Name of user. Really just a better displayName
 */
- (NSString *)formattedName;

/**
 * Download thumbnail image data of user if there is a download URL
 */
- (void)updateThumbnailImage;

@end
