//
//  GASHomeViewController.m
//  Sentinel
//
//

#import "GASHomeViewController.h"
#import "GeoserverManager.h"
#import "AFNetworkReachabilityManager.h"

@interface GASHomeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *splashOverlay;

@property (strong, nonatomic) TermsOfServiceViewController *tosViewController;
@property (strong, nonatomic) UIPopoverController *tosPopoverController;

@end

@implementation GASHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.splashOverlay.alpha != 1) {
        self.splashOverlay.alpha = 0;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.splashOverlay.alpha == 0) {
        [UIView animateWithDuration:1.0 animations:^{
            self.splashOverlay.alpha = 1;
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];    
    
    self.tosViewController = [[TermsOfServiceViewController alloc] initWithNibName:@"TermsOfService" bundle:nil];
    self.tosViewController.delegate = self;
    self.tosPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.tosViewController];
    self.tosPopoverController.delegate = self;
    self.tosPopoverController.popoverContentSize = self.tosViewController.view.frame.size;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startButtonPress:(id)sender
{
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"accepted_tos"] boolValue]) {
        [self segue];
    } else {
        [self.tosPopoverController presentPopoverFromRect:self.view.bounds inView:self.view
                                 permittedArrowDirections:(UIPopoverArrowDirection)NULL animated:YES];
    }
}

- (void)termsOfServiceDismissedAccepted:(BOOL)accepted
{
    [self.tosPopoverController dismissPopoverAnimated:YES];
    if (accepted) {
        [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:@"accepted_tos"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self segue];
    }
}

- (void)segue
{
    if ([AFNetworkReachabilityManager sharedManager].reachable) {
        [self performSegueWithIdentifier:@"SegueMapView" sender:self];
    } else {
        UIAlertView *networkAlert = [[UIAlertView alloc] initWithTitle:@"Connectivity Issue"
                                                               message:@"Your device must be connected to the internet in order to access Geoscience hotspot data"
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
        [networkAlert show];
    }
}

@end
