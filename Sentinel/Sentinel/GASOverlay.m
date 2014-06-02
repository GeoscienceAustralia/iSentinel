//
//  GASOverlay.m
//  Sentinel
//
//  Created by Matt Rankin on 24/04/2014.
//

#import "GASOverlay.h"

@implementation GASOverlay

@synthesize boundingMapRect;
@synthesize coordinate;

- (id)initWithLayers:(NSArray *)layers {
    
    if (!layers || [layers count] < 1) return nil;
    for (id layer in layers) {
        if (![layer isKindOfClass:[NSString class]]) {
            NSLog(@"Overlay must be provided with layer list");
        }
    }
    
    self = [super init];
    if (self) {
        
        // TODO: This should ideally be set to the maximum bounding box provided by the WMS capabilities
        boundingMapRect = MKMapRectWorld;
        coordinate = CLLocationCoordinate2DMake(0, 0);
        _layers = layers;
    }
    return self;
}

@end
