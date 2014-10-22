//
//  BBTJSONResponseSerializer.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/21/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "AFURLResponseSerialization.h"

extern NSString *const BBTJSONResponseSerializerKey;

/**
 * `BBTJSONResponseSerializer` is a subclass of `AFJSONResponseSerializer` that 
 * validates and decodes JSON responses.
 * It's added functionality is embedding the error body (response object) in the 
 * NSError passed in failure object of AFHTTPSessionManager request methods.
 *
 * You use this class by setting an instance of AFHTTPSessionManager, httpSessionManager:
 *      httpSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
 *
 * The response object can be found in the failure block's NSError:
 *      [error.userInfo objectForKey:BBTJSONResponseSerializerKey]
 *
 * This class can be used as an alternative to using BBTHTTPSessionManager
 *
 * @see BBTHTTPSessionManager
 *
 * @ref http://blog.gregfiumara.com/archives/239
 */
@interface BBTJSONResponseSerializer : AFJSONResponseSerializer

@end
