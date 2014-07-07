//
//  HotspotAnnotation.h
//  Sentinel
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "OCGrouping.h"

@interface HotspotAnnotation : NSObject <MKAnnotation, OCGrouping>

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate featureType:(NSString *)type;

- (UIImage *)image;

+ (UIImage *)imageFromType:(NSString *)type;

@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSDictionary *metaData;
@property (copy, nonatomic) NSString *groupTag;

@end
