//
//  GASOverlayView.m
//  Sentinel
//
//  Created by Matt Rankin on 24/04/2014.
//

#import "GASOverlayView.h"
#import "GeoserverManager.h"
#import "GASOverlay.h"
#import "GASHelpers.h"

@implementation GASOverlayView


- (BOOL)canDrawMapRect:(MKMapRect)mapRect
             zoomScale:(MKZoomScale)zoomScale
{
    if ([[GeoserverManager sharedManager] cachedImageForBoundingBox:[GASHelpers boundingBoxWithMapRect:mapRect]]) {
        return YES;
    } else {
        [[GeoserverManager sharedManager] requestImageForBoundingBox:[GASHelpers boundingBoxWithMapRect:mapRect] size:CGSizeMake(TILE_SIZE, TILE_SIZE) layers:[(GASOverlay *)self.overlay layers] success:^(UIImage *image) {
            [self setNeedsDisplayInMapRect:mapRect zoomScale:zoomScale];
        } failure:^{
            NSLog(@"Image fetch failed");
        }];
        return NO;
    }
}

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context
{
    CGRect rect = CGRectMake(mapRect.origin.x, mapRect.origin.y, mapRect.size.width, mapRect.size.height);
    UIImage *image = [[GeoserverManager sharedManager] cachedImageForBoundingBox:[GASHelpers boundingBoxWithMapRect:mapRect]];
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, 1/zoomScale, 1/zoomScale);
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), [image CGImage]);
    CGContextRestoreGState(context);
}


@end
