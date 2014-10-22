//
//  BBTMessage.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/13/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BBTGroupConversation, BBTUser;

@interface BBTMessage : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * hasMedia;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) UIImage * imageThumbnail;
@property (nonatomic, retain) NSString * imageThumbnailURL;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSNumber * isIncoming;
@property (nonatomic, retain) NSNumber * isRead;
@property (nonatomic, retain) NSNumber * isSystemEvent;
@property (nonatomic, retain) NSDate * localTimestamp;
@property (nonatomic, retain) NSDate * remoteTimestamp;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSNumber * systemEventType;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) BBTGroupConversation *groupConversation;
@property (nonatomic, retain) BBTUser *contactUsingAsLastMessage;
@property (nonatomic, retain) BBTUser *contact;

@end
