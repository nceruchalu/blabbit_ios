//
//  BBTRosterCDTVC.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/14/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "SearchCoreDataTableViewController.h"

@class XMPPUserCoreDataStorageObject;


/**
 * `BBTRosterCDTVC` is an abstract class that represents a Core Data TableViewController
 *   which is specialized to displaying a list of XMPP Roster Users' details.
 *
 *  @warning This class is intended to be subclassed. You should not use it 
 *    directly.
 */
@interface BBTRosterCDTVC : SearchCoreDataTableViewController

// hook up fetchedResultsController to any user request

/**
 * Get the identifier for the UITableViewCell of the currently displayed tableview's row.
 *
 * This is an abstract method to be implemented by a subclass
 *
 * @return the cell identifier string
 */
- (NSString *)cellIdentifier;

/**
 * Get the roster user object of the currently displayed tableview's row.
 *
 * This is an abstract method to be implemented by a subclass
 *
 * @return the roster CoreData storage user object of type XMPPUserCoreDataStorageObject
 *    or BBTUser
 */
- (id)userAtIndexPath:(NSIndexPath *)indexPath ofTableView:(UITableView *)tableView;


@end
