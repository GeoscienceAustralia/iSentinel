//
//  GeoserverManager.m
//  Sentinel
//
//  Created by Matt Rankin on 24/04/2014.
//

#import "GeoserverManager.h"
#import "NSURL+RPC.h"
#import "NSString+Functions.h"
#import "AFHTTPRequestOperationManager.h"
#import "GASHelpers.h"
#import "GeoserverXMLHelper.h"

@interface GeoserverManager ()

@property (strong, nonatomic) NSDictionary *geoServerURLs;
@property (strong, nonatomic) AFHTTPRequestOperationManager *WFSRequestManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *WMSRequestManager;
@property (strong, nonatomic) NSTimer *cacheExpiryTimer;

@end

@implementation GeoserverManager

static GeoserverManager *sharedInstance;

+ (GeoserverManager *)sharedManager
{
    if (!sharedInstance) sharedInstance = [[GeoserverManager alloc] init];
    return sharedInstance;
}

- (AFHTTPRequestOperationManager *)WFSRequestManager
{
    if (!_WFSRequestManager) _WFSRequestManager = [AFHTTPRequestOperationManager manager];
    return _WFSRequestManager;
}

- (AFHTTPRequestOperationManager *)WMSRequestManager
{
    if (!_WMSRequestManager) _WMSRequestManager = [AFHTTPRequestOperationManager manager];
    _WMSRequestManager.operationQueue.maxConcurrentOperationCount = 1;
    return _WMSRequestManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _geoServerURLs = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GeoServer" ofType:@"plist"]];
        
        NSDate *lastCacheReset = [[NSUserDefaults standardUserDefaults] valueForKey:@"last_cache_reset"];
        NSTimeInterval timeSinceLastCacheReset = [[NSDate date] timeIntervalSinceDate:lastCacheReset];
        
        NSLog(@"time since last cache reset: %.2f", timeSinceLastCacheReset);
        
        if (isnan(timeSinceLastCacheReset)) {
            [self resetCache];
            _cacheExpiryTimer = [NSTimer scheduledTimerWithTimeInterval:CACHE_EXPIRY_TIME
                                                                 target:self
                                                               selector:@selector(resetCache)
                                                               userInfo:nil
                                                                repeats:NO];
        } else {
            if (timeSinceLastCacheReset > CACHE_EXPIRY_TIME) {
                [self resetCache];
                timeSinceLastCacheReset = 0.0;
            }
            _cacheExpiryTimer = [NSTimer scheduledTimerWithTimeInterval:CACHE_EXPIRY_TIME  - timeSinceLastCacheReset
                                                                 target:self
                                                               selector:@selector(resetCache)
                                                               userInfo:nil
                                                                repeats:NO];
        }
    }
    return self;
}


#pragma mark - Tile Cache -

- (void)resetCache
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [GASHelpers cacheDirectory];
    
    [self.emptyCacheSpinner startAnimating];
    [UIView animateWithDuration:1.0 animations:^{
        self.emptyCacheLabel.alpha = 1.0;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        NSError *error;
        for (NSString *file in [fileManager contentsOfDirectoryAtPath:cachePath error:&error]) {
            [fileManager removeItemAtPath:[cachePath stringByAppendingPathComponent:file] error:&error];
        }
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"last_cache_reset"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.emptyCacheSpinner stopAnimating];
            [UIView animateWithDuration:1.0 animations:^{
                self.emptyCacheLabel.alpha = 0.0;
            }];
            
        });
        
    });
    
    _cacheExpiryTimer = [NSTimer scheduledTimerWithTimeInterval:CACHE_EXPIRY_TIME
                                                         target:self
                                                       selector:@selector(resetCache)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (UIImage *)cachedImageForBoundingBox:(NSArray *)bbox
{
    NSString *filePath = [GASHelpers filePathForTileWithBoundingBox:bbox];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        return [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath]];
    }
    return nil;
}


#pragma mark - Network -

- (void)cancelAllRequests
{
    [self.WFSRequestManager.operationQueue cancelAllOperations];
}

- (BOOL)hasRequestsPending
{
    return [self.WFSRequestManager.operationQueue operationCount] > 0;
}


//
// This probably won't be needed unless layer/feature lists are to be displayed dynamically or
// max bounding box information is required
//
- (void)refreshCapabilitiesSuccess:(void (^)())successBlock failure:(void (^)())failureBlock
{
//    NSDictionary *GeoServerURLs = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GeoServer" ofType:@"plist"]];
    
//    NSURL *wfsRequest = [[NSURL alloc] initWithServer:[GeoServerURLs valueForKey:@"WFS"]
//                                           parameters:@{@"Version": @"1.0.0",
//                                                        @"Request": @"getcapabilities",
//                                                        @"Service": @"WFS",
//                                                        @"Servicename": @"GDA94_Sentinel_Shapefiles_WFS"}];
//    
//    NSURL *wmsRequest = [[NSURL alloc] initWithServer:[GeoServerURLs valueForKey:@"WMS"]
//                                           parameters:@{@"Version": @"1.1.1",
//                                                        @"Request": @"getcapabilities",
//                                                        @"Service": @"WMS",
//                                                        @"Servicename": @"GDA94_Sentinel_Shapefiles_WMS"}];

}


//
// WMS
//
- (void)requestImageForBoundingBox:(NSArray *)bbox
                              size:(CGSize)size
                            layers:(NSArray *)layerList
                           success:(void (^)(UIImage *image))successCallback
                           failure:(void (^)())failureCallback
{
    NSMutableDictionary *parameterList = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultsWMS" ofType:@"plist"]];
    [parameterList setValue:[NSString commaDelimitedListWithArray:bbox] forKey:@"bbox"];
    [parameterList setValue:[NSString stringWithFormat:@"%d", (int)size.width] forKey:@"width"];
    [parameterList setValue:[NSString stringWithFormat:@"%d", (int)size.height] forKey:@"height"];
    [parameterList setValue:[NSString commaDelimitedListWithArray:layerList] forKey:@"layers"];
    
    NSURL *wmsRequestURL = [[NSURL alloc] initWithServer:[self.geoServerURLs valueForKey:@"WMS"]
                                           parameters:parameterList];
    
    NSLog(@"WMS: %@", wmsRequestURL);
    
    //
    // The following works successfully. It is not possible to cancel requests, because they are
    // hidden in NSData, but the use of tiling means this shouldn't be an issue except for very slow
    // connections accessing many layers at once (thus producing larger pngs).
    //
    // See below for AFNetworking solution.
    //
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSData *imageData = [NSData dataWithContentsOfURL:wmsRequestURL];
        
        if (imageData) {
            
            UIImage *image = [UIImage imageWithData:imageData];
            [UIImagePNGRepresentation(image) writeToFile:[GASHelpers filePathForTileWithBoundingBox:bbox] atomically:YES];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                successCallback(image);
            });
            
        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                failureCallback();
            });
            
        }
        
    });
    
    return;
    
    //
    // This solution provides for the cancelling of requests, but there is something about these AFHTTPRequestOperationManagers
    // that means they crash occasionally (they are new in AFNetworking 2.0). It is left here for future reference.
    //
    self.WMSRequestManager.responseSerializer = [AFImageResponseSerializer serializer];
    
    [self.WMSRequestManager GET:[wmsRequestURL description] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        successCallback(responseObject);
        
        if ([responseObject isKindOfClass:[UIImage class]]) {
            UIImage *image = (UIImage *)responseObject;
            [UIImagePNGRepresentation(image) writeToFile:[GASHelpers filePathForTileWithBoundingBox:bbox] atomically:YES];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (![operation isCancelled]) {
            NSLog(@"Error: %@", error);
            failureCallback();
        }
        NSLog(@"Image fetch cancelled");
    }];
    
    
    
    // Alternatively check out: https://github.com/nicklockwood/RequestQueue
    
}


//
// WFS
//
- (void)requestFeatures:(NSArray *)featureList
         forBoundingBox:(NSArray *)bbox
                success:(void (^)(NSDictionary *features))successCallback
                failure:(void (^)(NSError *error))failureCallback
{
    NSMutableDictionary *parameterList = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultsWFS" ofType:@"plist"]];
    [parameterList setValue:[NSString commaDelimitedListWithArray:featureList] forKey:@"typeName"];
    [parameterList setValue:[NSString commaDelimitedListWithArray:bbox] forKey:@"bbox"];
    
    NSURL *wfsRequestURL = [[NSURL alloc] initWithServer:[self.geoServerURLs valueForKey:@"WFS"]
                                           parameters:parameterList];
    
    NSLog(@"WFS: %@", wfsRequestURL);
    
    AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
    responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/xml", nil];
    self.WFSRequestManager.responseSerializer = responseSerializer;
    
    [self.WFSRequestManager GET:[wfsRequestURL description] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSData *data = (NSData *)responseObject;
            NSError *error;
            TBXML *tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failureCallback(error);
                });
            } else {
                NSDictionary *dict = [GeoserverXMLHelper dictionaryWithTBXMLElement:tbxml.rootXMLElement];
                NSDictionary *filteredFeatureList = [GeoserverXMLHelper buildFilteredFeatureList:dict];
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(filteredFeatureList);
                });
            }
            
        });

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (![operation isCancelled]) {
            NSLog(@"Error: %@", error);
            failureCallback(error);
        }
        failureCallback(nil);
        NSLog(@"Feature fetch cancelled");
        
    }];
    
    return;
}

@end
