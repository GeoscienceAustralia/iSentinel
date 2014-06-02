//
//  TermsOfServiceViewController.h
//  Sentinel
//
//  Created by Matt Rankin on 25/04/2014.
//

#import <UIKit/UIKit.h>

@protocol TermsOfServiceViewControllerDelegate <NSObject>

- (void)termsOfServiceDismissedAccepted:(BOOL)accepted;

@end

@interface TermsOfServiceViewController : UIViewController

@property (weak, nonatomic) id<TermsOfServiceViewControllerDelegate> delegate;

@end
