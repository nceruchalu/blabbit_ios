//
//  BBTConstants.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//
//  Place file in precompiled header for the project

#import <CoreLocation/CoreLocation.h>

// Colors
/**
 * Theme Color is RGB #FF9500
 */
#define kBBTThemeColor [UIColor colorWithRed:255.0/255.0 green:149.0/255.0 blue:0.0/255.0 alpha:1.0]

/**
 * Dark Green Color
 */
#define kBBTDarkGreenColor [UIColor colorWithRed:78.0/255.0 green:130.0/255.0 blue:31.0/255.0 alpha:1.0]

// Input field Borders
/**
 * Input field border color
 */
#define kInputBorderColor [UIColor colorWithRed:212.0/255.0 green:212.0/255.0 blue:212.0/255.0 alpha:1.0]

// Light Gray Border color (nice against Group Table View background color)
// This is same value as that used for UITableViewCell borders
#define kBBTLightGrayBorderColor [UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1.0]

/**
 * kInputBorderThickness is the height/width of input borders
 */
extern const CGFloat kInputBorderThickness;


// Application Settings
/**
 * kBBTSettingsSounds is the key for NSUserDefaults setting on whether app makes
 * sounds or not
 */
extern NSString *const kBBTSettingsSounds;

/**
 * We don't want the message history to persist forever.
 * Doing so would allow the database to grow infinitely large over time.
 * For this reason the group conversations are ephemeral.
 *
 * kBBTGroupConversationExpiryTime specifies how old a group conversation can
 * get before it should get deleted from the database. This defaults to 24 hours
 *
 * kBBTGroupConversationDeleteInterval specifies how often to sweep for expired
 * group conversations. This defaults to 5 minutes.
 * Since deleting is an expensive operation (disk io) it is done on a fixed 
 * interval.
 **/
extern const NSTimeInterval kBBTGroupConversationExpiryTime;
extern const NSTimeInterval kBBTGroupConversationDeleteInterval;

/**
 * The BBTGroupConversation creation process is multi-step in that it requires
 * XMPP Creation, XMPP Configuration, HTTP Syncing. More steps means more possible
 * failure points so limits are set for how long a conversation can stay in a 
 * state before we consider the conversation stuck there.
 * 
 * kBBTGroupConversationMaxCreatedTime is the maximum time a conversation can be
 * in a state of "created" (BBTGroupConversationStatusCreated).
 *
 * kBBTGroupConversationMaxConfiguredTime is the maximum time a conversation can
 * be in a state of  "configured" (BBTGroupConversationStatusConfigured).
 */
extern const NSTimeInterval kBBTGroupConversationMaxCreatedTime;
extern const NSTimeInterval kBBTGroupConversationMaxConfiguredTime;


// XMPP Connection info.
/**
 * kBBTXMPPServer is the XMPP Server domain hostname
 */
extern NSString *const kBBTXMPPServer;

/**
 * kBBTXMPPConferenceServer is the XMPP Conference Server domain hostname
 */
extern NSString *const kBBTXMPPConferenceServer;

/**
 * kBBTXMPPResource is the base string to use for client resource strings
 * It will be appended with random numbers to vary the client resource identifers
 */
extern NSString *const kBBTXMPPResource;

/**
 * kBBTXMPPAuthenticationRetryMaxAttempts is the maximum number of authentication
 * retry attempts after auth failure.
 * Keep this between 2 and 5 for sake of being reasonable.
 */
extern const NSUInteger kBBTXMPPAuthenticationRetryMaxAttempts;


// HTTP Connection info.
/**
 * kBBTHTTPBaseURL is the base URL of the server's REST API.
 */
extern NSString *const kBBTHTTPBaseURL;

/**
 * key for results when REST API returns a list
 */
extern NSString *const kBBTRESTListResultsKey;


// REST API HTTP paths
/**
 * kBBTRESTUsers: URL for List of all users.
 */
extern NSString *const kBBTRESTUsers;

/**
 * kBBTRESTUser: URL for Details of authenticated user
 */
extern NSString *const kBBTRESTUser;

/**
 * kBBTRESTUserContacts: URL for contacts of authenticated user
 */
extern NSString *const kBBTRESTUserContacts;

/**
 * kBBTRESTUserRooms: URL for rooms that authenticated user is a member of
 */
extern NSString *const kBBTRESTUserRooms;

/**
 * kBBTRESTObtainAuthToken: URL to retrieve authentication path for a given
 * username and password
 */
extern NSString *const kBBTRESTObtainAuthToken;

/***
 * kBBTRESTPasswordChange : URL for requesting a password change.
 */
extern NSString *const kBBTRESTPasswordChange;

/**
 * kBBTRESTPasswordReset: URL for requesting a password reset.
 */
extern NSString *const kBBTRESTPasswordReset;

/**
 * kBBTRESTFeedbacks: URL for submitting feedback
 */
extern NSString *const kBBTRESTFeedbacks;

/**
 * kBBTRESTSearchUsers: URL for searching users.
 */
extern NSString *const kBBTRESTSearchUsers;

/**
 * kBBTRESTSearchRooms: URL for searching rooms.
 */
extern NSString *const kBBTRESTSearchRooms;

/**
 * kBBTRESTRooms: URL for list of all rooms
 */
extern NSString *const kBBTRESTRooms;

/**
 * kBBTRESTRoomMembers: URL for members sub-list of a specific room
 */
extern NSString *const kBBTRESTRoomMembers;

/**
 * kBBTRESTRoomLikes: URL for likers sub-list of a specific room
 */
extern NSString *const kBBTRESTRoomLikes;

/**
 * kBBTRESTRoomFlag: URL for flagging a specific room
 */
extern NSString *const kBBTRESTRoomFlag;

/**
 * kBBTRESTExplorePopular: URL for list of popular rooms
 */
extern NSString *const kBBTRESTExplorePopular;

/**
 * REST API KEYS
 * Keys in the object dictionaries used by the server's REST API
 */
// User object
extern NSString *const kBBTRESTUserUsernameKey;
extern NSString *const kBBTRESTUserPasswordKey;
extern NSString *const kBBTRESTUserDisplayNameKey;
extern NSString *const kBBTRESTUserAvatarKey;
extern NSString *const kBBTRESTUserAvatarThumbnailKey;
extern NSString *const kBBTRESTUserLastModifiedKey;
extern NSString *const kBBTRESTUserEmailKey;

// User password change fields
extern NSString *const kBBTRESTPasswordChangeOldKey;
extern NSString *const kBBTRESTPasswordChangeNewKey;
extern NSString *const kBBTRESTPasswordChangeConfirmKey;

// Feedback object
extern NSString *const kBBTRESTFeedbackBodyKey;

// Search Query
extern NSString *const kBBTRESTSearchQueryKey;

// Room object
extern NSString *const kBBTRESTRoomNameKey;
extern NSString *const kBBTRESTRoomSubjectKey;
extern NSString *const kBBTRESTRoomIsOwnerKey;
extern NSString *const kBBTRESTRoomPhotoKey;
extern NSString *const kBBTRESTRoomPhotoThumbnailKey;
extern NSString *const kBBTRESTRoomLikesCountKey;
extern NSString *const kBBTRESTRoomCreationDateKey;
extern NSString *const kBBTRESTRoomLastModifiedKey;
extern NSString *const kBBTRESTRoomLocationKey;
// key for coordinates array in location dictionary
extern NSString *const kBBTRESTRoomLocationCoordinatesKey;

// Room Like update response result key
extern NSString *const kBBTRESTRoomLikeResultKey;


// Address dictionary keys
extern NSString *const kBBTAddressCityKey;
extern NSString *const kBBTAddressStateKey;
extern NSString *const kBBTAddressCountryKey;

// User Credentials

/**
 * kBBTLoginKeychainIdentifier is the KeychainItemWrapper identifier
 */
extern NSString *const kBBTLoginKeychainIdentifier;

/**
 * kBBTMinUsernameLength is the minimum username length
 */
extern const NSUInteger kBBTMinUsernameLength;

/**
 * kBBTMinPasswordLength is the minimum password length
 */
extern const NSUInteger kBBTMinPasswordLength;


// Location Settings
/**
 * kBBTLocationAccuracyThreshold is the upper bound of the accuracy values below
 * which a location update is deemed good enough.
 * If possible make this > 10;
 */
extern const CLLocationAccuracy kBBTLocationAccuracyThreshold;

/**
 * kBBTLocationAttemptsMax is the maximum number of attempts we can make when
 * trying to get an accurate location.
 * This value really should be something <= 10. Anything more is asking
 * for a really slow location determination. Here are some statistics to aid in
 * choosing this value:
 *  location accuracy    max number of attempts
 *  ~1000                2
 *  ~100                 4
 *  50                   6
 *  10                   8
 *  5                    10
 */
extern const NSUInteger kBBTLocationAttemptsMax;

/**
 * kBBTLocationUpdateExpiryTime is the maximum age of location update that can be
 * considered valid. The smaller this value the more sensitive we are to location
 * changes.
 * If you get a location update that falls within this expiry
 * time window, turn off updates to save power.
 */
extern const NSTimeInterval kBBTLocationUpdateExpiryTime;

/**
 * kBBTLocationUpdateBetterWaitTime is the maximum wait time (in seconds) after
 * getting a location update that we hold off for a better location update.
 * If we don't get a better update in this time window we end operations and
 * take the best location so far..
 */
extern const NSTimeInterval kBBTLocationUpdateBetterWaitTime;

/**
 * kBBTLocationUpdateFirstWaitTime is the maximum wait (in seconds) for getting first
 * location update.
 */
extern const NSTimeInterval kBBTLocationUpdateFirstWaitTime;


// Notifications

/**
 * NSNotification identifier for Blabbit's managedObjectContext availability
 */
extern NSString *const kBBTMOCAvailableNotification;

/**
 * NSNotification identifier for Blabbit's managedObjectContext removal. This
 * happens on signout
 */
extern NSString *const kBBTMOCDeletedNotification;

/**
 * NSNotification identifier for new Chat State received from a contact
 */
extern NSString *const kBBTChatStateNotification;

/**
 * NSNotification identifier for new chat/groupchat Message received from a contact
 */
extern NSString *const kBBTMessageNotification;

/**
 * NSNotification identifier for deleted (groupchat) conversation
 */
extern NSString *const kBBTConversationDeleteNotification;

/**
 * NSNotification identifier for (groupchat) conversation sync with HTTP server.
 * This happens shortly after conversation creation.
 */
extern NSString *const kBBTConversationSyncNotification;

/**
 * NSNotification identifier for joining a groupchat conversation
 */
extern NSString *const kBBTConversationJoinNotification;

/**
 * NSNotification identifier for changes it to current list of conversations.
 * This is used for checking for and showing appropriate badges on view elements.
 */
extern NSString *const kBBTConversationsUpdateNotification;

/**
 * NSNotification identifier for changes to xmpp roster
 * This is used for checking for and showing appropriate badges on view elements.
 */
extern NSString *const kBBTRosterUpdateNotification;

/**
 * NSNotification identifier for change in XMPP Authentication status
 */
extern NSString *const kBBTAuthenticationNotification;

// Application Error Strings
/**
 * kBBTErrorMsgLocationDisabled is the error message shown when location services are disabled
 */
extern NSString *const kBBTErrorMsgLocationDisabled;


// Typedefs

/**
 * Chat States
 * Each state is purposely given an integer value because it is important
 *   that we mimic what we receive from the XMPPFramework.
 */
typedef enum : NSUInteger {
    BBTChatStateUnknown   = 0,
    BBTChatStateActive    = 1,
    BBTChatStateComposing = 2,
    BBTChatStatePaused    = 3,
    BBTChatStateInactive  = 4,
    BBTChatStateGone      = 5
} BBTChatState;

/**
 * System Message Type codes
 */
typedef enum : NSUInteger {
    BBTSystemEventChangedSubject = 0,
    BBTSystemEventJoinedRoom,
    BBTSystemEventLeftRoom
} BBTSystemEvent;

/**
 * Chat/Groupchat Message status codes
 */
typedef enum : NSUInteger {
    BBTMessageStatusSending = 0,
    BBTMessageStatusSent,
    BBTMessageStatusFailed,
    BBTMessageStatusDelivered
} BBTMessageStatus;

/**
 * Friendship/Relationship with Blabbit Users
 */
typedef enum : NSUInteger {
    BBTUserFriendshipNone = 0,  // Not friends at all
    BBTUserFriendshipBoth,      // 2 way friendship
    BBTUserFriendshipFrom,      // incoming friend request from user
    BBTUserFriendshipTo         // sent friend request to user
} BBTUserFriendship;

/**
 * Membership status in Groupchat conversation (Room)
 */
typedef enum : NSUInteger {
    BBTGroupConversationMembershipNone = 0,     // Neither room member nor invitee
    BBTGroupConversationMembershipMember,       // Member of a room
    BBTGroupConversationMembershipInvited,      // Invited to a room
    BBTGroupConversationMembershipInvitedViewed // Viewed invitation's details but
                                                // haven't ignored or accepted
    
} BBTGroupConversationMembership;

/**
 * Groupchat conversation (Room) status codes
 */
typedef enum : NSUInteger {
    BBTGroupConversationStatusNone = 0,     // Room we own has been instantiated in Core Data
    BBTGroupConversationStatusCreated,      // Room created on XMPP server
    BBTGroupConversationStatusConfigured,   // Room created and configured on XMPP server
    BBTGroupConversationStatusSynced        // Details (subject, photo) set on HTTP server
} BBTGroupConversationStatus;

/**
 * HTTP Methods: GET/POST/PUT/DELETE
 */
typedef enum : NSUInteger {
    BBTHTTPMethodGET = 0,
    BBTHTTPMethodPOST,
    BBTHTTPMethodPUT,
    BBTHTTPMethodPATCH,
    BBTHTTPMethodDELETE
} BBTHTTPMethod;






