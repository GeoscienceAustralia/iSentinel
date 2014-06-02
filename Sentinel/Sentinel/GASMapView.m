//
//  GASMapView.m
//  Sentinel
//
//  Created by Matt Rankin on 28/04/2014.
//

#import "GASMapView.h"
#import "GASOverlay.h"
#import "GeoserverManager.h"

@implementation GASMapView

- (void)setLayers:(NSArray *)layers
{
    if (![layers isEqualToArray:_layers]) {
        [self removeOverlays:self.overlays];
        [self addOverlay:[[GASOverlay alloc] initWithLayers:layers]];
    }
    _layers = layers;
}

- (NSMutableArray *)allAnnotations
{
    if (!_allAnnotations) _allAnnotations = [[NSMutableArray alloc] init];
    return _allAnnotations;
}

- (void)applyDefaults
{
    NSDictionary *mapDefaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MapDefaults" ofType:@"plist"]];
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = [[mapDefaults valueForKey:@"Latitude"] doubleValue];
    zoomLocation.longitude = [[mapDefaults valueForKey:@"Longitude"] doubleValue];
    NSUInteger viewDimension = [[mapDefaults valueForKey:@"ViewDimension"] integerValue];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, viewDimension, viewDimension);
    [self setRegion:viewRegion animated:YES];
    self.layers = [mapDefaults valueForKey:@"Layers"];
    self.detailThreshold = [[mapDefaults valueForKey:@"DetailThreshold"] floatValue];
}

@end
