//
//  CoreDataCollectionViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "CoreDataCollectionViewController.h"

@interface CoreDataCollectionViewController ()

@property (strong, nonatomic) NSMutableArray *itemChangesOfCDCVC;
@property (strong, nonatomic) NSMutableArray *sectionChangesOfCDCVC;

@end

@implementation CoreDataCollectionViewController

#pragma mark - Properties
- (NSMutableArray *)itemChangesOfCDCVC
{
    // lazy instantiation
    if (!_itemChangesOfCDCVC) _itemChangesOfCDCVC = [[NSMutableArray alloc] init];
    return _itemChangesOfCDCVC;
}

- (NSMutableArray *)sectionChangesOfCDCVC
{
    // lazy instatiation
    if (!_sectionChangesOfCDCVC) _sectionChangesOfCDCVC = [[NSMutableArray alloc] init];
    return _sectionChangesOfCDCVC;
}


#pragma mark - Fetching
// perform fetch on fetchedResultsController @property and reload collection view.
- (void)performFetch
{
    if (self.fetchedResultsController) {
        if (self.fetchedResultsController.fetchRequest.predicate) {
            if (self.debug) NSLog(@"[%@ %@] fetching %@ with predicate: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName, self.fetchedResultsController.fetchRequest.predicate);
        } else {
            if (self.debug) NSLog(@"[%@ %@] fetching all %@ (i.e., no predicate)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fetchedResultsController.fetchRequest.entityName);
        }
        NSError *error;
        [self.fetchedResultsController performFetch:&error];
        if (error) NSLog(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
    } else {
        if (self.debug) NSLog(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    [self.collectionView reloadData];
}

// setup new fetchResultsController property
//   set delegate (as self)
//   set view controller's title if appropriate
//   call performFetch if we got a new fetchResultsController
//      or clear CollectionView (by reloading Data) if this was removed
- (void)setFetchedResultsController:(NSFetchedResultsController *)newfrc
{
    // only bother changing the fetchedResultsController if receiving a new one.
    NSFetchedResultsController *oldfrc = _fetchedResultsController;
    if (newfrc != oldfrc) {
        _fetchedResultsController = newfrc;
        newfrc.delegate = self;
        
        // set title if view controller doesn't have one
        if ((!self.title || [self.title isEqualToString:oldfrc.fetchRequest.entity.name]) &&
            (!self.navigationController || !self.navigationItem.title)) {
            self.title = newfrc.fetchRequest.entity.name;
        }
        
        // either fetch new data or clear out collection view.
        if (newfrc) {
            if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
            [self performFetch];
        } else {
            if (self.debug) NSLog(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            [self.collectionView reloadData];
        }
    }
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([[self.fetchedResultsController sections] count] > 0 ) {
        return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
    } else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell"; // get the cell
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    // NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //   configure the cell with data from the managed object
    
    // Configure the cell...
    
    return cell;
}


#pragma mark - NSFetchedResultsControllerDelegate
/*
 * NSFetchedResultsController delegate has methods that do the following:
 *   -controllerWillChangeContent: is called before changes are made
 *   -controller:didChangeSection: is called for changes to individual sections
 *   -controller:didChangeObject:  is called for changes to individual objects
 *   -controllerDidChangeContent:  is called when all changes are complete
 *
 * UITableView uses beginUpdates and endUpdates to submit batch changes to the 
 *   table view.
 *   beginUpdates is called before changes are made, and endUpdates when done.
 *
 * UICollectionView doesn't have these, rather it has a performBatchUpdates: 
 *   method, which takes a block parameter to update the collection view. 
 *   This doesn't work well with the NSFetchedResultsController delegate and
 *   will make us jump through some extra hoops as documented below
 */
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // refresh the stores of changed items and sections
    self.itemChangesOfCDCVC = nil;
    self.sectionChangesOfCDCVC = nil;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
    switch (type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
            
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
            
        default:
            break;
    }
    [self.sectionChangesOfCDCVC addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
    switch (type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
            
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
            
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
            
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
            
        default:
            break;
    }
    [self.itemChangesOfCDCVC addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([self shouldReloadCollectionViewToPreventKnownIssue] || !self.collectionView.window) {
        // Check to prevent a known bug as well as nasty auto layout issues
        // by reloading data when not on screen.
        // This is to prevent a bug in UICollectionView from occurring.
        // The bug presents itself when inserting the first object or
        //   deleting the last object in a collection view.
        //   http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
        // This code should be removed once the bug has been fixed, it is
        //   tracked in OpenRadar
        //   http://openradar.appspot.com/12954582
        [self.collectionView reloadData];
        return;
    }
    
    [self.collectionView performBatchUpdates:^{
        // section changes
        for (NSDictionary *change in self.sectionChangesOfCDCVC) {
            [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch (type)
                {
                    case NSFetchedResultsChangeInsert:
                        [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                        
                    case NSFetchedResultsChangeDelete:
                        [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                        break;
                        
                    default:
                        break;
                }
            }];
        }
        
        // item changes
        for (NSDictionary *change in self.itemChangesOfCDCVC) {
            [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                
                NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                switch (type) {
                    case NSFetchedResultsChangeInsert:
                        [self.collectionView insertItemsAtIndexPaths:@[obj]];
                        break;
                        
                    case NSFetchedResultsChangeDelete:
                        [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                        break;
                        
                    case NSFetchedResultsChangeUpdate:
                        [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                        break;
                        
                    case NSFetchedResultsChangeMove:
                        [self.collectionView moveItemAtIndexPath:obj[0]
                                                     toIndexPath:obj[1]];
                        break;
                        
                    default:
                        break;
                }
            }];
        }
        
        
    } completion:^(BOOL finished) {
        self.sectionChangesOfCDCVC = nil;
        self.itemChangesOfCDCVC = nil;
    }];
}


#pragma mark - Instance Methods (private)
/* 
 * This is to prevent a bug in UICollectionView from occurring.
 * The bug presents itself when inserting the first object or deleting the last 
 *   object in a collection view.
 *   http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
 * This code should be removed once the bug has been fixed, it is tracked in OpenRadar
 *   http://openradar.appspot.com/12954582
 */
- (BOOL)shouldReloadCollectionViewToPreventKnownIssue {
    __block BOOL shouldReload = NO;
    for (NSDictionary *change in self.itemChangesOfCDCVC) {
        [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            NSIndexPath *indexPath = obj;
            switch (type) {
                case NSFetchedResultsChangeInsert:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 0) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeDelete:
                    if ([self.collectionView numberOfItemsInSection:indexPath.section] == 1) {
                        shouldReload = YES;
                    } else {
                        shouldReload = NO;
                    }
                    break;
                case NSFetchedResultsChangeUpdate:
                    shouldReload = NO;
                    break;
                case NSFetchedResultsChangeMove:
                    shouldReload = NO;
                    break;
            }
        }];
    }
    
    return shouldReload;
}

@end
