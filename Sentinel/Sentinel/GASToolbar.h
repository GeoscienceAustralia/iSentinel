//
//  GASToolbar.h
//  Sentinel
//
//

#import <Foundation/Foundation.h>

@protocol GASToolbar <NSObject>
@required

- (NSArray *)labelsForActiveToggles;

@end

@protocol GASToolbarViewControllerDelegate <NSObject>
@required

- (void)toolbarStatusDidChange:(id)sender;

@end
