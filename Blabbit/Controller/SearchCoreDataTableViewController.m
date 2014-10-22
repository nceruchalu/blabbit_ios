//
//  SearchCoreDataTableViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "SearchCoreDataTableViewController.h"

@interface SearchCoreDataTableViewController ()

@property (nonatomic) BOOL beganUpdates;

@end

@implementation SearchCoreDataTableViewController

#pragma mark - Fetching
// perform fetch on searchFetchedResultsController @property and reload table view.
- (void)performSearchFetch
{
    if (self.searchFetchedResultsController) {
        if (self.searchFetchedResultsController.fetchRequest.predicate) {
            if (self.debug) NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.searchFetchedResultsController.fetchRequest.entityName, self.searchFetchedResultsController.fetchRequest.predicate);
        } else {
            if (self.debug) NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.searchFetchedResultsController.fetchRequest.entityName);
        }
        NSError *error;
        [self.searchFetchedResultsController performFetch:&error];
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        if (self.debug) NSLog(@"[%@ %@] no NSsearchFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [self.searchDisplayController.searchResultsTableView reloadData];
}

// setup new searchFetchedResultsController property
//   set delegate (as self)
//   set view controller's title if appropriate
//   call performSearchFetch if we got a new fetchResultsController
//      or clear Table (by reloading Data) if this was removed
- (void)setSearchFetchedResultsController:(NSFetchedResultsController *)newfrc
{
    // only bother changing the searchFetchedResultsController if receiving a new one.
    NSFetchedResultsController *oldfrc = _searchFetchedResultsController;
    if (newfrc != oldfrc) {
        _searchFetchedResultsController = newfrc;
        newfrc.delegate = self;
        
        // set title if view controller doesn't have one
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) &&
            (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name;
        }
        
        // either fetch new data or clear out table view.
        if (newfrc) {
            if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
            [self performSearchFetch];
        } else {
            if (self.debug) NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }
}


#pragma mark - Helpers
/**
 * Return appropriate fetchedResultsController based on if the current tableView is
 *  self.tableView or self.searchDisplayController.searchResultsTableView
 */
- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView
{
    return (tableView == self.tableView) ? self.fetchedResultsController : self.searchFetchedResultsController;
}

/**
 * Return appropriate tableView based on if the current fetchedResultsController is
 * self.fetchedResultsController or self.searchFetchedResultsController
 */
- (UITableView *)tableViewForFetchedResultsController:(NSFetchedResultsController *)controller
{
    return (controller == self.fetchedResultsController) ? self.tableView : self.searchDisplayController.searchResultsTableView;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
     NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
    
    return [[fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
    
    if ([[fetchedResultsController sections] count] > 0 ) {
        return [[[fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
    } else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
    
    if ([[fetchedResultsController sections] count] > 0 ) {
        return [[[fetchedResultsController sections] objectAtIndex:section] name];
    } else {
        return nil;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
    
    return [fetchedResultsController sectionIndexTitles];
}


#pragma mark -  UISearchDisplayDelegate
/**
 * When the tableView behind the searchResultsTableView has its headers reloaded
 * the top header will pop out and display over the searchResultsTableView.
 * To solve this I'll prevent the tableView from being able to reload by setting
 * it to nil. It should be instantiated again when the search disappears.
 */
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    self.fetchedResultsController = nil;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    // search table view is done so get rid of the search FRC
    self.searchFetchedResultsController = nil;
}



#pragma mark - NSFetchedResultsControllerDelegate
// Have to overwrite the parent class's delegate method so they use the right
// tableview
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    UITableView *tableView = [self tableViewForFetchedResultsController:controller];
    
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [tableView beginUpdates];
        self.beganUpdates = YES;
    } else {
        self.beganUpdates = NO;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    UITableView *tableView = [self tableViewForFetchedResultsController:controller];
    
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        switch (type) {
            case NSFetchedResultsChangeInsert:
                [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                         withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                         withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            default:
                break;
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = [self tableViewForFetchedResultsController:controller];
    
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        switch (type) {
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeMove:
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            default:
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    UITableView *tableView = [self tableViewForFetchedResultsController:controller];
    
    if (self.beganUpdates) [tableView endUpdates];
}




@end
