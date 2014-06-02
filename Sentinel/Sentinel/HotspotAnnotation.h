//
//  HotspotAnnotation.h
//  Sentinel
//
//  Created by Matt Rankin on 22/04/2014.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface HotspotAnnotation : NSObject <MKAnnotation>

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate featureType:(NSString *)type;

- (UIImage *)image;

@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSDictionary *metaData;

@end
