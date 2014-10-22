//
//  BBTGroupConversation+CLLocation.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/19/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTGroupConversation.h"

/**
 * The CLLocation category on BBTGroupConversation handles the non-standard
 * CLLocation object attribute, location.
 * 
 * With this category you can simply set and get the location attribute and not
 * touch the latitudes and longitudes.
 *
 * Will use this header to document BBTGroupConversation model attributes used
 * for location data
 *
 *  Property            Purpose
 *  location            (CLLocation *) coordinate where groupConversation was created.
 *  locationAddress     (NSDictionary *) cached addressDictionary of reverse-geocoded location
 */
@interface BBTGroupConversation (CLLocation)
#pragma mark - Class Methods
/**
 * Convert a placemark to an address dictionary with keys:
 * - kBBTAddressCityKey
 * - kBBTAddressStateKey
 * - kBBTAddressCountryKey
 *
 * If the provided placemark doesn't have at least one of these required fields
 * then nil is returned.
 */
+ (NSDictionary *)addressForPlacemark:(CLPlacemark *)placemark;

/**
 * Get CLLocation from JSON representation of the location as returned by HTTP Server.
 *
 * @param locationDictionary    JSON representation of location.
 *
 * @see locationToJSON
 */
+ (CLLocation *)locationFromJSON:(NSDictionary *)locationDictionary;

#pragma mark - Instance Methods
/**
 * Get JSON representation of the location property as expected by HTTP Server.
 * The JSON object will be of the format:
 *  {
 *      "type" : "Point",
 *      "coordinates" : [<longitude>, <latitude>]
 *  }
 */
- (NSDictionary *)locationToJSON;

@end
