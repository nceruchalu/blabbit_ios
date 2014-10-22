//
//  BBTXMPPManager.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/14/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

@class BBTGroupConversation;

/**
 * A singleton class that manages all XMPP interactions.
 * Having just one instance of this class throughout the application ensures all 
 *   data stays synced.
 */
@interface BBTXMPPManager : NSObject <XMPPRosterDelegate,
                                        XMPPStreamDelegate,
                                        XMPPCapabilitiesDelegate,
                                        XMPPMUCDelegate,
                                        XMPPRoomDelegate,
                                        XMPPvCardTempModuleDelegate>

#pragma mark -  Properties

/**
 * Set if you want to do custom certificate evaluation. Default is NO.
 */
@property (nonatomic, readonly) BOOL customCertEvaluation;

/**
 * Indicator of the current XMPP Stream connection status.
 */
@property (nonatomic, readonly, getter=isXmppConnected) BOOL xmppConnected;

/**
 * The XMPPStream is the base class for all activity.
 *  Everything else plugs into the xmppStream, such as modules/extensions and delegates.
 */
@property (strong, nonatomic, readonly) XMPPStream *xmppStream;

/**
 * The XMPPReconnect module monitors for "accidental disconnections" and
 *   automatically reconnects the stream for you.
 * There's a bunch more information in the XMPPReconnect header file.
 */
@property (strong, nonatomic, readonly) XMPPReconnect *xmppReconnect;

/**
 * The XMPPRoster handles the xmpp protocol stuff related to the roster.
 */
@property (strong, nonatomic, readonly) XMPPRoster *xmppRoster;

/**
 * The storage facility for the XMPPRoster
 */
@property (strong, nonatomic, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;

/**
 * Database handle for Roster CoreData storage facility
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContextRoster;

/**
 * The vCardTempModule handles the user vCards
 */
@property (strong, nonatomic, readonly) XMPPvCardTempModule *xmppvCardTempModule;

/**
 * The vCardAvatarModule is used to download avatars and add to the user vCards.
 * It works in conjunction with the vCardTempModule
 * The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to 
 *   cache roster photos in the roster.
 */
@property (strong, nonatomic, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;

/**
 * The storage facility for the vCardTempModule
 */
@property (strong, nonatomic, readonly) XMPPvCardCoreDataStorage *xmppvCardStorage;

/**
 * The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
 * It is configured to autofetch hashed caps and not autofetch non-hashed caps
 */
@property (strong, nonatomic, readonly) XMPPCapabilities *xmppCapabilities;

/**
 * The storage facility for the XMPPCapabilities module.
 * It can also be shared amongst multiple streams to further reduce hash lookups.
 */
@property (strong, nonatomic, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;

/**
 * Database handle for Capabilities CoreData storage facility
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContextCapabilities;

/**
 * XMPP DeliverReceipts Module is configured to automatically send message 
 *   delivery receipts and requests for chat messages. It follows the 
 *   recommendation to not do so in groupchats.
 */
@property (strong, nonatomic, readonly) XMPPMessageDeliveryReceipts *xmppDeliveryReceipts;

/**
 * XMPPMUC module provides general (but important) tasks related to MUC such as
 *   managing active rooms and listening to room invitations sent from other users.
 */
@property (strong, nonatomic, readonly) XMPPMUC *xmppMUC;

/**
 * The storage facility for the XMPPRoom module.
 */
@property (strong, nonatomic, readonly) XMPPRoomCoreDataStorage *xmppRoomStorage;

/**
 * Database handle for Room CoreData storage facility
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContextRoom;

/**
 * Current XMPPRoom this user is active in
 */
@property (strong, nonatomic, readonly) XMPPRoom *xmppRoom;

/**
 * Nickname to be used for XMPP Groupchats
 */
@property (strong, nonatomic, readonly) NSString *xmppNickname;


#pragma mark - Class Methods
/**
 * Single instance manager. 
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized BBTXMPPManager object.
 */
+ (instancetype)sharedManager;

#pragma mark - Instance Methods
#pragma mark XMPP Stream Management
/**
 * Setup XMPP Stream
 * Here we allocate the xmppStream property and initialize the various 
 * extensions being used in this application.
 */
- (void)setupStream;

/**
 * Tear down XMPP Stream
 * Here we deactivate the various extensions used in the application and
 * disconnect the xmppStream property.
 */
- (void)teardownStream;

/** 
 * Connect to the XMPP Server as an authenticated user.
 * This will use the username/password stored on the device as well as the app's
 * model so ensure all these are setup.
 *
 * @return BOOL indicating app's ability to start connection process.
 */
- (BOOL)connect;

/**
 * Connect to the XMPP Server as an anonymous user. That is use SASL ANONYMOUS.
 * This will use the app's model so ensure this is setup prior to calling this.
 *
 * @return BOOL indicating app's ability to start connection process.
 */
- (BOOL)connectAnonymous;

/**
 * Go offline and disconnect from the XMPP Server.
 */
- (void)disconnect;


#pragma mark Roster Management
/**
 * Adds the given user to the roster. 
 * This will request permission to receive presence information from the user.
 *
 * @param jidString
 *      Bare JID of the user to be added
 */
- (void)sendInvitationToJID:(NSString *)jidString;


#pragma mark Conversation Management
/**
 * Send the given chat state to a contact
 *
 * @param chatState
 *      Chat state to be sent
 * @param jidString
 *      Bare JID of the contact to be messaged
 */
- (void)sendChatState:(BBTChatState)chatState to:(NSString *)jidString;

/**
 * Create a groupchat conversation
 * 
 * @param subject
 *      Groupchat conversation subject
 * @param photo
 *      Groupchat conversation photo
 * @param location
 *      Location to be associated with conversation.
 * @param locationAddress
 *      Reverse-geocoded location address Dictionary using kBBTAddress keys
 * @param users
 *      Users [of type (XMPPUserCoreDataStorageObject *)] that are to be invited to groupchat
 */
- (BBTGroupConversation *)createGroupConversationWithSubject:(NSString *)subject
                                                       photo:(UIImage *)photo
                                                    location:(CLLocation *)location
                                                     address:(NSDictionary *)locationAddress
                                                    invitees:(NSArray *)users;

/**
 * Sync a groupchat conversation with HTTP server after configuring it on XMPP
 * server. This sync sets the conversation's subject, location, photo then sends
 * room invitations.
 *
 * @param conversation: Groupchat conversation that has been configured but is
 *      yet to be sync'd with HTTP server.
 */
- (void)syncGroupConversationAfterConfiguration:(BBTGroupConversation *)conversation;

/**
 * Join an XMPP Room of a specified JID.
 * If XMPP room doesnt exist it will be created so use this with caution.
 * XMPPRoom will be activated, this class will be its delegate, and this room will
 *   be tracked in the xmppRoom property
 *
 * @param roomJIDBare   Bare JID of the room.
 */
- (void)joinGroupConversationWithJID:(NSString *)roomJIDBare;

/**
 * Leave groupchat conversation of given JID (if currently active in the conversation)
 * Leave in this case simply means 'end session'. If you want to stop being a member
 * then use `revokeGroupConversationMembership:andDestroy:`
 *
 * @param roomJID
 *      Bare JID of room to leave if currently active in it
 */
- (void)leaveGroupConversationWithJID:(XMPPJID *)roomJID;

/**
 * Revoke app user's membership in groupchat conversation of given JID and optionally
 * destroy group at the same time. Can only destroy a groupchat if you created it.
 * If destroying a room then membership wont be explicitly revoked as this is implicit
 * in a deletion.
 *
 * @param roomJID
 *      Bare JID of room to revoke
 * @param destroy
 *      BOOL to indicate if the group should also be destroyed
 *
 * @see revokeGroupConversationMembership:andDestroy:withRevokeOnlySuccess:
 */
- (void)revokeGroupConversationMembership:(XMPPJID *)roomJID andDestroy:(BOOL)destroy;

/**
 * Revoke app user's membership in groupchat conversation of given JID and optionally
 * destroy group at the same time. Can only destroy a groupchat if you created it.
 * If destroying a room then membership wont be explicitly revoked as this is implicit
 * in a deletion.
 *
 * @param roomJID
 *      Bare JID of room to revoke
 * @param destroy
 *      BOOL to indicate if the group should also be destroyed
 * @param membershipRevoked
 *      Block to be called when room is not being destroyed and room membership
 *      is successfully revoked.
 */
- (void)revokeGroupConversationMembership:(XMPPJID *)roomJID andDestroy:(BOOL)destroy withRevokeOnlySuccess:(void (^)())membershipRevoked;

/**
 * Invite contacts to an xmppRoom of specified JID
 *
 * @param roomJID   bare JID of room of interest
 * @param contacts  array of XMPPUserCoreDataStorageObject users to be invited
 */
- (void)sendRoomInvitations:(XMPPJID *)roomJID toContacts:(NSArray *)contacts;

@end
