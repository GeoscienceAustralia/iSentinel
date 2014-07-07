//
//  GeoserverManager.h
//  Sentinel
//
//

#import <Foundation/Foundation.h>

#define CACHE_EXPIRY_TIME    600.0

@interface GeoserverManager : NSObject

+ (GeoserverManager *)sharedManager;

- (UIImage *)cachedImageForBoundingBox:(NSArray *)bbox;
- (void)resetCache;

// The capabilities request isn't necessary at present, because the feature/layer
// names are hard coded or stored in plist form. However they should probably be
// fetched to learn of maximum bounding boxes.
- (void)refreshCapabilitiesSuccess:(void (^)())successBlock
                           failure:(void (^)())failureBlock;

// WMS
- (void)requestImageForBoundingBox:(NSArray *)bbox
                              size:(CGSize)size
                            layers:(NSArray *)layerList
                           success:(void (^)(UIImage *image))successCallback
                           failure:(void (^)())failureCallback;

// WFS
- (void)requestFeatures:(NSArray *)featureList
         forBoundingBox:(NSArray *)bbox
  useSecondaryScheduler:(BOOL)secondaryRequest
                success:(void (^)(NSDictionary *features))successCallback
                failure:(void (^)(NSError *error))failureCallback;

- (void)cancelAllRequests;
- (BOOL)hasRequestsPending;

@property (weak, nonatomic) UILabel *emptyCacheLabel;
@property (weak, nonatomic) UIActivityIndicatorView *emptyCacheSpinner;

@end
