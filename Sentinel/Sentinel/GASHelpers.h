//
//  GASHelpers.h
//  Sentinel
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#define METRES_PER_KM        1000

@interface GASHelpers : NSObject

+ (NSArray *)boundingBoxWithRegion:(MKCoordinateRegion)region;
+ (NSArray *)boundingBoxWithMapRect:(MKMapRect)mapRect;
+ (NSArray *)boundingBoxFromLocation:(CLLocation *)location withRadius:(float)radius;

+ (NSString *)md5Hash:(NSString *)stringData;
+ (NSString *)cacheDirectory;

// Use a hash value derived from the string representing the bounding box.
+ (NSString *)filePathForTileWithBoundingBox:(NSArray *)bbox;

@end
