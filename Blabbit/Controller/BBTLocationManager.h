//
//  BBTLocationManager.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 8/6/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;

typedef void (^BBTLocationManagerCompletion)(CLLocation *location, NSError *error);

/**
 * BBTLocationManager is a singleton class that ensures we have just one instance
 * of CLLocationManager throughout this application.
 * This way we ensure we only have one location manager working and don't have to
 * duplicate code everywhere.
 *
 * Attempts to acquire a location measurement with a predetermined level of
 * accuracy. A timeout is used to avoid wasting power in the case where a
 * sufficiently accurate measurement cannot be acquired.
 *
 * @ref https://developer.apple.com/library/ios/samplecode/locateme/Introduction/Intro.html
 */
@interface BBTLocationManager : NSObject

#pragma mark - Properties
/**
 * location is set to last retrieved value from `updateCurrentLocation:`
 */
@property (nonatomic, strong, readonly) CLLocation *location;


#pragma mark - Class Methods
/**
 * Single instance manager.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized BBTLocationManager object.
 */
+ (instancetype)sharedManager;

/**
 * Show error message indicating location is disabled for app
 */
+ (void)showLocationDisabledErrorAlert;


#pragma mark - Instance Methods
/**
 * Get current location
 *
 * @param completion    block to be called when location servies are enabled and
 *                      we are done getting a location. This takes two parameters,
 *                      location and error. Be sure to check that the location is
 *                      not nil before using it
 * @param failure       block to be called when location services are disabled.
 */
- (void)updateCurrentLocation:(BBTLocationManagerCompletion)completion failure:(void (^)())failure;

@end
