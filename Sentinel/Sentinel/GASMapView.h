//
//  GASMapView.h
//  Sentinel
//
//  Created by Matt Rankin on 28/04/2014.
//

#import <MapKit/MapKit.h>

@interface GASMapView : MKMapView

@property (strong, nonatomic) NSArray *layers;
@property (nonatomic) CLLocationDegrees detailThreshold;
@property (strong, nonatomic) NSMutableArray *allAnnotations;

- (void)applyDefaults;

@end
