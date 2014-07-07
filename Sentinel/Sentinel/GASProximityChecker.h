//
//  GASProximityChecker.h
//  Sentinel
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>


@protocol GASProximityCheckerDelegate <NSObject>

- (void)drawAttentionToLocation:(CLLocationCoordinate2D)location
         relativeToUserLocation:(CLLocationCoordinate2D)userLocation
                usingAnnotation:(id<MKAnnotation>)annotation;

@end

@interface GASProximityChecker : NSObject <UIAlertViewDelegate, CLLocationManagerDelegate>

- (id)init;
- (void)startProximityCheck;

@property (weak, nonatomic) id<GASProximityCheckerDelegate> delegate;

@end
