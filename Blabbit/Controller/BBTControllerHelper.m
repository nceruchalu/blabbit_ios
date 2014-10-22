//
//  BBTControllerHelper.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 8/21/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTControllerHelper.h"
#import "BBTModelManager.h"
#import "BBTXMPPManager.h"
#import <CoreData/CoreData.h>

// Tab Bar item positions [0-indexed]
static const NSUInteger __unused kTabBarIndexChat        = 3;
static const NSUInteger kTabBarIndexExplore     = 0;
static const NSUInteger kTabBarIndexGroups      = 1;
static const NSUInteger kTabBarIndexContacts    = 2;
static const NSUInteger kTabBarIndexSettings    = 3;

@implementation BBTControllerHelper

#pragma mark - Class Methods
#pragma mark - Private
/**
 * Get app's root tab bar controller;
 */
+ (UITabBarController *)rootTabBarController
{
    UITabBarController *rootTabBarController = (UITabBarController *)([[UIApplication sharedApplication].delegate window].rootViewController);
    return rootTabBarController;
}

#pragma mark - Public
/**
 * Get count of group conversations that you've been invited to but have not
 * viewed, i.e BBTGroupConversations with membership of BBTGroupConversationMembershipInvited
 */
+ (NSUInteger)invitedButUnviewedConversationsCount
{
    NSUInteger count = 0;
    
    NSManagedObjectContext *managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;
    if (managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTGroupConversation"];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"membership == %lu", BBTGroupConversationMembershipInvited];
        [request setPredicate:predicate];
        
        count = [managedObjectContext countForFetchRequest:request error:NULL];
    }
    
    return count;
}

/**
 * Get count of incoming friend requests.
 */
+ (NSUInteger)friendRequestsCount
{
    NSUInteger count = 0;
    
    NSManagedObjectContext *managedObjectContext = [[BBTXMPPManager sharedManager] managedObjectContextRoster];
    
    if (managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
        
        // see -[BBTFriendsRosterCDTVC changeContactsList:] for details on why
        // this predicate works
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(subscription == \"from\") AND (ask == nil)"];
        [request setPredicate:predicate];
        
        count = [managedObjectContext countForFetchRequest:request error:NULL];
    }
    
    return count;
}

/**
 * Setup selected images of app's tab bar icon
 */
+ (void)configureTabBarItemsSelectedImages
{
    UITabBarController *tabBarController = [BBTControllerHelper rootTabBarController];
    UITabBar *tabBar = tabBarController.tabBar;
    
    //UITabBarItem *tabBarItemChat = [tabBar.items objectAtIndex:kTabBarIndexChat];
    //tabBarItemChat.selectedImage = [UIImage imageNamed:@"chat-full"];
    
    UITabBarItem *tabBarItemGroups = [tabBar.items objectAtIndex:kTabBarIndexGroups];
    tabBarItemGroups.selectedImage = [UIImage imageNamed:@"threads-full"];
    
    UITabBarItem *tabBarItemExplore = [tabBar.items objectAtIndex:kTabBarIndexExplore];
    tabBarItemExplore.selectedImage = [UIImage imageNamed:@"explore-full"];
    
    UITabBarItem *tabBarItemSettings = [tabBar.items objectAtIndex:kTabBarIndexSettings];
    tabBarItemSettings.selectedImage = [UIImage imageNamed:@"settings-full"];
}

+ (void)updateExploreTabBadge
{
    // only operate if there's a managed object context
    if (![BBTModelManager sharedManager].managedObjectContext) return;
    
    UITabBarController *tabBarController = [BBTControllerHelper rootTabBarController];
    UITabBarItem *tabBarItemExplore = [tabBarController.tabBar.items objectAtIndex:kTabBarIndexExplore];
    
    NSString *badgeValue = nil;
    NSUInteger invitationsCount = [BBTControllerHelper invitedButUnviewedConversationsCount];
    if (invitationsCount) {
        badgeValue = [@(invitationsCount) stringValue];
    }
    
    tabBarItemExplore.badgeValue = badgeValue;
}

+ (void)updateContactsTabBadge
{
    // only operate if there's a managed object context
    if (![BBTXMPPManager sharedManager].managedObjectContextRoster) return;
    
    UITabBarController *tabBarController = [BBTControllerHelper rootTabBarController];
    UITabBarItem *tabBarItemContacts = [tabBarController.tabBar.items objectAtIndex:kTabBarIndexContacts];
    
    NSString *badgeValue = nil;
    NSUInteger friendRequestsCount = [BBTControllerHelper friendRequestsCount];
    if (friendRequestsCount) {
        badgeValue = [@(friendRequestsCount) stringValue];
    }
    
    tabBarItemContacts.badgeValue = badgeValue;
}

+ (void)updateTabsBadges
{
    [BBTControllerHelper updateExploreTabBadge];
    [BBTControllerHelper updateContactsTabBadge];
}

@end
