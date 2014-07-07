//
//  TermsOfServiceViewController.h
//  Sentinel
//
//

#import <UIKit/UIKit.h>

@protocol TermsOfServiceViewControllerDelegate <NSObject>

- (void)termsOfServiceDismissedAccepted:(BOOL)accepted;

@end

@interface TermsOfServiceViewController : UIViewController

@property (weak, nonatomic) id<TermsOfServiceViewControllerDelegate> delegate;

@end
