//
//  BBTManagedDocument.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/7/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTManagedDocument.h"
#import <CoreData/CoreData.h>

@interface BBTManagedDocument ()

/**
 * Property that represents what we want the managedObjectModel property to return.
 */
@property (strong, nonatomic) NSManagedObjectModel *privateBBTManagedObjectModel;

@end

@implementation BBTManagedDocument

#pragma mark - Properties

/** 
 * Returns the managed object model for the application.
 * If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)privateBBTManagedObjectModel
{
    // lazy instantiation
    if (!_privateBBTManagedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Blabbit" withExtension:@"momd"];
        _privateBBTManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _privateBBTManagedObjectModel;
}

- (NSManagedObjectModel *)managedObjectModel
{
    return self.privateBBTManagedObjectModel;
}

@end
