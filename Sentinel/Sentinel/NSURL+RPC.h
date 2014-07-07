//
//  NSURL+RPC.h
//  Sentinel
//
//

#import <Foundation/Foundation.h>

@interface NSURL (RPC)

- (id)initWithServer:(NSString *)remoteServerPath parameters:(NSDictionary *)parameters;

@end
