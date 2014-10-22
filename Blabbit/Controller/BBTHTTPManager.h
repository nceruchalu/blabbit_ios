//
//  BBTHTTPManager.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/20/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFURLRequestSerialization.h"

@class AFHTTPSessionManager;
@class AFHTTPRequestOperation;

/**
 * A singleton class that manages all HTTP interactions and user authentication
 * Having just one instance of this class throughout the application ensures all
 *   data stays synced.
 */
@interface BBTHTTPManager : NSObject

#pragma mark -  Properties
/**
 * Indicator of the current HTTP Authentication status.
 * If YES then the user is identified by a username/password
 * If NO then the user is operating as an anonymous user
 */
@property (nonatomic, readonly, getter=isHTTPAuthenticated) BOOL httpAuthenticated;

/**
 * Authenticated user's username
 */
@property (strong, nonatomic, readonly) NSString *username;

/**
 * Authenticated user's password.
 */
@property (strong, nonatomic) NSString *password;

#pragma mark - Class Methods
/**
 * Single instance manager.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized BBTHTTPManager object.
 */
+ (instancetype)sharedManager;

/**
 * Show an alert with given title and message.
 * The alert has only a cancel button with fixed text "OK".
 *
 * @param title     alert view title
 * @param message   alert view message
 */
+ (void)alertWithTitle:(NSString *)title message:(NSString *)message;


/**
 * Show an alert for a given response object following a failed HTTP Request.
 * Provide alternate messaging in the event the responseObject is empty or cannot
 * be parsed
 *
 * @param responseObject    HTTP response object from failed response
 * @param title             Alternate title to be used if response object can't be used.
 * @param message           Alternate message to be used if response object can't be used.
 */
+ (void)alertWithFailedResponse:(id)responseObject withAlternateTitle:(NSString *)title andMessage:(NSString *)message;


#pragma mark Generate REST API URLs
/**
 * Generate the relative URL for a REST API's room detail
 *
 * @param roomName  name of room of interest
 *
 * @return relative URL
 */
+ (NSString *)roomDetailURL:(NSString *)roomName;

/**
 * Generate the relative URL for a REST API's room member detail
 *
 * @param roomName   name of room of interest
 * @param username   username of member of interest
 *
 * @return relative URL
 */
+ (NSString *)roomDetailURL:(NSString *)roomName member:(NSString *)username;

/**
 * Generate the relative URL for a REST API's room liker detail
 *
 * @param roomName   name of room of interest
 * @param username   username of room liker of interest
 *
 * @return relative URL
 */
+ (NSString *)roomDetailURL:(NSString *)roomName like:(NSString *)username;

/**
 * Generate the relative URL for REST API's room flagging
 *
 * @param roomName   name of room of interest
 * @return relative URL
 */
+ (NSString *)roomDetailURLFlag:(NSString *)roomName;


#pragma mark - Instance Methods

/**
 Creates and runs an `NSURLSessionDataTask` with a <HTTP Method> request.
 This is just a wrapper to BBTHTTPSessionManager's HTTP Method requests.
 The value-add here is setting the request headers appropriately on each call
 
 @param httpMethod
    HTTP request method (GET, POST, PUT, DELETE, etc)
 @param URLString   
    The relative (to REST API's base URL) URL string used to create the request 
    URL.
 @param parameters  
    The parameters to be encoded according to the client request serializer.
 @param success 
    A block object to be executed when the task finishes successfully.
    This block has no return value and takes two arguments: the data task, and 
    the response object created by the client response serializer.
 @param failure 
    A block object to be executed when the task finishes unsuccessfully,
    or that finishes successfully, but encountered an error while parsing the 
    response data. This block has no return value and takes three arguments: the
    data task, the error describing the network or parsing error that occurred, and
    the response object created by the client response serializer.
 
 @see -dataTaskWithRequest:completionHandler:
 */
- (NSURLSessionDataTask *)request:(BBTHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure;



/**
 * Creates and runs an `NSURLSessionDataTask` with a multipart `POST`/`PUT`/`PATCH`
 * request.
 * This is just a wrapper to BBTHTTPSessionManager's HTTP Method requests.
 * The value-add here is setting the request headers appropriately on each call
 *
 * @param httpMethod
 *      HTTP request method (POST, PUT, PATCH)
 * @param URLString
 *      The URL string used to create the request URL.
 * @param parameters
 *      The parameters to be encoded according to the client request serializer.
 * @param block
 *      A block that takes a single argument and appends data to the HTTP body.
 *      The block argument is an object adopting the `AFMultipartFormData` protocol.
 * @param success
 *      A block object to be executed when the task finishes successfully. This
 *      block has no return value and takes two arguments: the data task, and the
 *      response object created by the client response serializer.
 * @param failure
 *      A block object to be executed when the task finishes unsuccessfully, or
 *      that finishes successfully, but encountered an error while parsing the
 *      response data. This block has no return value and takes three arguments:
 *      the data task, the error describing the network or parsing error that
 *      occurred, and the response object created by the client response serializer.
 *
 * @see -dataTaskWithRequest:completionHandler:
 *
 * @warning you probably want to use the `AFHTTPRequestOperation` counterpart. 
 *      This has been modified to work around the issues as documented here: 
 *      https://github.com/AFNetworking/AFNetworking/issues/1398
 *      I'm not a fan of having to create a temporary file...
 */
- (NSURLSessionDataTask *)request:(BBTHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
        constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure;


/**
 * Creates and runs an `AFHTTPRequestOperation` with a multipart `POST`/`PUT`/`PATCH`
 * request.
 *
 * This is just a wrapper to AFHTTPRequestOperationManager's HTTP Method requests.
 * The value-add here is setting the request headers appropriately on each call
 *   and this is more efficient than the HTTPSessionManager equivalent in that
 *   it doesn't create a temporary file.
 *
 * @param httpMethod
 *      HTTP request method (POST, PUT, PATCH)
 * @param URLString 
 *      The URL string used to create the request URL.
 * @param parameters 
 *      The parameters to be encoded according to the client request serializer.
 * @param block 
 *      A block that takes a single argument and appends data to the HTTP body.
 *      The block argument is an object adopting the `AFMultipartFormData` protocol.
 * @param success
 *      A block object to be executed when the request operation finishes successfully. 
 *      This block has no return value and takes two arguments: the request 
 *      operation, and the response object created by the client response serializer.
 * @param failure A block object to be executed when the request operation finishes 
 *      unsuccessfully, or that finishes successfully, but encountered an error 
 *      while parsing the response data. This block has no return value and takes 
 *      two arguments: the request operation and the error describing the network 
 *      or parsing error that occurred.
 
 @see -HTTPRequestOperationWithRequest:success:failure:
 */
- (AFHTTPRequestOperation *)operationRequest:(BBTHTTPMethod)httpMethod
                                      forURL:(NSString *)URLString
                                  parameters:(id)parameters
                   constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;


/**
 * Asynchronously downloads an image from the specified URL request. 
 * This doesn't have any caching, so only use this if you plan on caching image
 * yourself.
 *
 * @param URLString   
 *      The absolute URL location of the image.
 * @param success
 *      A block object to be executed when the task finishes successfully. This
 *      block has no return value and takes two arguments: the data task, and the
 *      response object created by the client response serializer, which contains the image
 * @param failure
 *      A block object to be executed when the task finishes unsuccessfully, or
 *      that finishes successfully, but encountered an error while parsing the
 *      response data. This block has no return value and takes three arguments:
 *      the data task, the error describing the network or parsing error that
 *      occurred, and the response object created by the client response serializer.
 */
- (NSURLSessionDataTask *)imageFromURL:(NSString *)URLString
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure;


/**
 * Authenticate a given username and password.
 * Successful authentication results in the httpAuthenticated flag being set
 *   as well as current username, password and authentication token being persisted
 *
 * @param username  username to authenticate
 * @param password  password to authenticate username against
 * @param success   block object to be executed when the task succeeds.
 * @param failure   block object to be executed when the task fails.
 */
- (void)authenticateUsername:(NSString *)username
                    password:(NSString *)password
                     success:(void (^)())success
                     failure:(void (^)())failure;

/**
 * Attempt authenticating user with saved username and password.
 * If that fails prompt the user to sign in.
 *
 * You really want to call this whenever app starts up
 *
 * @param success   block object to be executed when the task succeeds.
 * @param failure   block object to be executed when the task fails.
 */
- (void)authenticateWithSuccess:(void (^)())success failure:(void (^)())failure;

/**
 * Skip authentication and setup user for anonymous operation in the app
 *
 * If the user isn't being authenticated then this is the entry point of the app.
 */
- (void)operateAnonymously;

/**
 * Show the SignInViewController modally
 * 
 * @param animated  Show modal with an animation
 */
- (void)showSignInVC:(BOOL)animated;

/**
 * Start sign in process by showing sign in VC and disconnecting XMPP Server
 * connection (incase we were already conencted anonymously
 */
- (void)startSignIn;

/**
 * Sign user out.
 * This also disconnects the XMPP Server connection.
 */
- (void)signOut;

/**
 * Get the user's contacts from the server after successful authentication, and
 * save in CoreData. So this depends on managed object context being setup.
 *
 * This will refresh the avatars and displaynames used on the ContactConversationsCDTVC
 */
- (void)setupContacts;

/**
 * Perform setup by getting the authenticated user's rooms from the server and
 * sync this with what's in our local Core Data storage.
 *
 * The assumption is that this method is only called when the managedObjectContext
 * is setup
 *
 * @param roomsAreSetup     block to be called after setting up rooms. This is 
 *      run on the main queue.
 */
- (void)setupRooms:(void (^)())roomsAreSetup;

/**
 * Fetch popular groupchat conversations from webserver.
 *
 * The assumption is that this method is only called when the managedObjectContext
 * is setup
 *
 * @param conversationsFetched  block to be called after fetching rooms, regardless
 *      of success or failure. This is run on the main queue.
 */
- (void)fetchPopularConversations:(void (^)())conversationsFetched;

@end
