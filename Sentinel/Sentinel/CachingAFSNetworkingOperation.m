//
//  CachingAFSNetworkingOperation.m
//  Sentinel
//
//

#import <Foundation/Foundation.h>


#import "CachingAFSNetworkingOperation.h"

@implementation CachingAFSNetworkingOperation

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
success:(void (^)(AFHTTPRequestOperation *operation,
                  id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation,
                                                                      NSError *error))failure
{
    NSMutableURLRequest *modifiedRequest = request.mutableCopy;
    AFNetworkReachabilityManager *reachability = self.reachabilityManager;
    if (!reachability.isReachable)
    {
        modifiedRequest.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    }
    
    AFHTTPRequestOperation *operation =  [super HTTPRequestOperationWithRequest:modifiedRequest
                                          success:success
                                          failure:failure];

    // Provided its a nice 200 response then cache for 120seconds
    [operation setCacheResponseBlock: ^NSCachedURLResponse *(NSURLConnection *connection,
                                                             NSCachedURLResponse *cachedResponse)
     {
         NSURLResponse *response = cachedResponse.response;
         NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse*)response;
         NSDictionary *headers = HTTPResponse.allHeaderFields;

         NSMutableDictionary *modifiedHeaders = headers.mutableCopy;
         modifiedHeaders[@"Cache-Control"] = @"max-age=120";
         NSHTTPURLResponse *modifiedHTTPResponse = [[NSHTTPURLResponse alloc]
                                                    initWithURL:HTTPResponse.URL
                                                    statusCode:HTTPResponse.statusCode
                                                    HTTPVersion:@"HTTP/1.1"
                                                    headerFields:modifiedHeaders];
         
         return [[NSCachedURLResponse alloc] initWithResponse:modifiedHTTPResponse
                                                                     data:cachedResponse.data
                                                                 userInfo:cachedResponse.userInfo
                                                            storagePolicy:cachedResponse.storagePolicy];
     }];
    
    return operation;
}

@end