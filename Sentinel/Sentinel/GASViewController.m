//
//  GASViewController.m
//  Sentinel
//
//  Created by Matt Rankin on 22/04/2014.
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

@interface GASViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *networkIndicator;
@property (weak, nonatomic) IBOutlet GASMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *toolBarFrame;

@property (strong, nonatomic) GASToolbarViewController *featuresToolbar;
@property (strong, nonatomic) UIAlertView *networkErrorAlertView;
@property (strong, nonatomic) HotspotMetaDataViewController *metaDataViewController;
@property (strong, nonatomic) UIPopoverController *metaDataPopoverController;
@property (weak, nonatomic) IBOutlet UINavigationBar *navbar;

// Debug
@property (weak, nonatomic) IBOutlet UILabel *emptyCacheLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *emptyCacheSpinner;

@end

@implementation GASViewController

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
    
    [GeoserverManager sharedManager].emptyCacheLabel = self.emptyCacheLabel;
    [GeoserverManager sharedManager].emptyCacheSpinner = self.emptyCacheSpinner;
}

#pragma mark - Toolbar Delegate -

- (void)toolbarStatusDidChange:(GASToolbarViewController *)sender
{
    if (sender == self.featuresToolbar) {
        // TODO only redraw annotations if at the zoom level that will show them.
        [self redrawAnnotations];

    }
}

#pragma mark - Update MapView -

//
// Decide which layers to switch on and whether to load feature data/annotations
// Annotations are UIViews, so displaying thousands of them begins to slow
// things down dramatically.
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
//        self.mapView.layers = @[ @"Roads", @"MainlandOutline" ];
    } else {
        [self.mapView removeAnnotations:self.mapView.annotations];
//        self.mapView.layers = @[ @"Roads", @"MainlandOutline", @"Modis24to48Hours", @"Modis48to72Hours" ];
    }
}

- (void)updateAnnotations
{
    void (^successBlock)(NSDictionary *) = ^(NSDictionary *features) {
        
        self.mapView.allAnnotations = nil;
        if (![[GeoserverManager sharedManager] hasRequestsPending]) [self.networkIndicator stopAnimating];
        
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
            [self showConnectivityAlert];
        }
    };
    
    NSArray *allFeatureTypes = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HotspotImages" ofType:@"plist"]] allKeys];
    
    
    [[GeoserverManager sharedManager] requestFeatures:allFeatureTypes
                                       forBoundingBox:[GASHelpers boundingBoxWithRegion:self.mapView.region]
                                              success:successBlock
                                              failure:failureBlock];
}

- (void)redrawAnnotations
{
    NSArray *activeFeatures = [self.featuresToolbar labelsForActiveToggles];
    [self.mapView removeAnnotations:self.mapView.annotations];

    for (id<MKAnnotation> annotation in self.mapView.allAnnotations) {
        if ([activeFeatures containsObject:[(HotspotAnnotation *)annotation type]]) {
            [self.mapView addAnnotation:annotation];
        }
    }
}

- (void)showConnectivityAlert
{
    if (!_networkErrorAlertView) {
        _networkErrorAlertView = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                            message:@"The GeoScience server is currently unavailable"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
    }
    
    if (![_networkErrorAlertView isVisible]) {
        [_networkErrorAlertView show];
    }
    
}

- (IBAction)homeButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{}];
}



#pragma mark - MKMapViewDelegate -

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (mapView.region.span.latitudeDelta < self.mapView.detailThreshold) {
        [self refreshMapWithAnnotations:YES];
    } else {
        // For now, always show the annotations. In the future, it should be changed to
        // use the map service at a higher level of zoom.
        [self refreshMapWithAnnotations:YES];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    [[GeoserverManager sharedManager] cancelAllRequests];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[HotspotAnnotation class]]) {
        
        NSString *type = [(HotspotAnnotation *)annotation type];
    
        MKAnnotationView *annotationView = (MKAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:type];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:type];
            annotationView.enabled = YES;
            annotationView.canShowCallout = NO;
            annotationView.image = [(HotspotAnnotation *)annotation image];
        } else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    HotspotMetaDataViewController *hotspotMetaDataViewController = [[HotspotMetaDataViewController alloc] initWithNibName:@"HotspotMetaDataView" bundle:nil metaData:[(HotspotAnnotation *)view.annotation metaData]];
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:hotspotMetaDataViewController];
    popover.delegate = self;
    self.metaDataPopoverController = popover;
    self.metaDataViewController = hotspotMetaDataViewController;
    
    popover.popoverContentSize = hotspotMetaDataViewController.view.frame.size;
    
   [popover presentPopoverFromRect:view.bounds inView:view
      permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    GASOverlayView *overlayView = [[GASOverlayView alloc] initWithOverlay:overlay];
    return overlayView;
}


@end
