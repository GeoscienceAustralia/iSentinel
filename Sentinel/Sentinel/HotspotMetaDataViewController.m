//
//  HotspotMetaDataViewController.m
//  Sentinel
//
//  Created by Matt Rankin on 22/04/2014.
//

#import "HotspotMetaDataViewController.h"

@interface HotspotMetaDataViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelLatitude;
@property (weak, nonatomic) IBOutlet UILabel *labelLongitude;
@property (weak, nonatomic) IBOutlet UILabel *labelTempK;
@property (weak, nonatomic) IBOutlet UILabel *labelAge;
@property (weak, nonatomic) IBOutlet UILabel *labelSource;
@property (weak, nonatomic) IBOutlet UILabel *labelConfidence;
@property (weak, nonatomic) IBOutlet UILabel *labelTempC;

@property (strong, nonatomic) NSDictionary *metaData;

@end

@implementation HotspotMetaDataViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil metaData:(NSDictionary *)metaData
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _metaData = metaData;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.labelLatitude.text = [NSString stringWithFormat:@"%@", [_metaData valueForKey:@"latitude"]];
    self.labelLongitude.text = [NSString stringWithFormat:@"%@", [_metaData valueForKey:@"longitude"]];
    
    NSString *tempString = [_metaData valueForKey:@"temp"];
    if (tempString) {
        float tempK = [tempString floatValue];
        float tempC = tempK - 273.15f;
        self.labelTempK.text = [NSString stringWithFormat:@"%.2f", tempK];
        self.labelTempC.text = [NSString stringWithFormat:@"%.2f", tempC];
    } else {
        self.labelTempK.text = [NSString stringWithFormat:@"%@", nil];
        self.labelTempC.text = [NSString stringWithFormat:@"%@", nil];
    }
    
    self.labelAge.text = [NSString stringWithFormat:@"%@", [_metaData valueForKey:@"age_hours"]];
    self.labelSource.text = [NSString stringWithFormat:@"%@", [_metaData valueForKey:@"source"]];
    self.labelConfidence.text = [NSString stringWithFormat:@"%@", [_metaData valueForKey:@"confidence"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
