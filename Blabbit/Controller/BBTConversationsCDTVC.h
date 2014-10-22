//
//  BBTConversationsCDTVC.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/23/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "SearchCoreDataTableViewController.h"

/**
 * `BBTConversationsCDTVC` is an abstract class that represents a Core Data 
 *   TableViewController which is specialized to displaying a list of Blabbit
 *   Conversation details.
 *  
 * You're still required to implement the following DataSource/Delegate methods
 *   - tableView:cellForRowAtIndexPath:
 *   - tableView:commitEditingStyle:forRowAtIndexPath:
 *
 *  @warning This class is intended to be subclassed. You should not use it 
 *    directly.
 */
@interface BBTConversationsCDTVC : SearchCoreDataTableViewController

/**
 * need this property to get a handle to the database
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

#pragma mark - Instance Methods
#pragma mark Navigation
/**
 * Called when about to segue to a VC after selecting a tableview cell.
 *
 * @param vc                View controller to be segued to
 * @param segueIdentifier   Segue identifier as configured in storyboard
 * @param indexPath         NSIndexPath of tableview cell that triggered segue.
 * @param tableView         tableView that triggering cell belongs in
 */
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
                fromIndexPath:(NSIndexPath *)indexPath
                  ofTableView:(UITableView *)tableView;

#pragma mark Abstract
/**
 * Hook up fetchedResultsController property to any conversation request
 * This will only be called when managedObjectContext property is configured
 */
- (void)setupFetchedResultsController;

@end
