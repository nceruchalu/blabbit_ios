//
//  BBTRosterTVCHelper.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/30/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BBTRosterTableViewCell;
@class XMPPUserCoreDataStorageObject;

/**
 * BBTRosterTVCHelper pulls out methods that are shared by BBTContactPicker's 
 * tableview and BBTRosterCDTVC's tableview. This is a much better solution than 
 * duplicating code.
 */
@interface BBTRosterTVCHelper : NSObject

/**
 * Configure a cell in UITableViewDataSource method: tableView:cellForRowAtIndexPath:
 * @param cell  Table view cell to be updated
 * @param user  User to be represented in table view cell of type BBTUser or XMPPUserCoreDataStorageObject
 */
+ (void)configureCell:(BBTRosterTableViewCell *)cell withUser:(id)user;

/**
 * Convert an XMPPUserCoreDataStorageObject's sectionNum to an online
 *   availability status string.
 *
 * @return availability status string
 */
+ (NSString *)userSectionNumToStatus:(int)sectionNum;

@end
