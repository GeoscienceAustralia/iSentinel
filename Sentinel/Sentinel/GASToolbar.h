//
//  GASToolbar.h
//  Sentinel
//
//  Created by Matt Rankin on 28/04/2014.
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
