//
//  NSURL+RPC.h
//  Sentinel
//
//  Created by Matt Rankin on 23/04/2014.
//

#import <Foundation/Foundation.h>

@interface NSURL (RPC)

- (id)initWithServer:(NSString *)remoteServerPath parameters:(NSDictionary *)parameters;

@end
