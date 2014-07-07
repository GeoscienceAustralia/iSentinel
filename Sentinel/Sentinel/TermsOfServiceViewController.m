//
//  TermsOfServiceViewController.m
//  Sentinel
//
//

#import "TermsOfServiceViewController.h"

@implementation TermsOfServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tosAccepted:(id)sender
{
    [self.delegate termsOfServiceDismissedAccepted:YES];
}

- (IBAction)tosCancelled:(id)sender
{
    [self.delegate termsOfServiceDismissedAccepted:NO];
}
@end
