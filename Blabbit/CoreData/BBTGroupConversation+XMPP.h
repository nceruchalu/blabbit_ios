//
//  BBTGroupConversation+XMPP.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/11/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//
/*
 *  Using this file as a location to document the BBTGroupConversation model
 *  which represents groupchat threads.
 *
 *  Property            Purpose
 *  creationDate        Creation date of conversation.
 *  membership          Am I a member/invited to this groupchat?
 *  isOwner             Am I the owner of this groupchat?
 *  roomName            Unique identifier and localpart of the room's bare JID
 *  subject             Groupchat conversation subject
 *  liked               Has app user liked this groupchat?
 *  likesCount          Number of likes this thread has received
 *  photoThumbnail      (UIImage *) cached thumbnail of room's photo
 *  photoThumbnailURL   URL where room photo thumbnail image can be downloaded
 *  photoURL            URL where full-size room photo image can be downloaded
 *  status              Code indicating groupconversation creation/readiness status
 *  lastModified        this attribute will automatically be updated with the
 *                        current date and time by the server whenever anything
 *                        changes on a BBTConversation record. It is used for sync 
 *                        purposes
 *
 *  @see http://stackoverflow.com/a/5052208 for more on lastModified
 */

#import "BBTGroupConversation.h"
#import "BBTConversation.h"

@class XMPPJID;

@interface BBTGroupConversation (XMPP) <BBTConversation>

#pragma mark - Class Methods
/**
 * Create groupchat conversation with provided attributes.
 * Since we are creating the app user is both a member and an owner
 *
 * @param subject           conversation subject
 * @param roomName          name of groupchat's room
 * @param location          location to be associated with conversation.
 * @param locationAddress   reverse-geocoded location address Dictionary using
 *                          kBBTAddress keys
 * @param context           handle to Chats database
 *
 * @return Initialized BBTConversation instance
 */
+ (instancetype)groupConversationWithSubject:(NSString *)subject
                                        name:(NSString *)roomName
                                    location:(CLLocation *)location
                                     address:(NSDictionary *)locationAddress
                      inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find groupchat conversation for given roomJID.
 *
 * @param roomJID   bare JID of groupchat's room
 * @param context   handle to Chats database
 *
 * @return Initialized BBTConversation instance or nil if room doesn't exist
 */
+ (instancetype)groupConversationWithJID:(XMPPJID *)roomJID
                  inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a groupchat conversation object using a JSON object from HTTP server.
 *
 * @param roomDictionary    JSON Room object with all attributes from webserver
 * @param context           handle to database
 *
 * @return Initialized BBTConversation instance
 */
+ (instancetype)groupConversationWithRoomInfo:(NSDictionary *)roomDictionary
                       inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a batch of groupchat conversation objects from HTTP server.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param roomDicts         Array of roomDictionary objects, where each contains
 *                          JSON data as expected from webserver.
 * @param context           handle to database
 *
 * @return Initiailized BBTConversation instances (of course based on passed in roomDicts)
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)groupConversationsWithRoomInfoArray:(NSArray *)roomDicts
                          inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Remove app user as a member of the groupchat conversation objects not in an 
 * array of room JSON objects. This only operates on groupchats that you don't own
 * but are a member of, i.e. it leaves "invited" rooms untouched.
 *
 * @param roomDicts         Array of roomDictionary objects, where each contains
 *                          JSON data as expected from webserver.
 * @param context           handle to database
 *
 * @return the groupchat conversations that you had membership revoked from
 *
 * @ref http://stackoverflow.com/a/1383645
 */
+ (NSArray *)removeMembershipOfGroupConversationsNotInRoomInfoArray:(NSArray *)roomDicts
                                        inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Get the roomJID for a given room name
 * This creates a jid of the form <room name>@<XMPP Conference Server Domain>
 *
 * @param name  Room name of interest
 *
 * @return the roomJID
 */
+ (NSString *)jidForRoomName:(NSString *)name;


#pragma mark - Instance Methods
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
 * Time interval left before room expires.
 */
- (NSTimeInterval)expiryTime;

/**
 * Revoke app user's membership from this group locally and on server (if 
 * authenticated).
 * If the app user owns the group then delete the group as well.
 */
- (void)revokeMembership;

/**
 * If app user is not already a conversation member, grant app user membership 
 * of this group conversation locally and on server (if authenticated).
 */
- (void)grantMembership;


/**
 * Delete this conversation and post a kBBTConversationDeleteNotification 
 * notification for any view controllers currently using it.
 */
- (void)deleteAndPostNotification;

@end
