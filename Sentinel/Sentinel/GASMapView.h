//
//  GASMapView.h
//  Sentinel
//
//

#import <MapKit/MapKit.h>
#import "OCMapView.h"

@interface GASMapView : OCMapView

@property (strong, nonatomic) NSArray *layers;
@property (nonatomic) CLLocationDegrees detailThreshold;
@property (strong, nonatomic) NSMutableArray *allAnnotations;

- (void)applyDefaults;

- (NSArray *)getBoundingBox;

@end
