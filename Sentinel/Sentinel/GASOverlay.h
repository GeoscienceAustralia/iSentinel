//
//  GASOverlay.h
//  Sentinel
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface GASOverlay : NSObject <MKOverlay>

- (id)initWithLayers:(NSArray *)layers;

@property (strong, nonatomic) NSArray *layers;

@end
