//
//  SearchCoreDataTableViewController.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "CoreDataTableViewController.h"

/**
 * The `SearchCoreDataTableViewController` class is a subclass of CoreDataTableViewController
 *   that integrates with UISearchDisplayController.
 *
 * This class now expects fetchedResultscontroller property to be instantiated
 * when we end search as this is set to nil when the search table is displayed,
 * so as to prevent quirks with background updates.
 *
 * You still have to implement the UITableViewDataSource method tableView:cellForRowAtIndexPath:
 * and the UISearchDisplayDelegate methods, which appropriately call `super`.
 *
 * The idea behind this class is there are two fetchedResultsControllers:
 * fetchedResultsController and searchFetchedResultsController. The searchFetchedResultsController
 * should not be used unless there is a search, and as such should be cleared out
 * when the search is canceled. All UITableView methods must figure out what table view
 * it will query and which applicable FRC to pull the information from.
 * The NSFetchedResultsController delegate methods must also figure out what tableView to
 * update.
 *
 * This sort of boilerplate code will be useful for other classes hence making 
 * it its own class.
 *
 * @see http://stackoverflow.com/a/4481896
 *
 *  @warning This class is intended to be subclassed. You should not use it directly.
 */
@interface SearchCoreDataTableViewController : CoreDataTableViewController <UISearchDisplayDelegate,
UISearchBarDelegate>

/**
 * The controller (this class) shows no search results
 */
@property (strong, nonatomic) NSFetchedResultsController *searchFetchedResultsController;

#pragma mark - Helpers
/**
 * Return appropriate fetchedResultsController based on if the current tableView is
 *  self.tableView or self.searchDisplayController.searchResultsTableView
 */
- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView;

/**
 * Return appropriate tableView based on if the current fetchedResultsController is
 * self.fetchedResultsController or self.searchFetchedResultsController
 */
- (UITableView *)tableViewForFetchedResultsController:(NSFetchedResultsController *)controller;

@end
