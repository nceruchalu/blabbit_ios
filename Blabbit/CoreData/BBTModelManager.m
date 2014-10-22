//
//  BBTModelManager.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/7/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTModelManager.h"
#import <CoreData/CoreData.h>

// Imports for Ephemeral conversation management
#import "BBTGroupConversation+XMPP.h"

// Constants
/**
 * Constants for Managed Document location
 */
static NSString *const kUserDocumentBase      = @"UserDocument";
static NSString *const kAnonymousUserDocument = @"AnonymousUserDocument";

/**
 * Constants for NSUserDefaults user settings dictionary keys
 */
static NSString *const kUserKeyBase      = @"kBBTUserKey";
static NSString *const kAnonymousUserKey = @"kBBTAnonymousUserKey";


@interface BBTModelManager ()

// want all properties to be readwrite internally
@property (strong, nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *workerContext;

@property (strong, nonatomic) NSString *username; // cache username being used.

/**
 * The documents for this app are separated by user, so this will be updated for
 * each user (authenticated or not) that logs into the app
 */
@property (strong, nonatomic) UIManagedDocument *userDocument;

/**
 * Timer that triggers deletion of expired group conversations.
 */
@property (strong, nonatomic) dispatch_source_t deleteTimer;

@end

@implementation BBTModelManager

#pragma mark - Properties
- (void)setUserDocument:(UIManagedDocument *)userDocument
{
    _userDocument = userDocument;
    self.managedObjectContext = nil;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    self.workerContext = nil;
    
    // if we have a new managedObjectContext, then perform a cleanup of expired
    // groupchats by forcing a delete to happen now
    if (managedObjectContext) {
        [self performDelete];
    }
}

- (NSManagedObjectContext *)workerContext
{
    if (!_workerContext && self.managedObjectContext) {
        _workerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _workerContext.parentContext = self.managedObjectContext;
        [_workerContext setStalenessInterval:0.0]; // no staleness acceptable
    }
    return _workerContext;
}


#pragma mark NSUserDefault Settings
- (BOOL)userSoundsSetting
{
    NSDictionary *userSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[self userSettingsKey]];
    return [[userSettings objectForKey:kBBTSettingsSounds] boolValue];
}

- (void)setUserSoundsSetting:(BOOL)userSoundsSetting
{
    NSString *userKey = [self userSettingsKey];
    NSMutableDictionary *mutableUserSettings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:userKey] mutableCopy];

    [mutableUserSettings setObject:@(userSoundsSetting) forKey:kBBTSettingsSounds];
    
    [[NSUserDefaults standardUserDefaults] setObject:mutableUserSettings forKey:userKey];
    [[NSUserDefaults standardUserDefaults] synchronize]; // never forget saving to disk
}


#pragma mark - Class methods
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static BBTModelManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}


#pragma mark - Initialization
// ideally we would make the designated initializer of the superclass call
//   the new designated initializer, but that doesn't make sense in this case.
// if a programmer calls [BBTModelManager alloc] init], let him know the error
//   of his ways.
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use + [BBTModelManager sharedManager]"
                                 userInfo:nil];
    return nil;
}

// here is the real (secret) initializer
// this is the official designated initializer so it will call the designated
//   initializer of the superclass
- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        // custom initialization here...
        // Setup timer for ephemeral conversation management
        _deleteTimer = [self createAndStartDispatchTimer:(kBBTGroupConversationDeleteInterval * NSEC_PER_SEC)
                                                  leeway:(1ull * NSEC_PER_SEC)
                                                   queue:dispatch_get_main_queue()
                                                   block:^{
                                                       [self performDelete];
                                                   }];
        
    }
    return self;
}

#pragma mark - Instance Methods
#pragma mark Public
- (void)setupDocumentForUser:(NSString *)username completionHandler:(void (^)())documentIsReady
{
    // register default settings for user at this time
    [self registerDefaultSettings:username];
    
    // clear out managed object context which will soon be setup again.
    self.managedObjectContext = nil;
    
    // if a document is already open close it out before setting up document
    if (self.userDocument) {
        [self closeUserDocument:^{
            self.userDocument = nil;
            [self setupNewDocumentForUser:username completionHandler:documentIsReady];
        }];
        
    } else {
        [self setupNewDocumentForUser:username completionHandler:documentIsReady];
    }
}


/**
 * Asynchronously save and close userDocument.
 *
 * @param documentIsClosed
 *      block to be called when document is closed successfully.
 */
- (void)closeUserDocument:(void (^)())documentIsClosed
{
    [self.userDocument closeWithCompletionHandler:^(BOOL success) {
        // it would be ideal to check for success first, but if this fails
        // it's game over anyways.
        // we indicate document closure by clearing out userDocument
        self.userDocument = nil;
        
        // notify all listeners that this managedObjectContext is no longer valid
        [[NSNotificationCenter defaultCenter] postNotificationName:kBBTMOCDeletedNotification
                                                            object:self];
        if (documentIsClosed) documentIsClosed();
    }];
}


/**
 * Force an asynchronous manual save of the usually auto-saved userDocument.
 *
 * @param documentIsSaved
 *      block to be called when document is saved.
 */
- (void)saveUserDocument:(void (^)())documentIsSaved
{
    [self.userDocument saveToURL:self.userDocument.fileURL
                forSaveOperation:UIDocumentSaveForOverwriting
               completionHandler:^(BOOL success) {
                   if (success) {
                       if (documentIsSaved) documentIsSaved();
                   }
               }
     ];
}


#pragma mark Private
/**
 * Setup document for a given app user (authenticated or anonymous). This sets
 * up the internal UIManagedDocument and its associated managedObjectContext
 *
 * This is different from the public method setupDocumentForUser:completionHandler:
 * in that it doesn't close a previously opened document.
 *
 * @param username
 *      Unique identifier of users. If set to nil, then it's assumed to be working
 *      with an anonymous (not authenticated) user.
 * @param documentIsReady
 *      A block object to be executed when the document and managed object context
 *      are setup. This block has no return value and takes no arguments.
 *
 * @warning You probably shouldn't call this without first closing the document.
 */
- (void)setupNewDocumentForUser:(NSString *)username completionHandler:(void (^)())documentIsReady
{
    // setup userDocument @property as a document in the application's document directory
    NSURL *docURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    // anonymous users have a different document directory from authenticated users.
    NSString *docPath = nil;
    if (username && [username length]) {
        docPath = [NSString stringWithFormat:@"%@%@", kUserDocumentBase, username];
    } else {
        docPath = kAnonymousUserDocument;
    }
    docURL = [docURL URLByAppendingPathComponent:docPath];
    self.userDocument = [[BBTManagedDocument alloc] initWithFileURL:docURL];
    
    // support automatic migration
    // see documentation of NSPersistentStoreCoordinator for details
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption  : @(YES),
                              NSInferMappingModelAutomaticallyOption        : @(YES)};
    self.userDocument.persistentStoreOptions = options;
    
    // use userDocument to setup managedObjectContext @property
    [self useUserDocument:^{
        // notify all listeners that this managedObjectContext is now setup
        [[NSNotificationCenter defaultCenter] postNotificationName:kBBTMOCAvailableNotification
                                                            object:self];
        if (documentIsReady) documentIsReady();
    }];
}

/**
 * Either creates, opens or just uses the userDocument.
 * Creating and opening are async, so in the completion handler we set our model
 *   (managedObjectContext).
 * This sets up the managedObjectContext property if it isn't already setup
 *   then it calls the ^(void)documentIsReady block.
 *
 * @param documentIsReady
 *      block to be called when document is ready and managedObjectContext
 *      property is setup.
 */
- (void)useUserDocument:(void (^)())documentIsReady
{
    // access the shared instance of the document
    NSURL *url = self.userDocument.fileURL;
    UIManagedDocument *document = self.userDocument;
    
    // must first open/create the document to use it so check to see if it
    // exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        // if document doesn't exist create it
        [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                self.managedObjectContext = document.managedObjectContext;
                // just created this document so this would be a good time to call
                // methods to populate the data. However there is no need for
                // that in this case.
                if (documentIsReady) documentIsReady();
            }
        }];
        
    } else if (document.documentState == UIDocumentStateClosed) {
        // if document exists but is closed, open it
        [document openWithCompletionHandler:^(BOOL success) {
            if (success) {
                self.managedObjectContext = document.managedObjectContext;
                // if already open, no need to attempt populating the data.
                if (documentIsReady) documentIsReady();
            }
        }];
        
    } else {
        // if document is already open try to use it
        self.managedObjectContext = document.managedObjectContext;
        // again already open, so no need to attempt populating the data.
        if (documentIsReady) documentIsReady();
    }
}


/**
 * Register NSUserDefault settings for currently authenticated user
 *
 * @param username
 *      Unique identifier of user. If set to nil, then it's assumed to be working
 *      with an anonymous (not authenticated) user.
 */
- (void)registerDefaultSettings:(NSString *)username;
{
    self.username = username; // cache username
    
    // Create the preference defaults
    NSDictionary *appDefaults = @{kBBTSettingsSounds: @(YES)};
    NSDictionary *userDefaults = @{[self userSettingsKey] : appDefaults};
    
    // Register the preference defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 * Get key for a user's settings in NSUserDefaults
 */
- (NSString *)userSettingsKey
{
    // anonymous users have a different key from authenticated users.
    NSString *username = self.username;
    NSString *key = nil;
    if (username && [username length]) {
        key = [NSString stringWithFormat:@"%@%@", kUserKeyBase, username];
    } else {
        key = kAnonymousUserKey;
    }
    return key;
}


#pragma mark - Ephemeral Conversation Management
- (void)dealloc
{
    [self destroyDeleteTimer];
}

/**
 * Delete expired groupchat conversations
 */
- (void)performDelete
{
    // Skip this deletion round if managedObjectContext isn't ready at this time.
    if (!self.managedObjectContext) return;
    
    // Use main thread context since this has some UIKit implications.
    NSManagedObjectContext *context = self.managedObjectContext;
    [context performBlock:^{
        // Minimum acceptable group conversation creation date.
        NSDate *minCreationDate = [NSDate dateWithTimeIntervalSinceNow:(kBBTGroupConversationExpiryTime * -1.0)];
        
        // Get expired group conversations
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"BBTGroupConversation"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"creationDate <= %@", minCreationDate];
        [fetchRequest setPredicate:predicate];
        // Not setting a fetch batch size as we want to remove every expired groupchat
        
        NSError *error = nil;
        NSArray *expiredConversations = [context executeFetchRequest:fetchRequest
                                                               error:&error];
        
        if ([expiredConversations count]) {
            for (BBTGroupConversation *conversation in expiredConversations) {
                // Can now delete the expired conversation.
                // Observe no network calls are made. We depend on the server to
                // perform its own ephemeral conversation management. This is
                // easily the cleanest solution.
                [conversation deleteAndPostNotification];
            }
            
            // post notification indicating the list of conversations has changed.
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kBBTConversationsUpdateNotification object:self];
            });
        }
    }];
}

/**
 * Destroy the dispatch timer that generates events for deleting expired
 * groupchat converations.
 */
- (void)destroyDeleteTimer
{
	if (self.deleteTimer)
	{
		dispatch_source_cancel(self.deleteTimer);
		self.deleteTimer = NULL;
	}
}

/**
 * Create and start Dispatch timer to generate events at regular, time-based
 * intervals. The timer interval is expected to relatively large (>10s), so the
 * dispatch source is created using the dispatch_walltime function.
 *
 * @param interval  The nanosecond interval for the timer
 * @param leeway    The amount of time, in nanoseconds, that the system can defer 
 *                  the timer.
 * @param queue     The dispatch queue to which the event handler block is submitted.
 * @param block     The timer event handler block to submit to the queue.
 *
 */
- (dispatch_source_t)createAndStartDispatchTimer:(uint64_t)interval
                                          leeway:(uint64_t)leeway
                                           queue:(dispatch_queue_t)queue
                                           block:(dispatch_block_t)block
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}




@end
