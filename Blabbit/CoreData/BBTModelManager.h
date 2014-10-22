//
//  BBTModelManager.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/7/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BBTManagedDocument.h"

/**
 * BBTModelManager is a singleton class that ensures we have just one instance
 * of UIManagedDocument throughout this application for each actual document.
 * This way all changes will always be seen by all readers and writers of the
 * document.
 * This class also handles reading and writing of user settings
 */
@interface BBTModelManager : NSObject

#pragma mark -  Properties

/**
 * Database handle for app's Core Data storage facility
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

/**
 * Database handle for background operations.
 * Need to use a shared version so that all workers see same data.
 *
 * Would just use managedObjectContext.parentContext as the background
 * worker context, however it doesn't push changes down to the main
 * thread context. So need to make the worker context a child of the
 * main thread context.
 *
 * @ref http://floriankugler.com/blog/2013/4/2/the-concurrent-core-data-stack
 *
 * @warning This context needs to always ensure its data is up to date by doing
 * either of the following:
 * + After modifying objects in this context and saving, turn them into faults
 *   by calling refreshObject:mergeChanges: with the mergeChanges flag set to NO.
 * + Alternatively you could just reset the context. This works because
 *   NSPrivateQueueConcurrencyType means context is associated with a private 
 *   dispatch queue (i.e. Serial Queue), so no other block will be using this
 *   context as same time as you.
 *
 * For this reason its staleness interval is set to 0.0 to represent "no staleness 
 * acceptable". Remember that staleness interval is only of value when firing 
 * faults. This is why we need to turn objects into faults
 *
 * @ref "Ensuring Data Is Up-to-Date": https://developer.apple.com/library/mac/documentation/cocoa/conceptual/coredata/articles/cdUsingMOs.html#//apple_ref/doc/uid/TP40001803-208900
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *workerContext;

#pragma mark NSUserDefault Settings
@property (nonatomic) BOOL userSoundsSetting;


#pragma mark - Class Methods
/**
 * Single instance manager.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized BBTModelManager object.
 */
+ (instancetype)sharedManager;


#pragma mark - Instance Methods
/**
 * Setup document for a given app user (authenticated or anonymous). This sets 
 * up the internal UIManagedDocument and its associated managedObjectContext
 * This will close a previously opened document that is still open
 *
 * @param username  
 *      Unique identifier of users. If set to nil, then it's assumed to be working
 *      with an anonymous (not authenticated) user.
 * @param documentIsReady
 *      A block object to be executed when the document and managed object context
 *      are setup. This block has no return value and takes no arguments.
 */
- (void)setupDocumentForUser:(NSString *)username completionHandler:(void (^)())documentIsReady;


/**
 * Asynchronously save and close userDocument.
 *
 * @param documentIsClosed
 *      block to be called when document is closed successfully.
 */
- (void)closeUserDocument:(void (^)())documentIsClosed;


/**
 * Force an asynchronous manual save of the usually auto-saved userDocument.
 *
 * @param documentIsSaved
 *      block to be called when document is saved.
 */
- (void)saveUserDocument:(void (^)())documentIsSaved;


@end
