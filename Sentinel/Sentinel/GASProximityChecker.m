//
//  GASProximityChecker.m
//  Sentinel
//
//

#import "GASProximityChecker.h"
#import "GeoserverManager.h"
#import "GASHelpers.h"
#import "GASErrorHandler.h"


@interface GASProximityChecker ()

@property (strong, nonatomic) NSTimer *proximityCheckTimer;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSMutableDictionary *relevantHotspotData;
@property (strong, nonatomic) NSMutableArray *knownHotspots;
@property (strong, nonatomic) CLLocation *lastUserLocation;

@end

@implementation GASProximityChecker

#define LOWER_THAN_IOS8 1047.25
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

- (id)init
{
    self = [super init];
    if (self) {
        
        NSUInteger updateInterval = [[[NSUserDefaults standardUserDefaults] valueForKey:@"update_interval"] integerValue];
        
        self.proximityCheckTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
                                                                    target:self
                                                                  selector:@selector(startProximityCheck)
                                                                  userInfo:nil
                                                                   repeats:NO];
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = 100.0;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
#ifdef __IPHONE_8_0
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
           [self.locationManager requestAlwaysAuthorization];
        }
#endif
        [self.locationManager startUpdatingLocation];        
    }
    return self;
}

- (NSMutableArray *)knownHotspots
{
    if (!_knownHotspots) _knownHotspots = [[NSMutableArray alloc] init];
    return _knownHotspots;
}


#pragma mark - Timer Delegate -


- (void)startProximityCheck
{
    
    NSUInteger updateInterval = [[[NSUserDefaults standardUserDefaults] valueForKey:@"update_interval"] integerValue];

    if (updateInterval < 10) {
        updateInterval = 10;
    }
    
    [self.proximityCheckTimer invalidate];
    [self checkProximityToLastLocation];
    
    // Schedule again. This permits the interval to be changed.
    self.proximityCheckTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
                                                                    target:self
                                                                  selector:@selector(startProximityCheck)
                                                                  userInfo:nil
                                                                   repeats:NO];
}

// If we have a location and timeout has occured then see if there are any fires nearby
- (void)checkProximityToLastLocation
{
    if (!self.lastUserLocation) {
        return;
    }
    
    NSUInteger proximity = [[[NSUserDefaults standardUserDefaults] valueForKey:@"proximity_threshold"] integerValue];
    if (proximity == 0) {
        proximity = 50;
    }
    
    NSArray *allFeatureTypes = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HotspotImages" ofType:@"plist"]] allKeys];
    
    [[GeoserverManager sharedManager] requestFeatures:allFeatureTypes
                                       forBoundingBox:[GASHelpers boundingBoxFromLocation:self.lastUserLocation withRadius:proximity * METRES_PER_KM]
                                useSecondaryScheduler:YES
                                              success:^(NSDictionary *features) {
                                                  [self checkProximityToUserLocation:self.lastUserLocation withFeatureList:features];
                                              }
                                              failure:^(NSError *error) {
                                                  
                                                  [[GASErrorHandler defaultHandler] reportConnectivityIssue];
                                                  
                                              }];
}

#pragma mark - CLLocationManager Delegate -

//
// Upon each location update, perform a location-based feature request
//
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *userLocation = [locations lastObject];

    // Ignore this if the newLocation is no Better than the one we last had
    if (self.lastUserLocation) {
        if (userLocation.horizontalAccuracy >= self.lastUserLocation.horizontalAccuracy ||
            [userLocation distanceFromLocation:self.lastUserLocation] >= userLocation.horizontalAccuracy)
        {
            // Ignore it
            return;
        }
    }

    // Remeber it
    self.lastUserLocation = userLocation;
    
    [self checkProximityToLastLocation];
}


#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
            [self showNewHotspotLocation];
            break;
            
        default:
            break;
    }
}

- (void)showNewHotspotLocation
{
    CLLocationCoordinate2D hotspotLocation = CLLocationCoordinate2DMake([[self.relevantHotspotData valueForKey:@"latitude"] doubleValue], [[self.relevantHotspotData valueForKey:@"longitude"] doubleValue]);
    
    CLLocationCoordinate2D userLocation = self.lastUserLocation.coordinate;
    
    MKPointAnnotation *pin = [[MKPointAnnotation alloc] init];
    [pin setTitle:[NSString stringWithFormat:@"Nearest hotspot; %@ away", [self.relevantHotspotData valueForKey:@"proximity"]]];
    [pin setSubtitle:[NSString stringWithFormat:@"Updated %@", [NSDate date]]];
    
    [self.delegate drawAttentionToLocation:hotspotLocation
                    relativeToUserLocation:userLocation
                           usingAnnotation:pin];
    
}


#pragma mark - Evaluate received hotspot data -

- (void)checkProximityToUserLocation:(CLLocation *)userLocation withFeatureList:(NSDictionary *)features
{
    //
    // No nearby features were found
    //
    if ([features count] > 0) {
        
        NSNumber *closestProximity = nil;
        NSDictionary *closestHotspot = nil;
        
        for (NSString *hotspotType in [features allKeys]) {
            
            NSDictionary *hotspots = [features valueForKey:hotspotType];
            NSLog(@"%d hotspots received near device's location %@", (int)[hotspots count], hotspotType);
            
            // Find the closest hotspot
            for (NSDictionary *hotspot in hotspots) {
                NSNumber* latitude = @([[hotspot valueForKey:@"latitude"] floatValue]);
                NSNumber* longitude = @([[hotspot valueForKey:@"longitude"] floatValue]);
                CLLocationCoordinate2D coordinate;
                coordinate.latitude = latitude.doubleValue;
                coordinate.longitude = longitude.doubleValue;
                
                CLLocation *hotspotLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
                CLLocationDistance dist = [hotspotLocation distanceFromLocation:userLocation];
                
                if (!closestProximity) {
                    closestProximity = @(dist);
                    closestHotspot = hotspot;
                } else {
                    if (dist < [closestProximity doubleValue]) {
                        closestProximity = @(dist);
                        closestHotspot = hotspot;
                    }
                }

            }
            
        }
        
        self.relevantHotspotData = (NSMutableDictionary *)closestHotspot;
        NSString *proximityString = [NSString stringWithFormat:@"%.2fkm", [closestProximity doubleValue] / METRES_PER_KM];
        [self.relevantHotspotData setValue:proximityString forKey:@"proximity"];
        
        //
        // Exclude hotspots that have already been reported to the user in this launch session (no persistence)
        // TODO: add capability for storing these, and add a corresponding setting to the bundle
        //
        if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"ignore_known_hotspots"] boolValue]) {
            BOOL hotspotAlreadyRegistered = NO;
            for (NSDictionary *hotspot in self.knownHotspots) {
                if ([hotspot isEqualToDictionary:closestHotspot]) {
                    hotspotAlreadyRegistered = YES;
                }
            }
            if (hotspotAlreadyRegistered) return;
        }
        
        //
        // Determine how to report this information to the user
        //
        self.lastUserLocation = userLocation;
        [self.knownHotspots addObject:(NSDictionary *)closestHotspot];
    
        UIAlertView *newHotspotAlert = [[UIAlertView alloc] initWithTitle:@"Hotspot Alert"
                                                                  message:[NSString stringWithFormat:@"There is a hotspot %@ away from your location", proximityString]
                                                                 delegate:self
                                                        cancelButtonTitle:@"Ignore"
                                                        otherButtonTitles:@"Show", nil];
        

        [newHotspotAlert show];
        
    }
    else {
        NSUInteger proximity = [[[NSUserDefaults standardUserDefaults] valueForKey:@"proximity_threshold"] integerValue];
        if (proximity == 0) {
            proximity = 50;
        }
        
        NSString *proximityString = [NSString stringWithFormat:@"%.2dkm", proximity];

        UIAlertView *newHotspotAlert = [[UIAlertView alloc] initWithTitle:@"Hotspot Alert"
                                                                  message:[NSString stringWithFormat:@"There are presently no hotspots within %@ of your location", proximityString]
                                                                 delegate:self
                                                        cancelButtonTitle:@"Ignore"
                                                        otherButtonTitles:nil];
        
        [newHotspotAlert show];
    }
}



                                    
                                    
@end
