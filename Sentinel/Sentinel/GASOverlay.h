//
//  GASOverlay.h
//  Sentinel
//
//  Created by Matt Rankin on 24/04/2014.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface GASOverlay : NSObject <MKOverlay>

- (id)initWithLayers:(NSArray *)layers;

@property (strong, nonatomic) NSArray *layers;

@end
