//
//  CoreDataCollectionViewController.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

/**
 * This class mostly just copies the code from NSFetchedResultController's
 *   documentation page into a sublcass of UITableViewController
 *
 * Just subclass this and set the fetchedResultsController
 * The only UICollectionViewDataSource method you have to implement is
 *   collectionView:cellForItemAtIndexPath: and you can use NSFetchedResultsController's
 *   method objectAtIndexPath: to do it.
 *
 * @note Remember that once you create an NSFetchedResultsController you CANNOT modify
 *   its properties.
 * If you want to create new fetch parameters (predicate, sorting, etc),
 *   create a NEW NSFetchedResultsController and set this class's
 *   fetchedResultsController again.
 *
 *  @warning This class is intended to be subclassed. You should not use it directly.
 */
@interface CoreDataCollectionViewController : UICollectionViewController <NSFetchedResultsControllerDelegate>

/**
 * The controller (this class) fetches nothing if this is not set
 */
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

/**
 * Causes the fetchedResultsController to refetch the data.
 * You almost certainly never need to call this.
 * The fetchedResultsController observes the context
 *   (so if objects in the context change, you do not need to call performFetch
 *   since the fetchedResultsController will notice and update the collectionView 
 *   automatically).
 * This will also be automatically called if you change the fetchedResultsController
 *   property.
 */
- (void)performFetch;

/**
 * Set to YES to get some debugging output in the console. Default is NO.
 */
@property BOOL debug;

@end
