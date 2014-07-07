//
//  GASToolbarViewController.h
//  Sentinel
//
//

#import <UIKit/UIKit.h>
#import "GASToolbar.h"

@interface GASToolbarViewController : UIViewController <GASToolbar>

@property (weak, nonatomic) id<GASToolbarViewControllerDelegate> delegate;
- (IBAction)toggleButtonPressed:(UIButton *)sender;

@end


