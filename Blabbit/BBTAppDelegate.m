//
//  BBTAppDelegate.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/22/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTAppDelegate.h"
#import "BBTHTTPManager.h"
#import "BBTXMPPManager.h"


@implementation BBTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // set appearance of views
    [[UITabBar appearance] setTintColor:kBBTThemeColor];
    
    // Setup the XMPP stream
    [[BBTXMPPManager sharedManager] setupStream];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Perform setup and authentication here each time the application becomes
    // active. The reason for doing this is that the XMPP stream connection could
    // go bad while an app is in background/suspended state. So this ensures
    // app is useful when in an active state.
    // Probably not the best to show the Sign In VC. Maybe a "Loading Data" VC
    // would be better. That's a task for a later day.
    
    // Setup the XMPP stream if not already setup
    [[BBTXMPPManager sharedManager] setupStream];
    
    // Authenticate the user if necessary.
    if (![[BBTXMPPManager sharedManager].xmppStream isAuthenticated]) {
        [[BBTHTTPManager sharedManager] showSignInVC:YES];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // Teardown XMPP Stream because:
    // 1. Per apple's notes in "Don’t Use dealloc to Manage Scarce Resources" you
    //    shouldn't manage scarce resources such as network connections, in a
    //    dealloc method.
    // 2. Apple docs further state that when an application terminates, objects
    //    may not be sent a dealloc message. Because the process’s memory is
    //    automatically cleared on exit, it is more efficient simply to allow
    //    the operating system to clean up resources than to invoke all the
    //    memory management methods.
    [[BBTXMPPManager sharedManager] teardownStream];
}

@end
