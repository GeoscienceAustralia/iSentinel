//
//  GASMapView.m
//  Sentinel
//
//

#import "GASMapView.h"
#import "GASOverlay.h"
#import "GeoserverManager.h"

@implementation GASMapView

- (void)setLayers:(NSArray *)layers
{
    if (![layers isEqualToArray:_layers]) {
        [self removeOverlays:self.overlays];
        if (layers && [layers count]) {
            [self addOverlay:[[GASOverlay alloc] initWithLayers:layers]];
        }
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
    self.clusterSize = [[mapDefaults valueForKey:@"ClusterSize"] floatValue];
    self.clusterByGroupTag = TRUE;
}

- (NSArray *)getBoundingBox
{
    //To calculate the search bounds...
    //First we need to calculate the corners of the map so we get the points
    CGPoint nePoint = CGPointMake(self.bounds.origin.x + self.bounds.size.width, self.bounds.origin.y);
    CGPoint swPoint = CGPointMake((self.bounds.origin.x), (self.bounds.origin.y + self.bounds.size.height));
    
    //Then transform those point into lat,lng values
    CLLocationCoordinate2D neCoord;
    neCoord = [self convertPoint:nePoint toCoordinateFromView:self];
    
    CLLocationCoordinate2D swCoord;
    swCoord = [self convertPoint:swPoint toCoordinateFromView:self];
    
    return @[[NSNumber numberWithDouble:swCoord.latitude ],
             [NSNumber numberWithDouble:swCoord.longitude],
             [NSNumber numberWithDouble:neCoord.latitude],
             [NSNumber numberWithDouble:neCoord.longitude]];
}
@end
