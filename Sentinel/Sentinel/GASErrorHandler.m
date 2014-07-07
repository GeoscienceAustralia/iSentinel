//
//  GASErrorHandler.m
//  Sentinel
//
//  Created by Matt Rankin on 27/06/2014.
//  Copyright (c) 2014 Matt Rankin. All rights reserved.
//

#import "GASErrorHandler.h"

@interface GASErrorHandler ()

@property (strong, nonatomic) UIAlertView *networkErrorAlertView;

@end

@implementation GASErrorHandler

static GASErrorHandler *defaultHandler;

+ (GASErrorHandler *)defaultHandler
{
    if (!defaultHandler) defaultHandler = [[GASErrorHandler alloc] init];
    return defaultHandler;
}

- (void)reportConnectivityIssue
{
    NSLog(@"connectivity issue!");
    
    if (!_networkErrorAlertView) {
        _networkErrorAlertView = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                            message:@"The GeoScience server is currently unavailable"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
    }
    
    [_networkErrorAlertView show];
}

@end
