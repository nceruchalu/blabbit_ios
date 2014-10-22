//
//  BBTControllerHelper.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 8/21/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Helper class methods that relate to the View Controllers
 */
@interface BBTControllerHelper : NSObject

/**
 * Get count of group conversations that you've been invited to but have not
 * viewed, i.e BBTGroupConversations with membership of BBTGroupConversationMembershipInvited
 */
+ (NSUInteger)invitedButUnviewedConversationsCount;

/**
 * Get count of incoming friend requests.
 */
+ (NSUInteger)friendRequestsCount;

/**
 * Setup selected images of app's tab bar icon
 */
+ (void)configureTabBarItemsSelectedImages;

/**
 * Update the badge for the explore tab bar item to show number of conversations
 * that you've been invited to but have not viewed, i.e BBTGroupConversations 
 * with membership of BBTGroupConversationMembershipInvited
 */
+ (void)updateExploreTabBadge;

/**
 * Update the badge for the contacts tab bar item to show number of pending friend
 * requests
 */
+ (void)updateContactsTabBadge;

/**
 * Update the badgs for all tabs.
 */
+ (void)updateTabsBadges;

@end
