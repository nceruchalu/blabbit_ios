#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "XMPPRoster.h"
#import "XMPPCoreDataStorage.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPGroupCoreDataStorageObject.h"
#import "XMPPResourceCoreDataStorageObject.h"

/**
 * Blabbit's version of XMPPRostererCoreDataStorageObject that adds a method for
 * setting a user's nickname. This is needed because trying to do on vcard receipt
 * with mainThreadManagedObjectContext leads to errors on first application startup. 
 * For this I added the method `setNickname:forUserWithJID:xmppStream:` which is
 * based off of `setPhoto:forUserWithJID:xmppStream:`
 *
 * See section `Blabbit customizations` for implementation.
 */

/**
 * This class is an example implementation of XMPPRosterStorage using core data.
 * You are free to substitute your own roster storage class.
**/

@interface XMPPRosterCoreDataStorage : XMPPCoreDataStorage <XMPPRosterStorage>
{
	// Inherits protected variables from XMPPCoreDataStorage
	
#if __has_feature(objc_arc_weak)
	__weak XMPPRoster *parent;
#else
	__unsafe_unretained XMPPRoster *parent;
#endif
	dispatch_queue_t parentQueue;
	void *parentQueueTag;
    
	NSMutableSet *rosterPopulationSet;
}

/**
 * Convenience method to get an instance with the default database name.
 * 
 * IMPORTANT:
 * You are NOT required to use the sharedInstance.
 * 
 * If your application uses multiple xmppStreams, and you use a sharedInstance of this class,
 * then all of your streams share the same database store. You might get better performance if you create
 * multiple instances of this class instead (using different database filenames), as this way you can have
 * concurrent writes to multiple databases.
**/
+ (instancetype)sharedInstance;


/* Inherited from XMPPCoreDataStorage
 * Please see the XMPPCoreDataStorage header file for extensive documentation.
 
- (id)initWithDatabaseFilename:(NSString *)databaseFileName storeOptions:(NSDictionary *)storeOptions;
- (id)initWithInMemoryStore;

@property (readonly) NSString *databaseFileName;
 
@property (readwrite) NSUInteger saveThreshold;

@property (readonly) NSManagedObjectModel *managedObjectModel;
@property (readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (readonly) NSManagedObjectContext *mainThreadManagedObjectContext;
 
*/

- (XMPPUserCoreDataStorageObject *)myUserForXMPPStream:(XMPPStream *)stream
                            managedObjectContext:(NSManagedObjectContext *)moc;

- (XMPPResourceCoreDataStorageObject *)myResourceForXMPPStream:(XMPPStream *)stream
                                          managedObjectContext:(NSManagedObjectContext *)moc;

- (XMPPUserCoreDataStorageObject *)userForJID:(XMPPJID *)jid
                                   xmppStream:(XMPPStream *)stream
                         managedObjectContext:(NSManagedObjectContext *)moc;

- (XMPPResourceCoreDataStorageObject *)resourceForJID:(XMPPJID *)jid
										   xmppStream:(XMPPStream *)stream
                                 managedObjectContext:(NSManagedObjectContext *)moc;

#pragma mark - Blabbit customizations
- (void)setNickname:(NSString *)nickname forUserWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream;

/**
 * Save private thread managed object context nd have this propagate to main
 * thread context then post an appropriate notification
 */
- (void)saveAndPostNotification;

@end
