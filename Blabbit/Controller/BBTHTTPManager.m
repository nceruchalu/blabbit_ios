//
//  BBTHTTPManager.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/20/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTHTTPManager.h"
#import "BBTHTTPSessionManager.h"
#import "KeychainItemWrapper.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "BBTXMPPManager.h"
#import "BBTJSONResponseSerializer.h"
#import "BBTUser+HTTP.h"
#import "BBTGroupConversation+XMPP.h"
#import "AFHTTPRequestOperation.h"
#import "AFHTTPRequestOperationManager.h"
#import "BBTModelManager.h"


@interface BBTHTTPManager ()

// want all properties to be readwrite (privately)
@property (nonatomic, readwrite, getter=isHTTPAuthenticated) BOOL httpAuthenticated;

// private properties
@property (strong, nonatomic, readwrite) BBTHTTPSessionManager *httpSessionManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *httpOperationManager;
@property (strong, nonatomic) KeychainItemWrapper *keychain;
/**
 * authenticationToken is an authenticated user's authentication token
 */
@property (strong, nonatomic, readonly) NSString *authenticationToken;

@end

@implementation BBTHTTPManager

#pragma mark - Properties
#pragma mark Public
- (NSString *)username
{
    return [self.keychain objectForKey:(__bridge id)(kSecAttrAccount)];
}

- (NSString *)password
{
    return [self.keychain objectForKey:(__bridge id)kSecValueData];
}

- (void)setPassword:(NSString *)password
{
    [self.keychain setObject:password forKey:(__bridge id)(kSecValueData)];
}

#pragma mark Private
- (NSString *)authenticationToken
{
    // value changes frequently so no room for lazy instantiation
    return  [self.keychain objectForKey:(__bridge id)(kSecAttrGeneric)];
}


#pragma mark - Class methods
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static BBTHTTPManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}


+ (void)alertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
}


+ (void)alertWithFailedResponse:(id)responseObject withAlternateTitle:(NSString *)title andMessage:(NSString *)message
{
    // alert user of any error and include any responseObject data
    
    if (responseObject) {
        
        // get any field that has errors and its corresponding error(s)
        NSString *errorField = [[responseObject allKeys] objectAtIndex:0];
        id errorFieldValue = [responseObject objectForKey:errorField];
        
        // This corresponding error is to be converted to a message be
        // it an array or a string.
        NSString *errorMessage = @"";
        if ([errorFieldValue isKindOfClass:[NSArray class]]) {
            errorMessage = [((NSArray *)errorFieldValue) firstObject];
        } else if ([errorFieldValue isKindOfClass:[NSString class]]) {
            errorMessage = (NSString *)errorFieldValue;
        }
        
        // finally show the UIAlertView
        [BBTHTTPManager alertWithTitle:[NSString stringWithFormat:@"Problem with %@",errorField]
                     message:errorMessage];
        
    } else {
        // use alternate title and message
        [BBTHTTPManager alertWithTitle:title message:message];
    }
}

+ (NSString *)roomDetailURL:(NSString *)roomName
{
    return [NSString stringWithFormat:@"%@%@/",kBBTRESTRooms, roomName];
}

+ (NSString *)roomDetailURL:(NSString *)roomName member:(NSString *)username
{
    NSString *roomDetailURL = [BBTHTTPManager roomDetailURL:roomName];
    return [NSString stringWithFormat:@"%@%@%@/", roomDetailURL, kBBTRESTRoomMembers, username];
}

+ (NSString *)roomDetailURL:(NSString *)roomName like:(NSString *)username
{
    NSString *roomDetailURL = [BBTHTTPManager roomDetailURL:roomName];
    return [NSString stringWithFormat:@"%@%@%@/", roomDetailURL, kBBTRESTRoomLikes, username];
}

+ (NSString *)roomDetailURLFlag:(NSString *)roomName
{
    NSString *roomDetailURL = [BBTHTTPManager roomDetailURL:roomName];
    return [NSString stringWithFormat:@"%@%@", roomDetailURL, kBBTRESTRoomFlag];
}


#pragma mark - Initialization
// ideally we would make the designated initializer of the superclass call
//   the new designated initializer, but that doesn't make sense in this case.
// if a programmer calls [BBTHTTPManager alloc] init], let him know the error
//   of his ways.
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use + [BBTHTTPMananger sharedManager]"
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
        
        // setup httpSessionManager
        NSURL *baseURL = [NSURL URLWithString:kBBTHTTPBaseURL];
        self.httpSessionManager = [[BBTHTTPSessionManager alloc] initWithBaseURL:baseURL];
        
        self.httpSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        self.httpSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        [self.httpSessionManager.requestSerializer setValue:@"application/json"
                                         forHTTPHeaderField:@"Accept"];
        [self.httpSessionManager.requestSerializer setValue:@"application/json"
                                         forHTTPHeaderField:@"Content-Type"];
        
        // setup httpOperationManager with same configs
        self.httpOperationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
        self.httpOperationManager.responseSerializer = [AFJSONResponseSerializer serializer];
        self.httpOperationManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        [self.httpOperationManager.requestSerializer setValue:@"application/json"
                                         forHTTPHeaderField:@"Accept"];
        [self.httpOperationManager.requestSerializer setValue:@"application/json"
                                         forHTTPHeaderField:@"Content-Type"];
        
        
        // setup keychain... will be accessing it a lot here.
        self.keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kBBTLoginKeychainIdentifier
                                                            accessGroup:nil];
        
        // easy management of the network activity indicator
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    }
    return self;
}


#pragma mark - Instance methods
#pragma mark Private
/**
 * Add an authorization header to the HTTP Request if current user is authenticated
 * "Authorization" HTTP header is of the form:
 *    Authorization: Token 401f7ac837da42b97f613d789819ff93537bee6a
 *
 * Clear authorization header if the user is not authenticated.
 */
- (void)addAuthorizationHeader
{
    if (self.isHTTPAuthenticated) {
        NSString *authorizationHeader = [NSString stringWithFormat:@"Token %@", self.authenticationToken];
        [self.httpSessionManager.requestSerializer setValue:authorizationHeader
                                         forHTTPHeaderField:@"Authorization"];
        [self.httpOperationManager.requestSerializer setValue:authorizationHeader
                                           forHTTPHeaderField:@"Authorization"];
    } else {
        [self clearAuthorizationHeader];
    }
}

/**
 * Remove authorization header used for HTTP Requests. Good idea to call this
 * when clearing credentials, i.e. resetting keychain.
 */
- (void)clearAuthorizationHeader
{
    [self.httpSessionManager.requestSerializer clearAuthorizationHeader];
    [self.httpOperationManager.requestSerializer clearAuthorizationHeader];
}


#pragma mark Public
- (NSURLSessionDataTask *)request:(BBTHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
{
    [self addAuthorizationHeader];
    
    // call corresponding BBTHTTPSessionManager method
    return [self.httpSessionManager request:httpMethod forURL:URLString parameters:parameters success:success failure:failure];
}


- (NSURLSessionDataTask *)request:(BBTHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
        constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
{
    [self addAuthorizationHeader];
    
    // call corresponding BBTHTTPSessionManager method
    return [self.httpSessionManager request:httpMethod forURL:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

- (AFHTTPRequestOperation *)operationRequest:(BBTHTTPMethod)httpMethod
                                      forURL:(NSString *)URLString
                                  parameters:(id)parameters
                   constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self addAuthorizationHeader];
    
    // only POST, PUT, PATCH allowed
    if (!((httpMethod == BBTHTTPMethodPOST) ||
          (httpMethod == BBTHTTPMethodPUT) || (httpMethod == BBTHTTPMethodPATCH))) {
        return nil;
    }
    
    // get the appropriate HTTP Request method String
    NSString *httpRequestMethod = [BBTHTTPSessionManager httpMethodToString:httpMethod];
    
    // Now run through the Operation
    NSMutableURLRequest *request = [self.httpOperationManager.requestSerializer multipartFormRequestWithMethod:httpRequestMethod URLString:[[NSURL URLWithString:URLString relativeToURL:self.httpOperationManager.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:nil];

    AFHTTPRequestOperation *operation = [self.httpOperationManager HTTPRequestOperationWithRequest:request success:success failure:failure];
    
    [self.httpOperationManager.operationQueue addOperation:operation];
    
    return operation;
}


- (NSURLSessionDataTask *)imageFromURL:(NSString *)URLString
                               success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                               failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure;
{
    BBTHTTPSessionManager *imageHttpSessionManager = [[BBTHTTPSessionManager alloc] init];
    imageHttpSessionManager.responseSerializer = [AFImageResponseSerializer serializer];
    
    return [imageHttpSessionManager request:BBTHTTPMethodGET forURL:URLString parameters:nil success:success failure:failure];
}


- (void)authenticateUsername:(NSString *)username
                    password:(NSString *)password
                     success:(void (^)())success
                     failure:(void (^)())failure
{
    NSDictionary *parameters = @{kBBTRESTUserUsernameKey : username,
                                 kBBTRESTUserPasswordKey : password};
    
    // save username/password as provided. This is important so that if a user
    // enters invalid credentials they can't just restart the app and get automatically
    // logged in with the accurate credentials.
    [self.keychain setObject:username forKey:(__bridge id)(kSecAttrAccount)];
    [self.keychain setObject:password forKey:(__bridge id)(kSecValueData)];
    
    [self request:BBTHTTPMethodPOST
           forURL:kBBTRESTObtainAuthToken
       parameters:parameters
          success:^(NSURLSessionDataTask *task, id responseObject) {
              self.httpAuthenticated = YES;
              
              // extract token and save it
              NSString *authenticationToken = [responseObject objectForKey:@"token"];
              [self.keychain setObject:authenticationToken forKey:(__bridge id)(kSecAttrGeneric)];
              
              
              [[BBTModelManager sharedManager] setupDocumentForUser:username completionHandler:^{
                  // Connect to xmpp server when our managedObjectContext is ready.
                  // Wait for the context because the XMPP manager heavily depends
                  // on the existence of the app's model.
                  [[BBTXMPPManager sharedManager] connect];
                  
                  // Now that we have a context and are authenticated we can
                  // sync the contacts and the groupchats
                  [self setupContacts];
                  [self setupRooms:nil];
                  [self fetchPopularConversations:nil];
              }];
              
              
              // finally execute callback;
              if (success) success();
          }
          failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
              self.httpAuthenticated = NO;
              // execute callback
              if (failure) failure();
          }
     ];
}

- (void)authenticateWithSuccess:(void (^)())success failure:(void (^)())failure;
{
    // only bother an authentication attempt if there's a saved username and password
    if ([self.username length] && [self.password length]) {
        [self authenticateUsername:self.username
                          password:self.password
                           success:^{
                               if (success) success();
                           }
                           failure:^{
                               // failed to authentiate with current credentials
                               // so maybe prompt user to sign in
                               if (failure) failure();
                           }
         ];
    
    } else {
        // unable to authenticate
        // so maybe prompt user to sign in
        if (failure) failure();
    }
}

- (void)operateAnonymously
{
    // sign out incase user is still signed in
    self.httpAuthenticated = NO;
    [self.keychain resetKeychainItem];
    [self clearAuthorizationHeader];
    
    // connect to xmpp server anonymously when our managedObjectContext is ready
    // Do this because the XMPP manager heavily depends on the existence
    // of the app's model.
    [[BBTModelManager sharedManager] setupDocumentForUser:nil completionHandler:^{
        [[BBTXMPPManager sharedManager] connectAnonymous];
        
        // Unauthenticated users still get to see the popular groupchats so sync that
        [self fetchPopularConversations:nil];
    }];
}

- (void)showSignInVC:(BOOL)animated
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        UIViewController *rootViewController = [[UIApplication sharedApplication].delegate window].rootViewController;
        NSString *segueIdentifier = animated ? @"showSignInAnimated" : @"showSignIn";
        [rootViewController performSegueWithIdentifier:segueIdentifier
                                                sender:rootViewController];
    });
}

- (void)startSignIn
{
    [self signOut];
}

- (void)signOut
{
    [[BBTXMPPManager sharedManager] disconnect];
    self.httpAuthenticated = NO;
    [self.keychain resetKeychainItem];
    [self clearAuthorizationHeader];
    
    // coredata managed object context depends on current user's authentication
    // status
    [[BBTModelManager sharedManager] closeUserDocument:^{
        [self showSignInVC:YES];
    }];
}

/**
 * Get the user's contacts from the server after successful authentication, and
 * save in CoreData. So this depends on managed object context being setup.
 * Observe that we use a background thread context so as not to block the main queue
 */
- (void)setupContacts
{
    // don't proceed if managedObjectContext isn't setup
    if (![BBTModelManager sharedManager].managedObjectContext) return;
    
    [self request:BBTHTTPMethodGET
           forURL:kBBTRESTUserContacts
       parameters:nil
          success:^(NSURLSessionDataTask *task, id responseObject) {
              
              // get array of user dictionaries in response
              NSArray *contactsJSON = [responseObject objectForKey:kBBTRESTListResultsKey];
              
              NSManagedObjectContext *workerContext = [BBTModelManager sharedManager].workerContext;
              if (workerContext) {
                  [workerContext performBlock:^{
                      [BBTUser usersWithUserInfoArray:contactsJSON
                               inManagedObjectContext:workerContext];
                      
                      // Push changes up to main thread context
                      [workerContext save:NULL];
                      
                      // turn all objects into faults
                      /*
                       for (BBTUser *user in contacts) {
                       [workerContext refreshObject:user mergeChanges:NO];
                       }*/
                      // ensure context is cleaned up for next user
                      [workerContext reset];
                  }];
              }
              
          }
          failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
              // pass
          }];
}

/**
 * Perform setup by getting the authenticated user's rooms from the server and
 * sync this with what's in our local Core Data storage.
 *
 * Observe that we only use a background thread context so as not to block the
 * main thread
 *
 * The assumption is that this method is only called when self.managedObjectContext
 * is setup
 */
- (void)setupRooms:(void (^)())roomsAreSetup
{
    // don't proceed if managedObjectContext isn't setup or user isn't authenticated
    if (![BBTModelManager sharedManager].managedObjectContext || !self.isHTTPAuthenticated) {
        // execute the callback block
        if (roomsAreSetup) roomsAreSetup();
        // then return
        return;
    }
    
    [self request:BBTHTTPMethodGET
           forURL:kBBTRESTUserRooms
       parameters:nil
          success:^(NSURLSessionDataTask *task, id responseObject) {
              
              // get array of room dictionaries in response
              NSArray *roomsJSON = [responseObject objectForKey:kBBTRESTListResultsKey];
              
              // Use worker context
              NSManagedObjectContext *workerContext = [BBTModelManager sharedManager].workerContext;
              if (workerContext) {
                  [workerContext performBlock:^{
                      // update membership the groupchats that you aren't still a member of
                      [BBTGroupConversation removeMembershipOfGroupConversationsNotInRoomInfoArray:roomsJSON inManagedObjectContext:workerContext];
                      
                      // now setup the appropriate groupchat conversations
                      NSArray *groupConversations = [BBTGroupConversation groupConversationsWithRoomInfoArray:roomsJSON inManagedObjectContext:workerContext];
                      
                      // update membership of these groupchat conversations that you
                      // are still a member of
                      for (BBTGroupConversation *conversation in groupConversations) {
                          conversation.membership = @(BBTGroupConversationMembershipMember);
                      }
                      
                      // Push changes up to main thread context
                      [workerContext save:NULL];
                      
                      // turn all objects into faults
                      /*
                       for (BBTGroupConversation *conversation in groupConversations) {
                       [workerContext refreshObject:conversation mergeChanges:NO];
                       }
                       for (BBTGroupConversation *conversation in revokedMembershipGroupConversation) {
                       [workerContext refreshObject:conversation mergeChanges:NO];
                       }*/
                      // ensure context is cleaned up for next user
                      [workerContext reset];
                      
                      // finally execute the callback block on main queue
                      dispatch_async(dispatch_get_main_queue(), ^{
                          if (roomsAreSetup) roomsAreSetup();
                      });
                  }];
              } else {
                  if (roomsAreSetup) roomsAreSetup();
              }
          }
          failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
              // do nothing but execute the callback block
              if (roomsAreSetup) roomsAreSetup();
          }];
}

/**
 * Fetch popular groupchat conversations from webserver.
 *
 * The assumption is that this method is only called when the managedObjectContext
 * is setup
 *
 * @param conversationsFetched  block to be called after fetching rooms, regardless
 *      of success or failure. This is run on the main queue.
 */
- (void)fetchPopularConversations:(void (^)())conversationsFetched
{
    // don't proceed if managedObjectContext isn't setup
    if (![BBTModelManager sharedManager].managedObjectContext) {
        // execute the callback block
        if (conversationsFetched) conversationsFetched();
        // then return
        return;
    }

    // Get popular objects from server.
    [self request:BBTHTTPMethodGET
           forURL:kBBTRESTExplorePopular
       parameters:nil
          success:^(NSURLSessionDataTask *task, id responseObject) {
              // get array of room dictionaries in response
              NSArray *popularRoomsJSON = [responseObject objectForKey:kBBTRESTListResultsKey];
              
              // put these objects in core data using worker context
              NSManagedObjectContext *workerContext = [BBTModelManager sharedManager].workerContext;
              if (workerContext) {
                  [workerContext performBlock:^{
                      [BBTGroupConversation groupConversationsWithRoomInfoArray:popularRoomsJSON inManagedObjectContext:workerContext];
                      
                      // Push changes up to main thread context
                      [workerContext save:NULL];
                      
                      // turn all objects into faults
                      /*
                       for (BBTGroupConversation *conversation in groupConversations) {
                       [workerContext refreshObject:conversation mergeChanges:NO];
                       }
                       */
                      // ensure context is cleaned up for next user
                      [workerContext reset];
                      
                      // finally execute the callback block on main queue
                      dispatch_async(dispatch_get_main_queue(), ^{
                          if (conversationsFetched) conversationsFetched();
                      });
                  }];
              } else {
                   if (conversationsFetched) conversationsFetched();
              }
          }
          failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
              // do nothing but execute the callback block
              if (conversationsFetched) conversationsFetched();
          }];
}


@end
