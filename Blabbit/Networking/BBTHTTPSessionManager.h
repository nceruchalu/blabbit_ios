//
//  BBTHTTPSessionManager.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/26/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "AFHTTPSessionManager.h"

/**
 * `BBTHTTPSessionManager` is a subclass of `AFURLSessionManager` with convenience 
 * methods for making HTTP requests. 
 * When a `baseURL` is provided, requests made with the `GET` / `POST` / et al. 
 * convenience methods can be made with relative paths.
 *
 * The real highlight of this subclass is it returns the response body on error
 * responses as well as provides functionality for making multipart/form-data
 * PUT and PATCH requests
 *
 * This class can be used as an alternative to using BBTJSONResponseSerializer
 *
 * @see BBTJSONResponseSerializer
 */
@interface BBTHTTPSessionManager : AFHTTPSessionManager

#pragma mark - Class Methods
/**
 * convert a BBTHTTPMethod to a standard HTTP method String
 * @param httpMethod    BBTHTTPMethod value to be converted to a HTTP method string
 *
 * @return a standard HTTP Method string: GET, POST, PUT, PATCH, DELETE.
 */
+ (NSString *)httpMethodToString:(BBTHTTPMethod)httpMethod;


#pragma mark - Instance Methods
/**
 * Creates and runs an `NSURLSessionDataTask` with a <HTTP Method> request.
 * This is just a wrapper to AFHTTPSessionManager's HTTP Method requests.
 * The value-add here is reducing the number of different functions to be called
 * and setting the request headers appropriately on each call
 *
 * @param httpMethod
 *      HTTP request method (GET, POST, PUT, PATCH DELETE)
 * @param URLString
 *      The URL string used to create the request
 *      URL.
 * @param parameters
 *      The parameters to be encoded according to the client request serializer.
 * @param success
 *      A block object to be executed when the task finishes successfully.
 *      This block has no return value and takes two arguments: the data task, and
 *      the response object created by the client response serializer.
 * @param failure
 *      A block object to be executed when the task finishes unsuccessfully,
 *      or that finishes successfully, but encountered an error while parsing the
 *      response data. This block has no return value and takes three arguments:
 *      the data task, the error describing the network or parsing error that 
 *      occurred, and the response object created by the client response serializer.
 *
 * @see -dataTaskWithRequest:completionHandler:
 */
- (NSURLSessionDataTask *)request:(BBTHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure;

/**
 * Creates and runs an `NSURLSessionDataTask` with a multipart `POST`/`PUT`/`PATCH`
 * request.
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
 */
- (NSURLSessionDataTask *)request:(BBTHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
        constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure;

@end
