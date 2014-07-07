//
//  GASViewController.h
//  Sentinel
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "GASToolbarViewController.h"
#import "GASProximityChecker.h"


@interface GASViewController : UIViewController <MKMapViewDelegate, UIPopoverControllerDelegate,  GASToolbarViewControllerDelegate, GASProximityCheckerDelegate>

@end
