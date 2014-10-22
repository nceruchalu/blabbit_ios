//
//  BBTXMPPManager.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/14/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTXMPPManager.h"
#import "GCDAsyncSocket.h"
#import "KeychainItemWrapper.h"
#import "BBTMessage+XMPP.h"
#import "BBTGroupConversation+XMPP.h"
#import "BBTGroupConversation+CLLocation.h"
#import "BBTUser+HTTP.h"
#import "BBTUtilities.h"
#import "BBTHTTPManager.h"
#import "BBTManagedDocument.h"
#import "BBTModelManager.h"

#import "XMPPLogging.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

#import <CFNetwork/CFNetwork.h>

// to grab managedObjectContext of XMPPRosterCoreDataStorage
#import "XMPPCoreDataStorageProtected.h"


// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE | XMPP_LOG_FLAG_SEND_RECV;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


// Constants
// maximum value of randomly generated int to be appended to resource
static const NSUInteger kMaxResourceID = 99999;


@interface BBTXMPPManager ()

// want all properties to be readwrite (privately)

@property (nonatomic, readwrite) BOOL customCertEvaluation;
@property (nonatomic, readwrite, getter = isXmppConnected) BOOL xmppConnected;
@property (strong, nonatomic, readwrite) XMPPStream *xmppStream;
@property (strong, nonatomic, readwrite) XMPPReconnect *xmppReconnect;
@property (strong, nonatomic, readwrite) XMPPRoster *xmppRoster;
@property (strong, nonatomic, readwrite) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (strong, nonatomic, readwrite) XMPPvCardTempModule *xmppvCardTempModule;
@property (strong, nonatomic, readwrite) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (strong, nonatomic, readwrite) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (strong, nonatomic, readwrite) XMPPCapabilities *xmppCapabilities;
@property (strong, nonatomic, readwrite) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (strong, nonatomic, readwrite) XMPPMessageDeliveryReceipts *xmppDeliveryReceipts;
@property (strong, nonatomic, readwrite) XMPPMUC *xmppMUC;
@property (strong, nonatomic, readwrite) XMPPRoomCoreDataStorage *xmppRoomStorage;


// private properties
// Cached user password (same for HTTP and XMPP)
@property (strong, nonatomic) NSString *userPassword;

// Number of retries for failed authentication
@property (nonatomic) NSInteger authenticationRetryCounts;

// Handle to the App model's managedObjectContext
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContextChats;

// Have chosen to go with a single instance of UIManagedDocument throughout the
//   application for each actual document. Then all changes will be seen by all
//   writers and readers of the document.
// I could of course have created another singleton class that returns just this
//   document but having this be a property of the singleton XMPP manager achieves
//   same goal with less scattered code.
@property (strong, nonatomic) UIManagedDocument *chatsDocument;

// Current XMPPRoom this user is active in
@property (strong, nonatomic, readwrite) XMPPRoom *xmppRoom;

// List of XMPPRooms that are to be destroyed. We need this because xmpp room
// destruction is an async process and we don't want to lose track of the rooms
// queued up for destroy operations.
@property (strong, nonatomic) NSMutableArray *xmppRoomsToDestroy; // of XMPPRoom

// We need to track some XMPP Room creation properties that cannot be used until
// rooms are created and configured on the XMPP Server.
// Dictionary tracking initial list of invitees to created rooms.
@property (strong, nonatomic) NSMutableDictionary *xmppRoomInvitees;
// Dictionary tracking photos used for created rooms.
@property (strong, nonatomic) NSMutableDictionary *xmppRoomPhoto;

// private instance methods
- (void)teardownStream;
- (void)goOnline;
- (void)goOffline;

@end


@implementation BBTXMPPManager

#pragma mark - Properties 
#pragma mark Core Data
- (NSManagedObjectContext *)managedObjectContextRoster
{
    return [self.xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContextCapabilities
{
    return [self.xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContextRoom
{
    return [self.xmppRoomStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContextChats
{
    return [BBTModelManager sharedManager].managedObjectContext;
}

#pragma mark Private
- (NSMutableDictionary *)xmppRoomInvitees
{
    // lazy instantiation
    if (!_xmppRoomInvitees) _xmppRoomInvitees = [[NSMutableDictionary alloc] init];
    return _xmppRoomInvitees;
}

- (NSMutableDictionary *)xmppRoomPhoto
{
    // lazy instantiation
    if (!_xmppRoomPhoto) _xmppRoomPhoto = [[NSMutableDictionary alloc] init];
    return _xmppRoomPhoto;
}

- (NSMutableArray *)xmppRoomsToDestroy
{
    // lazy instantiation
    if (!_xmppRoomsToDestroy) _xmppRoomsToDestroy = [[NSMutableArray alloc] init];
    return _xmppRoomsToDestroy;
}

- (void)setXmppRoom:(XMPPRoom *)xmppRoom{
    // first cleanup the xmppRoom
    [_xmppRoom leaveRoom];
    [_xmppRoom removeDelegate:self];
    [_xmppRoom deactivate];
    
    _xmppRoom = xmppRoom;
}

#pragma mark Public
- (NSString *)xmppNickname
{
    // We will join the xmpp rooms using a nickname of username.
    return self.xmppStream.myJID.user;
}


#pragma mark - Class methods
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static BBTXMPPManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}


#pragma mark - Initialization
// ideally we would make the designated initializer of the superclass call
//   the new designated initializer, but that doesn't make sense in this case.
// if a programmer calls [BBTXMPPManager alloc] init], let him know the error
//   of his ways.
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use + [BBTXMPPMananger sharedManager]"
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
        
        // Configure logging framework
        [DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:ddLogLevel];
    }
    return self;
}


#pragma mark - INSTANCE METHODS

#pragma mark - XMPP Stream Management
#pragma mark Private
- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	
	[self.xmppStream sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[self.xmppStream sendElement:presence];
}


#pragma mark Public
- (void)dealloc
{
    [self teardownStream];
}

- (void)setupStream
{
    // setupStream shouldn't be invoked multiple times.
    if (self.xmppStream) return;
    
	NSAssert(self.xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	self.xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
        // You shouldn't. Refer to apple's technical note on Networking and
        // Multitasking which recommends closing sockets when going into the
        // background and reopening them when it comes back into the foreground.
        // https://developer.apple.com/library/ios/technotes/tn2277/_index.html
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator,
        //        it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when
        //        it fails to set the property.
		
		self.xmppStream.enableBackgroundingOnSocket = NO;
	}
#endif
	
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	self.xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
	
	self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
	
    self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
	
	self.xmppRoster.autoFetchRoster = YES;
	self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	//
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	self.xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:self.xmppvCardStorage];
	
	self.xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCardTempModule];
	
	// Setup capabilities
	//
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	//
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	//
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
	self.xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    self.xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:self.xmppCapabilitiesStorage];
    
    self.xmppCapabilities.autoFetchHashedCapabilities = YES;
    self.xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    // Setup delivery receipts
    //
    // Want to always send delivery requests and receipts
    self.xmppDeliveryReceipts = [[XMPPMessageDeliveryReceipts alloc] init];
    self.xmppDeliveryReceipts.autoSendMessageDeliveryReceipts = YES;
    self.xmppDeliveryReceipts.autoSendMessageDeliveryRequests = YES;
    
    
    // Setup Room/MUC
    self.xmppRoomStorage = [XMPPRoomCoreDataStorage sharedInstance];
    self.xmppRoomStorage.maxMessageAge = kBBTGroupConversationExpiryTime; // 1 day
    self.xmppMUC = [[XMPPMUC alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    
    
    
	// Activate xmpp modules
    
	[self.xmppReconnect         activate:self.xmppStream];
	[self.xmppRoster            activate:self.xmppStream];
	[self.xmppvCardTempModule   activate:self.xmppStream];
	[self.xmppvCardAvatarModule activate:self.xmppStream];
	[self.xmppCapabilities      activate:self.xmppStream];
    [self.xmppDeliveryReceipts  activate:self.xmppStream];
    [self.xmppMUC               activate:self.xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
	[self.xmppStream            addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[self.xmppRoster            addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppvCardTempModule   addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppCapabilities      addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppMUC               addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:5222];
	
    
	// You may need to alter these settings depending on the server you're connecting to
	self.customCertEvaluation = YES;
}

- (void)teardownStream
{
	[self.xmppStream            removeDelegate:self];
	[self.xmppRoster            removeDelegate:self];
    [self.xmppvCardTempModule   removeDelegate:self];
    [self.xmppCapabilities      removeDelegate:self];
    [self.xmppMUC               removeDelegate:self];
	
	[self.xmppReconnect         deactivate];
	[self.xmppRoster            deactivate];
	[self.xmppvCardTempModule   deactivate];
	[self.xmppvCardAvatarModule deactivate];
	[self.xmppCapabilities      deactivate];
    [self.xmppDeliveryReceipts  deactivate];
    [self.xmppMUC               deactivate];
	
	[self.xmppStream disconnect];
	
	self.xmppStream = nil;
	self.xmppReconnect = nil;
    self.xmppRoster = nil;
	self.xmppRosterStorage = nil;
    self.xmppvCardTempModule = nil;
	self.xmppvCardAvatarModule = nil;
    self.xmppvCardStorage = nil;
	self.xmppCapabilities = nil;
	self.xmppCapabilitiesStorage = nil;
    self.xmppDeliveryReceipts = nil;
    self.xmppMUC = nil;
    self.xmppRoomStorage = nil;
    
    // This property will remove app user from room and deactivate it.
    self.xmppRoom = nil;
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// https://github.com/robbiehanson/XMPPFramework/wiki/WorkingWithElements


#pragma mark Connect/Disconnect
/* The connect method will check if there are credentials already stored
 * on the device.
 * The userJID (JabberID) can of course be stored using the NSUserDefaults
 *   class but the password you want to store in a secure place like the
 *   Keychain Access
 *
 * @return BOOL indicating app's ability to start connection process.
 */
- (BOOL)connect
{
    // if stream is already connected then there's nothing to do here
	if (![self.xmppStream isDisconnected]) {
		return YES;
	}
    
    // grab username/password to be used for authenticating
    NSString *myUsername = [BBTHTTPManager sharedManager].username;
	NSString *myPassword = [BBTHTTPManager sharedManager].password;
    
    // if a username/password isn't present, halt this connection attempt
    if ([myUsername length] == 0 || [myPassword length] == 0) {
		return NO;
	}
    
    // convert username to a JID
    NSString *myJID = [NSString stringWithFormat:@"%@@%@",myUsername, kBBTXMPPServer];
    NSUInteger r = arc4random() % kMaxResourceID;
    NSString * resource = [NSString stringWithFormat:@"%@%lu",kBBTXMPPResource,(unsigned long)r];
    
    // finally setup xmppStream for a connection and initiate the connection
	[self.xmppStream setMyJID:[XMPPJID jidWithString:myJID resource:resource]];
	self.userPassword = myPassword;
    
	NSError *error = nil;
	if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
		DDLogError(@"Error connecting: %@", error);
		return NO;
	}
    
	return YES;
}

- (BOOL)connectAnonymous
{
    // if stream is already connected then there's nothing to do here
	if (![self.xmppStream isDisconnected]) {
		return YES;
	}
    
    // even though we are doing anonymous authentication, we still have to set
    // myJID prior to calling connect. You can simply set it to something like
    // "anonymous@<domain>", where "<domain>" is the proper domain.
    // After the authentication process, you can query the myJID property to see
    // what your assigned JID is.
    // @see connectWithTimeout:error: for a more detailed discussion
    
    NSString *myJID = [NSString stringWithFormat:@"%@@%@",@"anonymous", kBBTXMPPServer];
    [self.xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
    
    NSError *error = nil;
	if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
		DDLogError(@"Error connecting anonymously: %@", error);
		return NO;
	}
    
    return YES;
}

- (void)disconnect
{
	[self goOffline];
    // chosen to use asynchronous disconnect
	[self.xmppStream disconnectAfterSending];
}

/**
 * Perform XMPP authentication after successful connection
 */
- (void)authenticate
{
    NSError *error = nil;
    if ([BBTHTTPManager sharedManager].isHTTPAuthenticated) {
        // if user has provided valid username/password then authenticate with that
        if (![self.xmppStream authenticateWithPassword:self.userPassword error:&error]) {
            DDLogError(@"Error authenticating: %@", error);
        }
        
    } else {
        // user is operating this app in anonymous mode so use that
        if (![self.xmppStream authenticateAnonymously:&error]) {
            DDLogError(@"Error authenticating (anonymous): %@", error);
        }
    }
}


#pragma mark - XMPPStreamDelegate
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	NSString *expectedCertName = [self.xmppStream.myJID domain];
	if (expectedCertName) {
		[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
	}
	
	if (self.customCertEvaluation) {
		[settings setObject:@(YES) forKey:GCDAsyncSocketManuallyEvaluateTrust];
	}
}

/**
 * Allows a delegate to hook into the TLS handshake and manually validate the peer it's connecting to.
 *
 * This is only called if the stream is secured with settings that include:
 * - GCDAsyncSocketManuallyEvaluateTrust == YES
 * That is, if a delegate implements xmppStream:willSecureWithSettings:, and plugs in that key/value pair.
 *
 * Thus this delegate method is forwarding the TLS evaluation callback from the underlying GCDAsyncSocket.
 *
 * Typically the delegate will use SecTrustEvaluate (and related functions) to properly validate the peer.
 *
 * Note from Apple's documentation:
 *   Because [SecTrustEvaluate] might look on the network for certificates in the certificate chain,
 *   [it] might block while attempting network access. You should never call it from your main thread;
 *   call it only from within a function running on a dispatch queue or on a separate thread.
 *
 * This is why this method uses a completionHandler block rather than a normal return value.
 * The idea is that you should be performing SecTrustEvaluate on a background thread.
 * The completionHandler block is thread-safe, and may be invoked from a background queue/thread.
 * It is safe to invoke the completionHandler block even if the socket has been closed.
 *
 * Keep in mind that you can do all kinds of cool stuff here.
 * For example:
 *
 * If your development server is using a self-signed certificate,
 * then you could embed info about the self-signed cert within your app, and use this callback to ensure that
 * you're actually connecting to the expected dev server.
 *
 * Also, you could present certificates that don't pass SecTrustEvaluate to the client.
 * That is, if SecTrustEvaluate comes back with problems, you could invoke the completionHandler with NO,
 * and then ask the client if the cert can be trusted. This is similar to how most browsers act.
 *
 * Generally, only one delegate should implement this method.
 * However, if multiple delegates implement this method, then the first to invoke the completionHandler "wins".
 * And subsequent invocations of the completionHandler are ignored.
 **/
- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	// The delegate method should likely have code similar to this,
	// but will presumably perform some extra security code stuff.
	// For example, allowing a specific self-signed certificate that is known to the app.
	
	dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(bgQueue, ^{
		
		SecTrustResultType result = kSecTrustResultDeny;
		OSStatus status = SecTrustEvaluate(trust, &result);
		
		if (status == noErr && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
			completionHandler(YES);
		}
		else {
			completionHandler(NO);
		}
	});
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	self.xmppConnected = YES;
    
    // setup max number of authentication retries.
    self.authenticationRetryCounts = kBBTXMPPAuthenticationRetryMaxAttempts;
    
    [self authenticate];
	
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"myJID: %@", self.xmppStream.myJID);
	
	[self goOnline];
    
    // XMPP Stream is now ready for communication
    // This is a good place to do things that depend on the XMPP Stream being ready.
    // and the user being authenticated
    
    // notify all listeners that we are now authenticated
    [[NSNotificationCenter defaultCenter] postNotificationName:kBBTAuthenticationNotification
                                                        object:self];
    
    // since we successfully authenticated, (re)setup max authentication retries.
    self.authenticationRetryCounts = kBBTXMPPAuthenticationRetryMaxAttempts;
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // Retry authenticating again if XMPP stream still connected and still within
    // allowed by number of retries
    if ([self.xmppStream isConnected] && (self.authenticationRetryCounts-- > 0)) {
        [self authenticate];
    }
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // run this delegate method in background as getting the associated contact
    // blocks the main thread.
    dispatch_queue_t xmppStreamQueue = dispatch_queue_create("XMPP Stream Handling", NULL);
    dispatch_async(xmppStreamQueue, ^{
        
        // only process messages if we're ready to handle them
        if (!self.managedObjectContextChats) return;
        
        // get sender's bare jid which could be a contact or a room
        XMPPJID *senderJID = [[message from] bareJID];
        
        // get contact object but do so in background as this could take some time,
        // block the main thread and crash the app.
        // however can only create this background thread on the main thread.
        __block NSManagedObjectContext *workerContextRoster = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            workerContextRoster = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            workerContextRoster.parentContext = self.managedObjectContextRoster;
            [workerContextRoster setStalenessInterval:0.0]; // no staleness acceptable
        });
        
        __block XMPPUserCoreDataStorageObject *contact = nil;
        [workerContextRoster performBlockAndWait:^{
            contact = [self.xmppRosterStorage userForJID:senderJID
                                              xmppStream:self.xmppStream
                                    managedObjectContext:workerContextRoster];
        }];
        
        [self.managedObjectContextChats performBlock:^{
            // determine appropriate conversation
            id <BBTConversation> conversation = nil;
            if ([message isChatMessage]) {
                conversation = [BBTUser conversationWithContact:contact
                                         inManagedObjectContext:self.managedObjectContextChats];
                
            } else if ([message isGroupChatMessage]) {
                conversation = [BBTGroupConversation groupConversationWithJID:senderJID
                                                       inManagedObjectContext:self.managedObjectContextChats];
            }
            
            
            if ([message isChatMessageWithBody] && ![message isErrorMessage]) {
                // if this is a complete chat message
                // save message in CoreData
                [BBTMessage incomingMessage:[message body]
                                fromContact:senderJID
                             inConversation:conversation
                     inManagedObjectContext:self.managedObjectContextChats];
                
                // notify all listeners that there's a new chat message
                [[NSNotificationCenter defaultCenter] postNotificationName:kBBTMessageNotification
                                                                    object:self
                                                                  userInfo:@{@"conversation":conversation}];
                
                
                // show user a local notification if app is not active.
                if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                    NSString *body = message.body;
                    
                    NSString *displayName = [contact displayName];
                    
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertAction = @"Ok";
                    localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }
                
            } else if ([message hasChatState] && ![message isErrorMessage]) {
                // if this is a chat state notification
                BBTChatState chatState = BBTChatStateUnknown;
                if([message hasComposingChatState])
                    chatState = BBTChatStateComposing;
                else if([message hasPausedChatState])
                    chatState = BBTChatStatePaused;
                else if([message hasActiveChatState])
                    chatState = BBTChatStateActive;
                else if([message hasInactiveChatState])
                    chatState = BBTChatStateInactive;
                else if([message hasGoneChatState])
                    chatState = BBTChatStateGone;
                
                // notify all listeners that there's a new chat state
                [[NSNotificationCenter defaultCenter] postNotificationName:kBBTChatStateNotification
                                                                    object:self
                                                                  userInfo:@{@"chatState":@(chatState),
                                                                             @"conversation":conversation}];
                
            } else if ([message hasReceiptResponse] && ![message isErrorMessage]) {
                // if this is a delivery notification, update the delivery state in CoreData
                NSString *messageId = [message receiptResponseID];
                [BBTMessage receivedDeliveryReceiptForMessageWithIdentifier:messageId
                                                     inManagedObjectContext:self.managedObjectContextChats];
                
            } else if ([message isGroupChatMessageWithSubject] && ![message isErrorMessage]) {
                // Uncomment below to update conversation subject if it's changed.
                // At this time conversation subjects can't be changed after creation so
                // leaving this commented out.
                /*
                 NSString *subject = [message subject];
                 BBTGroupConversation *groupConversation = (BBTGroupConversation *)conversation;
                 if (![groupConversation.subject isEqualToString:subject]) {
                 groupConversation.subject = subject;
                 }
                 */
                
            } else if ([message isGroupChatMessageWithBody] && ![message isGroupChatMessageWithSubject] && ![message isErrorMessage]) {
                // observe that we check for a lack of subject, because some clients send
                // bodies with subject changes.
                
                // only process new messages in the groupchat. Don't want to recreate
                // reflected messages sent by you or duplicate messages in room's history.
                if (![BBTMessage existsGroupMessage:message inRoom:senderJID]) {
                    
                    // save message in CoreData
                    NSString *occupantNickname = [[message from] resource];
                    [BBTMessage incomingGroupMessage:[message body]
                                        fromOccupant:occupantNickname
                                 withRemoteTimestamp:[message delayedDeliveryDate]
                                      inConversation:conversation
                              inManagedObjectContext:self.managedObjectContextChats];
                    
                    // notify all listeners that there's a new groupchat message
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBBTMessageNotification
                                                                        object:self
                                                                      userInfo:@{@"conversation":conversation}];
                }
                
            }
            
        }]; // end [self.managedObjectContextChats performBlock]
    }); // end dispatch_async
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
    
    // if presence type is subscribed then get it out of the contacts' resources
    //   as this causes problems when xmppframework tries to figure out the contact's
    //   availability
    //
    // Details:
    //   When a user accepts a subscription request from a contact, the
    //   contact sends a presence of type "subscribed" to the user. This gets saved
    //   in the roster contact's list of resources. Now when the user is trying to
    //   figure out the contact's availability it does so based on the contact's
    //   primary resource in XMPPUserCoreDataStorageObject's method
    //   `recalculatePrimaryResource`.
    //   When the XMPPResourceCoreDataStorageObject's compare: method is called
    //   it puts a resource with presence of type "subscribed" as the firstObject
    //   in the sorted array because:
    //     * all resource presence values are of same priority (0 in this case)
    //     * the resource with presence of type "subscribed" has a show indicating
    //       available (intShow == 3)
    //
    // Solution:
    //   The `recalculatePrimaryResource` really should filter its list of resources
    //   using the predicateWithFormat:@"presence.type != \"subscribed\""
    //   but it doesn't and I'd rather not change the xmppframework code hence
    //   this workaround.
    //
    // Implementation inspiration from:
    //   - XMPPRosterCoreDataStorage.m:     handlePresence:xmppStream:
    //   - XMPPUserCoreDataStorageObject.m: updateWithPresence:streamBareJidStr
    
    // Note: This won't work till I figure out how to get this scheduleBlock run
    // after those of XMPPRosterCoreDataStorage and XMPPUserCoreDataStorageObject
    /*
    if ([[presence type] isEqualToString:@"subscribed"]) {
        [self.xmppRosterStorage scheduleBlock:^{
            
            XMPPJID *jid = [presence from];
            NSManagedObjectContext *moc = [self.xmppRosterStorage managedObjectContext];
            XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:jid
                                                                          xmppStream:sender
                                                                managedObjectContext:moc];
            
            XMPPResourceCoreDataStorageObject *resource =
                (XMPPResourceCoreDataStorageObject *)[user resourceForJID:[presence from]];
            if (resource) {
                [user removeResourcesObject:resource];
                [[user managedObjectContext] deleteObject:resource];
            }
        }];
    }
     */
    
    
    // When a room owner destroys a room, it sends a presence stanza of type
    //   "unavailable" to each occupant so that the user knows he or she has been
    //   removed from the room.
    // A sample presence stanza when a service removes each occupant, from xep-0045
    //   example 202:
    //  <presence
    //      from='heath@chat.shakespeare.lit/firstwitch'
    //      to='crone1@shakespeare.lit/desktop'
    //      type='unavailable'>
    //      <x xmlns='http://jabber.org/protocol/muc#user'>
    //          <item affiliation='none' role='none'/>
    //          <destroy jid='coven@chat.shakespeare.lit'>
    //              <reason>Macbeth doth come.</reason>
    //          </destroy>
    //      </x>
    //  </presence>
    
    // first check if presence of type unavailable comes from the Conference Server
    if ([[presence type] isEqualToString:@"unavailable"]) {
        if ([[presence from].domain isEqualToString:kBBTXMPPConferenceServer]) {
            
            // now confirm that this room is unavailable because it was destroyed
            // by searching for the <x>...<destroy>...</destroy></x>
            NSXMLElement *x = [presence elementForName:@"x" xmlns:XMPPMUCUserNamespace];
            NSXMLElement *destroy = [x elementForName:@"destroy"];
            if (destroy) {
                // room has been destroyed by its owner (who isn't us) then remove
                // membership from this room
                XMPPJID *roomJID = [[presence from] bareJID];
                BBTGroupConversation *groupConversation = [BBTGroupConversation groupConversationWithJID:roomJID inManagedObjectContext:self.managedObjectContextChats];
                
                if (groupConversation) {
                    // Send out a notification incase a View Controller is currently
                    //   using this groupConversation
                    [[NSNotificationCenter defaultCenter] postNotificationName:kBBTConversationDeleteNotification
                                                                        object:self
                                                                      userInfo:@{@"roomName":groupConversation.roomName}];
                    // and finally delete group conversation if deletion was done
                    // by someone else. The reason we do this check for if deletion
                    // is done by someone else is that in the process of app user deleting
                    // a room we will get this unavailable presence and cleanup will
                    // be done in `xmppRoomDidDestroy:`
                    //
                    // Note that we can't just check for if we aren't the owner as
                    // we could be on another XMPP client and performing the delete.
                    // So check that this isn't in the list of XMPPRooms being destroyed
                    BOOL roomAlreadyBeingDestroyed = NO;
                    for (XMPPRoom *room in self.xmppRoomsToDestroy) {
                        if ([roomJID isEqualToJID:room.roomJID]) {
                            roomAlreadyBeingDestroyed = YES;
                            break;
                        }
                    }
                    if (!roomAlreadyBeingDestroyed) {
                        [self.managedObjectContextChats deleteObject:groupConversation];
                    }
                }
            }
            
        }
        
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!self.isXmppConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
}


#pragma mark - Roster Management
- (void)sendInvitationToJID:(NSString *)jidString
{
    [self.xmppRoster addUser:[XMPPJID jidWithString:jidString] withNickname:nil];
}

#pragma mark - XMPPRosterDelegate
/**
 * Sent when a presence subscription request is received.
 * That is, another user has added you to their roster,
 * and is requesting permission to receive presence broadcasts that you send.
 *
 * The entire presence packet is provided for proper extensibility.
 * You can use [presence from] to get the JID of the user who sent the request.
 *
 * The methods acceptPresenceSubscriptionRequestFrom: and rejectPresenceSubscriptionRequestFrom: can
 * be used to respond to the request.
 **/
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // accept all presence requests so that users requesting friendship show up
    // in our roster. Would be nice if XMPPFramework made it easy to track requests
    // without this weird workaround but it is what it is.
    // User cannot actually initiate chat until there is a subscription state of
    // "both" or "from"
    [self.xmppRoster acceptPresenceSubscriptionRequestFrom:[presence from]
                                            andAddToRoster:NO];
    
    // show user a local notification if app is in background.
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertAction = @"Ok";
        localNotification.alertBody = [NSString stringWithFormat:@"@%@ sent you a friend request",[[presence from] user]];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
}

#pragma mark - XMPPCapabilitiesDelegate
- (NSArray *)myFeaturesForXMPPCapabilities:(XMPPCapabilities *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    return @[@"http://jabber.org/protocol/chatstates"];
}


#pragma mark - Conversation Management
#pragma mark Public
- (void)sendChatState:(BBTChatState)chatState to:(NSString *)jidString
{
    XMPPJID *jid = [XMPPJID jidWithString:jidString];
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:jid];
    BOOL sendMessage = YES;
    switch (chatState) {
        case BBTChatStateActive:
            [message addActiveChatState];
            break;
            
        case BBTChatStateComposing:
            [message addComposingChatState];
            break;
            
        case BBTChatStateGone:
            [message addGoneChatState];
            break;
            
        case BBTChatStateInactive:
            [message addInactiveChatState];
            break;
            
        case BBTChatStatePaused:
            [message addPausedChatState];
            break;
            
        case BBTChatStateUnknown:
            sendMessage = NO;
            break;
            
        default:
            sendMessage = NO;
            break;
    }
    
    if (sendMessage) {
        [self.xmppStream sendElement:message];
    }
}

/**
 * Creating a groupchat conversation starts by creating an XMPP Room with JID of
 * the form <unique name>@<conference server>.
 * A corresponding groupchat conversation is added to CoreData using this unique name 
 * and given subject.
 *
 * Creating the XMPPRoom on the XMPP server is done by joining the room.
 * At this point the room is created but not yet usable as it is not configured.
 * When the XMPP server creates the room, the `xmppRoomDidCreate:` delegate method 
 * is invoked.
 *
 * @see xmppRoomDidCreate:
 */
- (BBTGroupConversation *)createGroupConversationWithSubject:(NSString *)subject
                                                       photo:(UIImage *)photo
                                                    location:(CLLocation *)location
                                                     address:(NSDictionary *)locationAddress
                                                    invitees:(NSArray *)users
{
    // localpart of roomJID has to be unique so will make it a UUID.
    NSString *roomName = [[BBTUtilities uniqueString] lowercaseString];
    
    // roomJID is <localpart>@<conference server>
    NSString *roomJIDBare = [BBTGroupConversation jidForRoomName:roomName];
    // ejabberd stores strings in lowercase so be consistent.
    roomJIDBare = [roomJIDBare lowercaseString];
    
    // Create the groupchat Conversation in CoreData
    BBTGroupConversation *conversation = [BBTGroupConversation groupConversationWithSubject:subject name:roomName location:location address:locationAddress inManagedObjectContext:self.managedObjectContextChats];
    
    // create xmpp room by joining it
   [self joinGroupConversationWithJID:roomJIDBare];
    
    // and log the properties that cannot be used till the xmpp room is fully
    // configured: list of invited users and photo
    if (users) {
        [self.xmppRoomInvitees setObject:users forKey:[self.xmppRoom.roomJID bare]];
    }
    if (photo) {
        [self.xmppRoomPhoto setObject:photo forKey:[self.xmppRoom.roomJID bare]];
    }
    
    // return created conversation.
    return conversation;
}


/**
 * Sync a groupchat conversation with HTTP server after configuring it on XMPP
 * server. This sync sets the conversation's subject, location, photo then sends
 * room invitations.
 *
 * @param conversation: Groupchat conversation that has been configured but is
 *      yet to be sync'd with HTTP server.
 */
- (void)syncGroupConversationAfterConfiguration:(BBTGroupConversation *)conversation
{
    // get cached room photo
    NSString *roomJID = [conversation jidStr];
    UIImage *roomPhoto = [self.xmppRoomPhoto objectForKey:roomJID];
    
    // set subject, location and photo on HTTP server
    NSString *roomDetailURL = [BBTHTTPManager roomDetailURL:conversation.roomName];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:conversation.subject forKey:kBBTRESTRoomSubjectKey];
    
    NSDictionary *locationJSON = [conversation locationToJSON];
    if (locationJSON) {
        [parameters setObject:locationJSON forKey:kBBTRESTRoomLocationKey];
    }
    
    if (roomPhoto) {
        // AFNetworking form data expects JSON dictionaries to be converted to NSData
        if (locationJSON) {
            NSData *locationJSONData = [NSJSONSerialization dataWithJSONObject:locationJSON
                                                                       options:0
                                                                         error:NULL];
            // never insert a nil object into a dictionary so do one more sanity check
            if (locationJSONData) {
                [parameters setObject:locationJSONData forKey:kBBTRESTRoomLocationKey];
            }
        }
        
        // make a multi-part data request with attached room photo.
        [[BBTHTTPManager sharedManager] operationRequest:BBTHTTPMethodPUT
                                                  forURL:roomDetailURL
                                              parameters:[parameters copy]
                               constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                   NSString *fileName = [NSString stringWithFormat:@"%@.jpg", conversation.roomName];
                                   [formData appendPartWithFileData:UIImageJPEGRepresentation(roomPhoto, 1.0)
                                                               name:kBBTRESTRoomPhotoKey
                                                           fileName:fileName
                                                           mimeType:@"image/jpeg"];
                               }
                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                     [self xmppRoom:conversation didSync:responseObject];
                                                 }
                                                 failure:nil];
        
    } else {
        [[BBTHTTPManager sharedManager] request:BBTHTTPMethodPUT
                                         forURL:roomDetailURL
                                     parameters:parameters
                                        success:^(NSURLSessionDataTask *task, id responseObject) {
                                            [self xmppRoom:conversation didSync:responseObject];
                                        }
                                        failure:nil];
    }
    
    // now discard of data that's no longer of use
    [self.xmppRoomPhoto removeObjectForKey:roomJID];
}

/**
 * Join an XMPP Room of a specified JID.
 * If XMPP room doesnt exist it will be created so use this with caution.
 * XMPPRoom will be activated, this class will be its delegate, and this room will
 *   be tracked in the xmppRoom property
 *
 * @param roomJIDBare   Bare JID of the room.
 */
- (void)joinGroupConversationWithJID:(NSString *)roomJIDBare
{
    // get roomJID object
    XMPPJID *roomJID = [XMPPJID jidWithString:roomJIDBare];
    
    // Get the nickname to be used for xmpp operations.
    NSString *nickname = self.xmppNickname;
    
    if ([roomJID isEqualToJID:self.xmppRoom.roomJID] && self.xmppRoom.isJoined
        && ([self.xmppRoom.myNickname isEqualToString:nickname])) {
        // if already an occupant of this room there's nothing further to do
        return;
    }
    
    // create XMPPRoom object, re-initialize xmppRoom, activate it and add
    // ourself as a delegate
    self.xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomStorage
                                                           jid:roomJID];
    [self.xmppRoom activate:self.xmppStream];
    [self.xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppRoom joinRoomUsingNickname:nickname history:nil];
}

- (void)leaveGroupConversationWithJID:(XMPPJID *)roomJID
{
    // only leave groupConversation if actively in it
    if ([self.xmppRoom.roomJID isEqualToJID:roomJID]) {
        [self.xmppRoom leaveRoom];
        self.xmppRoom = nil; // don't forget delegate cleanup
    }
}

- (void)revokeGroupConversationMembership:(XMPPJID *)roomJID andDestroy:(BOOL)destroy
{
    [self revokeGroupConversationMembership:roomJID andDestroy:destroy withRevokeOnlySuccess:nil];
}

- (void)revokeGroupConversationMembership:(XMPPJID *)roomJID andDestroy:(BOOL)destroy withRevokeOnlySuccess:(void (^)())membershipRevoked
{
    if (destroy) {
        // If room is to be destroyed, then destroying/deleing the room covers
        // revoking of membership
        XMPPRoom *roomToDestroy = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomStorage
                                                                    jid:roomJID];
        [roomToDestroy activate:self.xmppStream];
        [roomToDestroy addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.xmppRoomsToDestroy addObject:roomToDestroy];
        [roomToDestroy destroyRoom];
        
    } else {
        // All that has to be done is revoke group membership on HTTP server
        NSString *roomName = [roomJID user];
        NSString *username = [BBTHTTPManager sharedManager].username;
        NSString *roomDetailMemberURL = [BBTHTTPManager roomDetailURL:roomName member:username];
        
        [[BBTHTTPManager sharedManager] request:BBTHTTPMethodDELETE forURL:roomDetailMemberURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            if (membershipRevoked) membershipRevoked();
        } failure:nil];
    }
}


/**
 * Invite contacts to an xmppRoom of specified JID
 *
 * @param roomJID   bare JID of room of interest
 * @param contacts  array of XMPPUserCoreDataStorageObject users to be invited
 */
- (void)sendRoomInvitations:(XMPPJID *)roomJID toContacts:(NSArray *)contacts;
{
    // do nothing if there's neither a room JID nor contacts
    if (!roomJID || !contacts) return;
    
    // Get associated xmppRoom
    XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomStorage
                                                           jid:roomJID];
    [xmppRoom activate:self.xmppStream];
    
    // and now invite all partipants
    for (XMPPUserCoreDataStorageObject *user in contacts) {
        [xmppRoom inviteUser:user.jid withMessage:nil];
    }
}

#pragma mark Private
/**
 * Unfortunately XMPPRoom.m hasn't implemented [XMPPRoom -changeRoomSubject] so will
 *   roll out my own solution for now
 *
 * @param newRoomSubject    new room subject
 * @param room              XMPPRoom to be modified
 */
- (void)changeRoomSubject:(NSString *)newRoomSubject xmppRoom:(XMPPRoom *)room
{
    // <message to='coven@chat.shakespeare.lit' type='groupchat'>
    //   <subject>Fire Burn and Cauldron Bubble!</subject>
    // </message>
    
    NSXMLElement *subject = [NSXMLElement elementWithName:@"subject" stringValue:newRoomSubject];
    
    XMPPMessage *message = [XMPPMessage messageWithType:@"groupchat"];
    [message addAttributeWithName:@"to" stringValue:[room.roomJID full]];
    [message addChild:subject];
    
    [self.xmppStream sendElement:message];
}


#pragma mark - XMPPMUCDelegate
- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *)roomJID didReceiveInvitation:(XMPPMessage *)message
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // You've been invited to a room, so what you do here is refresh room details
    // (from HTTP server) and then save it in coredata with a membership status
    // indicating we've only been invited but haven't established membership
    
    // Get updated room info from server
    NSString *roomDetailURL = [BBTHTTPManager roomDetailURL:[roomJID user]];
    
    [[BBTHTTPManager sharedManager] request:BBTHTTPMethodGET
                                     forURL:roomDetailURL
                                 parameters:nil
                                    success:^(NSURLSessionDataTask *task, id responseObject)
    {
        // Add/Update the room in Core Data
        BBTGroupConversation *conversation = [BBTGroupConversation groupConversationWithRoomInfo:responseObject inManagedObjectContext:self.managedObjectContextChats];
        
        // set membership status to invited if not already affiliated
        if ([conversation.membership integerValue] == BBTGroupConversationMembershipNone) {
            conversation.membership = @(BBTGroupConversationMembershipInvited);
            
            // post notification to update associated UI badges
            [[NSNotificationCenter defaultCenter] postNotificationName:kBBTConversationsUpdateNotification object:self];
            
            // show user a local notification if app is in background.
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.alertAction = @"Ok";
                localNotification.alertBody = [NSString stringWithFormat:@"Invited to thread: %@", conversation.subject];
                localNotification.soundName = UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject)
    {
        // pass
    }];
}

- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *)roomJID didReceiveInvitationDecline:(XMPPMessage *)message
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}


#pragma mark - XMPPRoomDelegate
- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    // notify all listeners that room has been joined
    [[NSNotificationCenter defaultCenter] postNotificationName:kBBTConversationJoinNotification
                                                        object:self
                                                      userInfo:@{@"room":sender}];
}


- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // now we can configure the room by accepting default configurations
    [sender configureRoomUsingOptions:nil];
    
    // and update conversation status
    BBTGroupConversation *conversation = [BBTGroupConversation groupConversationWithJID:[sender.roomJID bareJID] inManagedObjectContext:self.managedObjectContextChats];
    conversation.status = @(BBTGroupConversationStatusCreated);
}

- (void)xmppRoom:(XMPPRoom *)sender didConfigure:(XMPPIQ *)iqResult
{
    // Room created and configured
    // Now we can set subject and photo before inviting appropriate participants.
    // The relevant data is stored in coredata
    BBTGroupConversation *conversation = [BBTGroupConversation groupConversationWithJID:[sender.roomJID bareJID] inManagedObjectContext:self.managedObjectContextChats];
    conversation.status = @(BBTGroupConversationStatusConfigured);
    
    // change subject on XMPP server
    [self changeRoomSubject:conversation.subject xmppRoom:sender];
    
    // and finally sync conversation's details with HTTP server
    [self syncGroupConversationAfterConfiguration:conversation];
}

- (void)xmppRoom:(XMPPRoom *)sender didNotConfigure:(XMPPIQ *)iqResult
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoomDidDestroy:(XMPPRoom *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    // When a room is destroyed via xmpp, go ahead and delete it on the server
    // and from local storage
    //
    // You might wonder, how on earth we are able to delete it on the server, given
    // that ejabberd should have done so. Well the many-to-many relationships I've
    // added to `muc_room` (members and likes) cause psql to throw this error:
    // update or delete on table "muc_room" violates foreign key constraint on
    // table "muc_room_members".
    //
    // This is good because it ensures proper cleanup like deletion of image files.
    //
    BBTGroupConversation *conversation = [BBTGroupConversation groupConversationWithJID:[sender.roomJID bareJID] inManagedObjectContext:self.managedObjectContextChats];
    
    // webserver cleanup
    NSString *roomDetailURL = [BBTHTTPManager roomDetailURL:conversation.roomName];
    
    [[BBTHTTPManager sharedManager] request:BBTHTTPMethodDELETE
                                     forURL:roomDetailURL
                                 parameters:nil
                                    success:^(NSURLSessionDataTask *task, id responseObject) {
                                        // sync deletion with a local storage cleanup
                                        [self.managedObjectContextChats deleteObject:conversation];
                                    }
                                    failure:nil];
    
    
    // finally done with XMPPRoom so deactivate it, stop acting as its delegate
    // and stop actively tracking it
    // first find it
    XMPPRoom *xmpppRoomToDestroy = nil;
    for (XMPPRoom *room in self.xmppRoomsToDestroy) {
        if ([sender.roomJID isEqualToJID:room.roomJID]) {
            xmpppRoomToDestroy = room;
            break;
        }
    }
    // then perform cleanup
    if (xmpppRoomToDestroy) {
        [xmpppRoomToDestroy removeDelegate:self];
        [xmpppRoomToDestroy deactivate];
        [self.xmppRoomsToDestroy removeObject:xmpppRoomToDestroy];
    }
}

#pragma mark Helper
/**
 * After successful XMPPRoom is configured we upload the room data (subject, photo)
 * to the server and when this completes the room's status is considered as synced.
 * When this completes successfully, this method is called
 *
 * @param conversation      Groupchat instance in Core Data
 * @param responseObject    Room details from HTTP server.
 */
- (void)xmppRoom:(BBTGroupConversation *)conversation didSync:(id)responseObject
{
    // sync received room with local object
    [BBTGroupConversation groupConversationWithRoomInfo:responseObject
                                 inManagedObjectContext:conversation.managedObjectContext];
    
    
    // Create the room JID
    XMPPJID *roomJID = [conversation jid];
    // Get associated xmppRoom
    XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self.xmppRoomStorage
                                                           jid:roomJID];
    [xmppRoom activate:self.xmppStream];
    
    // and now invite all partipants
    NSArray *roomInvitees = [self.xmppRoomInvitees objectForKey:[conversation jidStr]];
    for (XMPPUserCoreDataStorageObject *user in roomInvitees) {
        [xmppRoom inviteUser:user.jid withMessage:nil];
    }
    
    // notify all listeners that conversation has been sync'd
    [[NSNotificationCenter defaultCenter] postNotificationName:kBBTConversationSyncNotification
                                                        object:self
                                                      userInfo:@{@"conversation":conversation}];
    
    // now discard of data that's no longer of use
    [self.xmppRoomInvitees removeObjectForKey:roomJID];
    [xmppRoom deactivate];
}

#pragma mark - XMPPvCardTempModuleDelegate
- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule didReceivevCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if (vCardTemp.formattedName) {
        
        // if there's a display name in vCard, set nickname of corresponding user.
        // Trying to do this using the provided managedObjectContextRoster causes
        // crashes on the start of a newly installed app, hence using the custom
        // function that's based off of `setPhoto:forUserWithJID:xmppStream:`
        [self.xmppRosterStorage setNickname:vCardTemp.formattedName forUserWithJID:[jid bareJID] xmppStream:self.xmppStream];
    }
    
    // XMPPvCardAvatarModule should be clearing out photos when a vCard comes without
    // one, however it doesn't. It explicitly only checks for cases of vCards with
    // photos. This means if a contact deletes a photo, app user doesn't get notified
    // until reconnect. Well don't try fixing that here, as this messes with tracking
    // of user's availability
}

@end
