//
//  NSURL+RPC.m
//  Sentinel
//
//

#import "NSURL+RPC.h"

@implementation NSURL (RPC)

- (id)initWithServer:(NSString *)remoteServerPath parameters:(NSDictionary *)parameters
{
    NSMutableString *parameterString = [NSMutableString stringWithString:@""];
    for (NSString *key in [parameters allKeys]) {
        [parameterString appendFormat:@"%@=%@&", key, [parameters valueForKey:key]];
    }
    self = [self initWithString:[NSString stringWithFormat:@"%@?%@", remoteServerPath, parameterString]];
    return self;
}

@end
