//
//  GASHelpers.h
//  Sentinel
//
//  Created by Matt Rankin on 25/04/2014.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>

@interface GASHelpers : NSObject

+ (NSArray *)boundingBoxWithRegion:(MKCoordinateRegion)region;
+ (NSArray *)boundingBoxWithMapRect:(MKMapRect)mapRect;

+ (NSString *)md5Hash:(NSString *)stringData;
+ (NSString *)cacheDirectory;

// Use a hash value derived from the string representing the bounding box.
+ (NSString *)filePathForTileWithBoundingBox:(NSArray *)bbox;

@end
