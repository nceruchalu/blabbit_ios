//
//  BBTUtilities.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/19/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTUtilities.h"
#import "NSDate+BBTUtilities.h"

#pragma mark - Constants
// seconds in minute, hour, day per the Gregorian Calendar.
static const NSInteger kSecondsInMinute    = 60;
static const NSInteger kSecondsInHour      = 3600;
static const NSInteger kSecondsInDay       = 86400;

@implementation BBTUtilities

+(NSString *)uniqueString
{
    return [[NSUUID UUID] UUIDString];
}

+ (NSString *)dayLabelForMessageDate:(NSDate *)msgDate
{
    // if the date formatters isn't already setup, create it and cache for reuse.
    //   It's important to cache formatter for performance as creating it isn't cheap.
    static NSDateFormatter *dayLabelFormatter = nil;
    if (!dayLabelFormatter) {
        dayLabelFormatter = [[NSDateFormatter alloc] init];
    }
    
    // iOS7 messaging style
    NSString *dayLabel = nil;
    if ([msgDate isToday]) {
        // if today simply show time
        [dayLabelFormatter setDateFormat:@"hh:mma"];
        dayLabel = [dayLabelFormatter stringFromDate:msgDate];
    
    } else if ([msgDate isYesterday]) {
        // if yesterday simply show that
        dayLabel = @"Yesterday";
    
    } else if ([msgDate isWithinLastWeek]) {
        // if within the last week then show the day of the week
        [dayLabelFormatter setDateFormat:@"EEEE"];
        dayLabel = [dayLabelFormatter stringFromDate:msgDate];
        
    } else {
        // else show the date without time.
        [dayLabelFormatter setDateFormat:@"MM/dd/yy"];
        dayLabel = [dayLabelFormatter stringFromDate:msgDate];
    }
    
    return dayLabel;
}

+ (NSString *)timeLabelForConversationDate:(NSTimeInterval)conversationTime
{
    NSString *timeLabel = nil;
    
    if (conversationTime >= kSecondsInDay) {
        timeLabel = [NSString stringWithFormat:@"%dd",(int)(conversationTime/kSecondsInDay)];
    } else if (conversationTime >= kSecondsInHour) {
        timeLabel = [NSString stringWithFormat:@"%dh",(int)(conversationTime/kSecondsInHour)];
    } else if (conversationTime >= 0) {
        timeLabel = [NSString stringWithFormat:@"%dm",(int)(conversationTime/kSecondsInMinute)];
    }
    
    return timeLabel;
}

+ (BOOL)validateEmail:(NSString *)email
{
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    
    return [emailTest evaluateWithObject:email];
}

/**
 * Generate the RFC 3339 DateFormatter.
 */
+ (NSDateFormatter *)generateRFC3339DateFormatter
{
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    return rfc3339DateFormatter;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    // if no image received, return same.
    if (!image) return nil;
    
    // In next line, pass 0.0 to use the current device's pixel scaling factor
    // (and thus account for Retina resolution). Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)newSize
{
    // if no image received, return same.
    if (!image) return nil;
    
    CGFloat scale = MAX(newSize.width/image.size.width, newSize.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    // take center square
    CGRect imageRect = CGRectMake((newSize.width - width)/2.0f,
                                  (newSize.height - height)/2.0f,
                                  width,
                                  height);
    
    // In next line, pass 0.0 to use the current device's pixel scaling factor
    // (and thus account for Retina resolution). Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
