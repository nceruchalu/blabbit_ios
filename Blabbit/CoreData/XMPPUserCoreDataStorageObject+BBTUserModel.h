//
//  XMPPUserCoreDataStorageObject+BBTUserModel.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/6/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "XMPPUserCoreDataStorageObject.h"
#import "MBContactModel.h"

/**
 * The BBTUserModel category on XMPPUserCoreDataStorageObject provides us with
 *   the utility functions necessary to extract title fields necessary for
 *   displaying a user in RosterTableViews
 *
 */
@interface XMPPUserCoreDataStorageObject (BBTUserModel) <MBContactPickerModelProtocol>

/**
 * Username of user
 */
- (NSString *)username;


/**
 * Formatted Name of user. Really just a better displayName
 */
- (NSString *)formattedName;

@end
