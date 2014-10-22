//
//  BBTTabBarController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 8/23/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTTabBarController.h"
#import "BBTControllerHelper.h"
#import "BBTModelManager.h"

@interface BBTTabBarController ()

@end

@implementation BBTTabBarController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Setup tabBar icons
    [BBTControllerHelper configureTabBarItemsSelectedImages];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Attempt updating the tab bar items' badges
    if ([BBTModelManager sharedManager].managedObjectContext) {
        [BBTControllerHelper updateTabsBadges];
    }
    
    // Add Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextReady:)
                                                 name:kBBTMOCAvailableNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(conversationsUpdated:)
                                                 name:kBBTConversationsUpdateNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rosterUpdated:)
                                                 name:kBBTRosterUpdateNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTMOCAvailableNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTConversationsUpdateNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTRosterUpdateNotification
                                                  object:nil];
    
}

#pragma mark - Notification Observer Methods
/**
 * ManagedObjectContext now available from BBTModelManager so update tab bars 
 * items' badges
 */
- (void)managedObjectContextReady:(NSNotification *)aNotification
{
    [BBTControllerHelper updateTabsBadges];
}

/**
 *  Selection of conversations updated so update explore tab bar badge.
 */
- (void)conversationsUpdated:(NSNotification *)aNotification
{
    [BBTControllerHelper updateExploreTabBadge];
}

/**
 * XMPP Roster now updated so update explore contacts tab bar badge
 */
- (void)rosterUpdated:(NSNotification *)aNotification
{
    [BBTControllerHelper updateContactsTabBadge];
}


@end
