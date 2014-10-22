//
//  BBTConstants.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTConstants.h"

// Input borders
const CGFloat kInputBorderThickness         = 1.0f;

// Application Settings
NSString *const kBBTSettingsSounds          = @"kBBTSettingsSounds";
const NSTimeInterval kBBTGroupConversationExpiryTime        = 86400; // 24 hours
const NSTimeInterval kBBTGroupConversationDeleteInterval    = 300;   // 5 minutes
const NSTimeInterval kBBTGroupConversationMaxCreatedTime    = 300;   // 5 minutes
const NSTimeInterval kBBTGroupConversationMaxConfiguredTime = 120;   // 2 minutes

// XMPP and HTTP Connection Info
#if DEBUG
NSString *const kBBTXMPPServer              = @"10.0.0.2";
NSString *const kBBTXMPPConferenceServer    = @"conference.10.0.0.2";
NSString *const kBBTHTTPBaseURL             = @"http://10.0.0.2:8000/api/v1/";
#else
NSString *const kBBTXMPPServer              = @"blabb.it";
NSString *const kBBTXMPPConferenceServer    = @"conference.blabb.it";
NSString *const kBBTHTTPBaseURL             = @"http://blabb.it/api/v1/";
#endif

// XMPP Connection resource base
NSString *const kBBTXMPPResource            = @"blabbit";

// XMPP Authentication attempts
const NSUInteger kBBTXMPPAuthenticationRetryMaxAttempts = 2;


NSString *const kBBTRESTListResultsKey      = @"results";

// REST API HTTP relative paths (observe no leading slash)
NSString *const kBBTRESTUsers               = @"users/";
NSString *const kBBTRESTUser                = @"user/";
NSString *const kBBTRESTUserContacts        = @"user/contacts/";
NSString *const kBBTRESTUserRooms           = @"user/rooms/";
NSString *const kBBTRESTObtainAuthToken     = @"account/auth/token/";
NSString *const kBBTRESTPasswordChange      = @"account/password/change/";
NSString *const kBBTRESTPasswordReset       = @"account/password/reset/";
NSString *const kBBTRESTFeedbacks           = @"feedbacks/";
NSString *const kBBTRESTSearchUsers         = @"search/users/";
NSString *const kBBTRESTSearchRooms         = @"search/rooms/";
NSString *const kBBTRESTRooms               = @"rooms/";
NSString *const kBBTRESTRoomMembers         = @"members/";
NSString *const kBBTRESTRoomLikes           = @"likes/";
NSString *const kBBTRESTRoomFlag            = @"flag/";
NSString *const kBBTRESTExplorePopular      = @"explore/popular/";

// REST API KEYS
// User object
NSString *const kBBTRESTUserUsernameKey         = @"username";
NSString *const kBBTRESTUserPasswordKey         = @"password";
NSString *const kBBTRESTUserDisplayNameKey      = @"first_name";
NSString *const kBBTRESTUserAvatarKey           = @"avatar";
NSString *const kBBTRESTUserAvatarThumbnailKey  = @"avatar_thumbnail";
NSString *const kBBTRESTUserLastModifiedKey     = @"last_modified";
NSString *const kBBTRESTUserEmailKey            = @"email";

// User password change fields
NSString *const kBBTRESTPasswordChangeOldKey    = @"old_password";
NSString *const kBBTRESTPasswordChangeNewKey    = @"new_password1";
NSString *const kBBTRESTPasswordChangeConfirmKey= @"new_password2";

// Feedback object
NSString *const kBBTRESTFeedbackBodyKey         = @"body";

// Search Query
NSString *const kBBTRESTSearchQueryKey          = @"q";

// Room object
NSString *const kBBTRESTRoomNameKey             = @"name";
NSString *const kBBTRESTRoomSubjectKey          = @"subject";
NSString *const kBBTRESTRoomIsOwnerKey          = @"is_owner";
NSString *const kBBTRESTRoomPhotoKey            = @"photo";
NSString *const kBBTRESTRoomPhotoThumbnailKey   = @"photo_thumbnail";
NSString *const kBBTRESTRoomLikesCountKey       = @"likes_count";
NSString *const kBBTRESTRoomCreationDateKey     = @"created_at";
NSString *const kBBTRESTRoomLastModifiedKey     = @"last_modified";
NSString *const kBBTRESTRoomLocationKey         = @"location";
NSString *const kBBTRESTRoomLocationCoordinatesKey = @"coordinates";

// Room like update result key
NSString *const kBBTRESTRoomLikeResultKey       = @"detail";


// Address dictionary keys
NSString *const kBBTAddressCityKey              = @"kBBTAddressCityKey";
NSString *const kBBTAddressStateKey             = @"kBBTAddressStateKey";
NSString *const kBBTAddressCountryKey           = @"kBBTAddressCountryKey";

// User Credentials
NSString *const kBBTLoginKeychainIdentifier     = @"BlabbitLoginData";
const NSUInteger kBBTMinUsernameLength          = 3;
const NSUInteger kBBTMinPasswordLength          = 4;

// Location Settings
const CLLocationAccuracy kBBTLocationAccuracyThreshold  = 100.0;
const NSUInteger kBBTLocationAttemptsMax                = 4;
const NSTimeInterval kBBTLocationUpdateExpiryTime       = 5.0;
const NSTimeInterval kBBTLocationUpdateBetterWaitTime   = 5.0;
const NSTimeInterval kBBTLocationUpdateFirstWaitTime    = 30.0;

// Notifications
NSString *const kBBTMOCAvailableNotification        = @"kBBTMOCAvailableNotification";
NSString *const kBBTMOCDeletedNotification          = @"kBBTMOCDeletedNotification";
NSString *const kBBTChatStateNotification           = @"kBBTChatStateNotification";
NSString *const kBBTMessageNotification             = @"kBBTMessageNotification";
NSString *const kBBTConversationDeleteNotification  = @"kBBTConversationDeleteNotification";
NSString *const kBBTConversationSyncNotification    = @"kBBTConversationSyncNotification";
NSString *const kBBTConversationJoinNotification    = @"kBBTConversationJoinNotification";
NSString *const kBBTConversationsUpdateNotification = @"kBBTConversationsUpdateNotification";
NSString *const kBBTRosterUpdateNotification        = @"kBBTRosterUpdateNotification";
NSString *const kBBTAuthenticationNotification      = @"kBBTAuthenticationNotification";

// Application Error Strings
NSString *const kBBTErrorMsgLocationDisabled     = @"You have to enable your location in your device settings to add a location to your thread and see other nearby threads.";
