//
//  BBTUser.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/13/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BBTMessage;

@interface BBTUser : NSManagedObject

@property (nonatomic, retain) UIImage * avatarThumbnail;
@property (nonatomic, retain) NSString * avatarThumbnailURL;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSNumber * friendship;
@property (nonatomic, retain) NSDate * lastModified;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * unreadMessageCount;
@property (nonatomic, retain) BBTMessage *lastMessage;
@property (nonatomic, retain) NSSet *messages;
@end

@interface BBTUser (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(BBTMessage *)value;
- (void)removeMessagesObject:(BBTMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
