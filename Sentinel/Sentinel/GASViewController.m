//
//  GASViewController.m
//  Sentinel
//
//

#import "GASViewController.h"
#import "HotspotAnnotation.h"
#import "HotspotMetaDataViewController.h"
#import "GeoserverManager.h"
#import "GASToolbarViewController.h"
#import "GASMapView.h"
#import "GASOverlay.h"
#import "GASOverlayView.h"
#import "GASHelpers.h"
#import "GASErrorHandler.h"

@interface GASViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *networkIndicator;
@property (weak, nonatomic) IBOutlet GASMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *toolBarFrame;

@property (strong, nonatomic) GASToolbarViewController *featuresToolbar;
@property (strong, nonatomic) HotspotMetaDataViewController *metaDataViewController;
@property (strong, nonatomic) UIPopoverController *metaDataPopoverController;
@property (weak, nonatomic) IBOutlet UINavigationBar *navbar;

@property (strong, nonatomic) GASProximityChecker *proximityChecker;

// Debug
@property (weak, nonatomic) IBOutlet UILabel *emptyCacheLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *emptyCacheSpinner;

@end

@implementation GASViewController

CFAbsoluteTime lastAnnotationUpdate = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navbar setBackgroundImage:[UIImage imageNamed:@"navbar.png"] forBarMetrics:UIBarMetricsDefault];
    
    self.mapView.delegate = self;
    [self.mapView applyDefaults];
    
    self.featuresToolbar = [[GASToolbarViewController alloc] initWithNibName:@"GASToolbarView" bundle:nil];
    self.featuresToolbar.delegate = self;
    [self.toolBarFrame addSubview:self.featuresToolbar.view];
    self.toolBarFrame.backgroundColor = [UIColor clearColor];
    
    self.proximityChecker = [[GASProximityChecker alloc] init];
    self.proximityChecker.delegate = self;
    
    [GeoserverManager sharedManager].emptyCacheLabel = self.emptyCacheLabel;
    [GeoserverManager sharedManager].emptyCacheSpinner = self.emptyCacheSpinner;
    
    [self mapView:self.mapView regionDidChangeAnimated:NO];
}


#pragma mark - Proximity Checker Delegate -

- (void)drawAttentionToLocation:(CLLocationCoordinate2D)location
         relativeToUserLocation:(CLLocationCoordinate2D)userLocation
                usingAnnotation:(id<MKAnnotation>)annotation
{
    [annotation setCoordinate:location];
    [self.mapView addAnnotation:annotation];

    // TODO: what if the distance is such that annotations are not being shown?
    
    // Zoom to surrounding region
    MKCoordinateSpan span = MKCoordinateSpanMake(fabs(location.latitude - userLocation.latitude) * 1.8, fabs(location.longitude - userLocation.longitude) * 1.8);
    CLLocationCoordinate2D centre = CLLocationCoordinate2DMake((location.latitude + userLocation.latitude) / 2, (location.longitude + userLocation.longitude) / 2);
    
    MKCoordinateRegion zoomBox = MKCoordinateRegionMake(centre, span);
    [self.mapView setRegion:zoomBox animated:YES];
}


#pragma mark - Toolbar Delegate -

- (void)toolbarStatusDidChange:(GASToolbarViewController *)sender
{
    if (sender == self.featuresToolbar) {
        if (self.mapView.region.span.latitudeDelta < self.mapView.detailThreshold) {
            [self redrawAnnotations];
            [self.mapView doClustering];
        }
    }
}


#pragma mark - Update MapView -

//
// Decide which layers to switch on and whether to load feature data/annotations
//
// TODO: Switching WMS layers on/off is problematic: you can't just use an arbitrary threshold for
// swapping images with annotations (e.g. 5 degrees), instead it must match a mapKit zoom threshold
// precisely to avoid weird caching behaviour. There might be another way around it.
//
- (void)refreshMapWithAnnotations:(BOOL)displayAnnotations
{
    if (displayAnnotations) {
        [self.networkIndicator startAnimating];
        [self updateAnnotations];
// WMS with a slow mapping server is hard to want with out very good async error handling
//        [self.mapView setLayers:@[]];
    } else {
        [self.mapView removeAnnotations:self.mapView.annotations];
//        [self.mapView setLayers:@[@"hotspot_current"]];
    }
}

- (void)updateAnnotations
{
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();

    void (^successBlock)(NSDictionary *) = ^(NSDictionary *features) {
        lastAnnotationUpdate = now;
        
        if (![[GeoserverManager sharedManager] hasRequestsPending]) [self.networkIndicator stopAnimating];
        self.mapView.allAnnotations = nil;
        
        for (NSString *hotspotType in [features allKeys]) {
            
            NSDictionary *hotspots = [features valueForKey:hotspotType];
            NSLog(@"%d hotspots received for %@", (int)[hotspots count], hotspotType);
            
            for (NSDictionary *hotspot in hotspots) {
                NSNumber* latitude = @([[hotspot valueForKey:@"latitude"] floatValue]);
                NSNumber* longitude = @([[hotspot valueForKey:@"longitude"] floatValue]);
                CLLocationCoordinate2D coordinate;
                coordinate.latitude = latitude.doubleValue;
                coordinate.longitude = longitude.doubleValue;
                HotspotAnnotation *annotation = [[HotspotAnnotation alloc] initWithCoordinate:coordinate featureType:hotspotType];
                annotation.metaData = hotspot;
                [self.mapView.allAnnotations addObject:annotation];
            }
        }
        
        [self redrawAnnotations];
    };
    
    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        [self.networkIndicator stopAnimating];
        if (error) {
            NSLog(@"Error! %@ %@", [error localizedDescription], [error userInfo]);
            [[GASErrorHandler defaultHandler] reportConnectivityIssue];
        }
    };
    
    NSArray *allFeatureTypes = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HotspotImages" ofType:@"plist"]] allKeys];
    
    // Only do this every few minutes or if we dont have any on screen
    // TODO: Make this a true bounding box/sliding window with buffer like all the greats.
    // Provided the degress of bounding are small enough the WFS can respond fast enough.
    // This would also require the WMS requests to utilise the CQL_FILTER to enable featuers to be swapped out in the overlay
    if ((now - lastAnnotationUpdate > (300 * 1000)) || self.mapView.annotations.count == 0) {
        [[GeoserverManager sharedManager] requestFeatures:allFeatureTypes
                                       forBoundingBox:nil
                                useSecondaryScheduler:NO
                                              success:successBlock
                                              failure:failureBlock];
    }
    else if (![[GeoserverManager sharedManager] hasRequestsPending]) {
        [self.networkIndicator stopAnimating];   
    }

}

- (void)redrawAnnotations
{
    NSArray *activeFeatures = [self.featuresToolbar labelsForActiveToggles];
    
    // Remove all annotations except for dropped pins
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[HotspotAnnotation class]]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
    
    for (id<MKAnnotation> annotation in self.mapView.allAnnotations)
    {
        if ([activeFeatures containsObject:[(HotspotAnnotation *)annotation type]]) {
            [self.mapView addAnnotation:annotation];
        }
    }
}

- (IBAction)homeButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{}];
}


#pragma mark - MKMapViewDelegate -

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (mapView.region.span.latitudeDelta < self.mapView.detailThreshold) {
        if ([self.mapView mapWasZoomed] || [self.mapView mapWasPannedSignificantly]) {
            [self.mapView doClustering];
        }
        [self refreshMapWithAnnotations:YES];
    } else {
        [self refreshMapWithAnnotations:NO];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    [[GeoserverManager sharedManager] cancelAllRequests];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *annotationView = nil;

    if ([annotation isKindOfClass:[OCAnnotation class]]) {
        NSString *type = [(OCAnnotation *)annotation groupTag];

        // if it's a cluster
        if ([annotation isKindOfClass:[OCAnnotation class]]) {
            
            OCAnnotation *clusterAnnotation = (OCAnnotation *)annotation;
            
            annotationView = (MKAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"ClusterView"];
            if (!annotationView) {
                annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ClusterView"];
                annotationView.canShowCallout = YES;
                annotationView.centerOffset = CGPointMake(0, -20);
            }
            
            // set title
            clusterAnnotation.title = @"Cluster";
            clusterAnnotation.subtitle = [NSString stringWithFormat:@"There are : %zd hotspots nearby", [clusterAnnotation.annotationsInCluster count]];
            
            // set its image
            annotationView.image = [HotspotAnnotation imageFromType:type];
        }
    }
    else if ([annotation isKindOfClass:[HotspotAnnotation class]]) {
        
        NSString *type = [(HotspotAnnotation *)annotation type];
    
        annotationView = (MKAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:type];
        if (!annotationView) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:type];
            annotationView.enabled = YES;
            annotationView.canShowCallout = NO;
            annotationView.image = [(HotspotAnnotation *)annotation image];
        }
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view.annotation isKindOfClass:[HotspotAnnotation class]]) {
    
        HotspotMetaDataViewController *hotspotMetaDataViewController = [[HotspotMetaDataViewController alloc] initWithNibName:@"HotspotMetaDataView" bundle:nil metaData:[(HotspotAnnotation *)view.annotation metaData]];
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:hotspotMetaDataViewController];
        popover.delegate = self;
        self.metaDataPopoverController = popover;
        self.metaDataViewController = hotspotMetaDataViewController;
        
        popover.popoverContentSize = hotspotMetaDataViewController.view.frame.size;
        
       [popover presentPopoverFromRect:view.bounds inView:view
          permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else if ([view.annotation isKindOfClass:[OCAnnotation class]]) {
        // Do nothing. We are using a call out atm. We could zoom
    } else {
        
        for (id<MKAnnotation> hotspotAnnotation in self.mapView.annotations) {
            if ([hotspotAnnotation isKindOfClass:[HotspotAnnotation class]]) {
                if ([hotspotAnnotation coordinate].latitude == [view.annotation coordinate].latitude &&
                    [hotspotAnnotation coordinate].longitude == [view.annotation coordinate].longitude) {
                    [self mapView:mapView didSelectAnnotationView:[self.mapView viewForAnnotation:(HotspotAnnotation *)hotspotAnnotation]];
                }
            }
        }
        
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    GASOverlayView *overlayView = [[GASOverlayView alloc] initWithOverlay:overlay];
    return overlayView;
}


@end
