//
//  BBTUtilities.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/19/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BBTUtilities : NSObject

/**
 * Get a unique string by generating a UUID string.
 *
 * Probability of duplicates with UUIDs covered here:
 * http://en.wikipedia.org/wiki/UUID#Random%5FUUID%5Fprobability%5Fof%5Fduplicates
 * 
 * @return a CFUUID string
 */
+ (NSString *)uniqueString;

/**
 * Generate an iOS7-style date label for a message date
 * with possible values: 
 * - time (HH:mm)
 *
 * - "Yesterday"
 *
 * - Day of the week (i.e. "Sunday" to "Saturday")
 *
 * - date (MM/dd/yy)
 *
 * @return date label string
 */
+ (NSString *)dayLabelForMessageDate:(NSDate *)msgDate;

/**
 * Generate a time-label for a group conversation time such as time since created
 * or time to expiry
 *
 * @param conversationTime
 *
 * @return time interval string with the following format:
 *      - xxd when time interval is >= 1 day
 *      - xxh when time interval is < 1 day and >= 1 hour
 *      - xxm when time interval is < 1 hour and >= 0 minutes
 *      - nil if time interval < 0
 */
+ (NSString *)timeLabelForConversationDate:(NSTimeInterval)conversationTime;

/**
 * Validate a given email address and confirm it is compliant with RFC 2822
 * @see http://stackoverflow.com/a/1149894
 *
 * @param email     email address to validate
 *
 * @return  a BOOL stating if an email is valid. YES means valid.
 */
+ (BOOL)validateEmail:(NSString *)email;

/**
 * Generate the RFC 3339 DateFormatter.
 *
 * @return an NSDateFormatter that can parse dates of the format:
 *      "2014-06-30T00:43:38.565Z"
 */
+ (NSDateFormatter *)generateRFC3339DateFormatter;

/**
 * Get a scaled version of any image without accounting for aspect ratio
 * ref: http://stackoverflow.com/a/2658801
 *
 * @param image     original image
 * @param newSize   size of scaled image
 *
 * @return scaled version of original image
 */
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

/**
 * Get a scaled version of any image without distorting the image due to aspect
 * ratio changes.
 * ref: http://stackoverflow.com/a/17884863
 *
 * @param image     original image
 * @param newSize   size of scaled image
 *
 * @return scaled version of original image
 */
+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)newSize;

@end
