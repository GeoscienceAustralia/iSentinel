//
//  GASHelpers.m
//  Sentinel
//
//

#import "GASHelpers.h"
#import <CommonCrypto/CommonDigest.h>

@implementation GASHelpers


#pragma mark - Bounding Box Calculations -
//
// TODO: The maps don't line up. Geoscience appears to be using more than one type of projection which makes life harder
// for prototype.
//
+ (NSArray *)boundingBoxWithMapRect:(MKMapRect)mapRect
{
    CLLocationCoordinate2D SW = MKCoordinateForMapPoint(MKMapPointMake(mapRect.origin.x, MKMapRectGetMaxY(mapRect)));
    CLLocationCoordinate2D NE = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), mapRect.origin.y));
    return @[ @(SW.longitude), @(SW.latitude), @(NE.longitude), @(NE.latitude) ];
}

+ (NSArray *)boundingBoxWithRegion:(MKCoordinateRegion)region {
    
    return @[@(region.center.longitude - region.span.longitudeDelta / 2),
             @(region.center.latitude - region.span.latitudeDelta / 2),
             @(region.center.longitude + region.span.longitudeDelta / 2),
             @(region.center.latitude + region.span.latitudeDelta / 2), @("EPSG:4326")];
}

+ (NSArray *)boundingBoxFromLocation:(CLLocation *)location withRadius:(float)radius
{
    CLLocationCoordinate2D centre = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
    MKCoordinateRegion enclosingRegion = MKCoordinateRegionMakeWithDistance(centre, radius * 2, radius * 2);
    return [GASHelpers boundingBoxWithRegion:enclosingRegion];
}


#pragma mark - Caching Strings -

+ (NSString *)md5Hash:(NSString *)stringData {
    NSData *data = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5([data bytes], (CC_LONG)[data length], result);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
}

+ (NSString *)cacheDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)filePathForTileWithBoundingBox:(NSArray *)bbox
{
    NSString *tileName = [GASHelpers md5Hash:[bbox description]];
    NSString *cache = [GASHelpers cacheDirectory];
    NSString *filePath = [cache stringByAppendingPathComponent:tileName];
    return filePath;
}

@end
