//
//  BBTGroupConversation.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 8/8/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>

@class BBTMessage;

@interface BBTGroupConversation : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSNumber * membership;
@property (nonatomic, retain) NSNumber * isOwner;
@property (nonatomic, retain) NSDate * lastModified;
@property (nonatomic, retain) NSNumber * liked;
@property (nonatomic, retain) NSNumber * likesCount;
@property (nonatomic, retain) CLLocation * location;
@property (nonatomic, retain) NSDictionary * locationAddress;
@property (nonatomic, retain) UIImage * photoThumbnail;
@property (nonatomic, retain) NSString * photoThumbnailURL;
@property (nonatomic, retain) NSString * photoURL;
@property (nonatomic, retain) NSString * roomName;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSSet *messages;
@end

@interface BBTGroupConversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(BBTMessage *)value;
- (void)removeMessagesObject:(BBTMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
