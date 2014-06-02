//
//  GASToolbarViewController.m
//  Sentinel
//
//  Created by Matt Rankin on 28/04/2014.
//

#import "GASToolbarViewController.h"

//
// This class can be easily converted into a generic toggling toolbar class.
// Any subclass will be forced to conform to the GASToolbar and toolbar delegate protocols.
//

@interface GASToolbarViewController ()

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *fireIcons;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *categoryLabels;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *toggleButtons;

@end

@implementation GASToolbarViewController

- (IBAction)toggleButtonPressed:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    for (UIImageView *fireIcon in self.fireIcons) {
        if ([fireIcon tag] == [sender tag]) {
            fireIcon.alpha = sender.selected ? 1.0 : 0.3;
        }
    }
    for (UILabel *categoryLabel in self.categoryLabels) {
        if ([categoryLabel tag] == [sender tag]) {
            categoryLabel.alpha = sender.selected ? 1.0 : 0.3;
        }
    }
    
    [self.delegate toolbarStatusDidChange:self];
    
}

#pragma mark - GASToolbar -

- (NSArray *)labelsForActiveToggles
{
    NSMutableArray *labels = [NSMutableArray array];
    NSDictionary *toolbarFeatureNames = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HotspotFeatureNames" ofType:@"plist"]];
    for (UIButton *button in self.toggleButtons) {
        if (button.selected) {
            for (UILabel *categoryLabel in self.categoryLabels) {
                if ([categoryLabel tag] == [button tag]) {
                    [labels addObject:[toolbarFeatureNames valueForKey:categoryLabel.text]];
                }
            }
        }
    }
    return (NSArray *)labels;
}

@end
