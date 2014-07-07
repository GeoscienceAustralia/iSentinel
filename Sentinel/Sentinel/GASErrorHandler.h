//
//  GASErrorHandler.h
//  Sentinel
//
//  Created by Matt Rankin on 27/06/2014.
//  Copyright (c) 2014 Matt Rankin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GASErrorHandler : NSObject

+ (GASErrorHandler *)defaultHandler;

- (void)reportConnectivityIssue;

@end
