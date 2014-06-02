//
//  HotspotAnnotation.m
//  Sentinel
//
//  Created by Matt Rankin on 22/04/2014.
//

#import "HotspotAnnotation.h"

@interface HotspotAnnotation ()

@property (nonatomic, assign) CLLocationCoordinate2D theCoordinate;

@end

@implementation HotspotAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate featureType:(NSString *)type
{
    self = [super init];
    if (self) {
        _theCoordinate = coordinate;
        _type = type;
    }
    return self;
}

- (CLLocationCoordinate2D)coordinate {
    return _theCoordinate;
}

- (UIImage *)image
{
    NSDictionary *hotspotImages = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HotspotImages" ofType:@"plist"]];
    
    return [UIImage imageNamed:[hotspotImages valueForKey:self.type]];
}


@end
