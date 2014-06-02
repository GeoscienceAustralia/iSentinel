//
//  GASToolbarViewController.h
//  Sentinel
//
//  Created by Matt Rankin on 28/04/2014.
//

#import <UIKit/UIKit.h>
#import "GASToolbar.h"

@interface GASToolbarViewController : UIViewController <GASToolbar>

@property (weak, nonatomic) id<GASToolbarViewControllerDelegate> delegate;
- (IBAction)toggleButtonPressed:(UIButton *)sender;

@end


