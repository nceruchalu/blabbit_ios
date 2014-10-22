//
//  BBTGroupConversation+CLLocation.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/19/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTGroupConversation+CLLocation.h"

@implementation BBTGroupConversation (CLLocation)

#pragma mark - Class Methods
+ (NSDictionary *)addressForPlacemark:(CLPlacemark *)placemark
{
    NSDictionary *address = nil;
    
    NSString *city = placemark.locality;
    NSString *state = placemark.administrativeArea;
    NSString *country = placemark.country;
    if ([city length] || [state length] || [country length]) {
        NSMutableDictionary *locationAddress = [NSMutableDictionary dictionary];
        if (city) {
            [locationAddress setObject:city forKey:kBBTAddressCityKey];
        }
        if (state) {
            [locationAddress setObject:state forKey:kBBTAddressStateKey];
        }
        if (country) {
            [locationAddress setObject:country forKey:kBBTAddressCountryKey];
        }
        
        address = [locationAddress copy];
    }
    
    return address;
}

+ (CLLocation *)locationFromJSON:(NSDictionary *)locationDictionary
{
    CLLocation *location = nil;
    // location dictionary could be NULL, so check that it is indeed a dictionary first.
    if (locationDictionary && [locationDictionary isKindOfClass:[NSDictionary class]]) {
        NSArray *coordinates = [locationDictionary objectForKey:kBBTRESTRoomLocationCoordinatesKey];
        if ([coordinates count] == 2) {
            CLLocationDegrees longitude = [((NSNumber *)[coordinates firstObject]) doubleValue];
            CLLocationDegrees latitude = [((NSNumber *)[coordinates lastObject]) doubleValue];
            location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        }
    }
    
    return location;
}

#pragma mark - Instance Methods
- (NSDictionary *)locationToJSON
{
    NSDictionary *locationDictionary = nil;
    if (self.location) {
        NSNumber *longitude = @(self.location.coordinate.longitude);
        NSNumber *latitude = @(self.location.coordinate.latitude);
        locationDictionary = @{@"type" : @"Point",
                               @"coordinates":@[longitude, latitude]};
    }
    return locationDictionary;
}

@end
