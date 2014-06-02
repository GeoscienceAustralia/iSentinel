//
//  NSString+Functions.m
//  Sentinel
//
//  Created by Matt Rankin on 24/04/2014.
//

#import "NSString+Functions.h"

@implementation NSString (Functions)

+ (NSString *)commaDelimitedListWithArray:(NSArray *)array
{
    NSMutableString *list;
    for (id element in array) {
        if (!list) list = [NSMutableString stringWithString:@""];
        [list appendString:[element description]];
        [list appendString:@","];
    }
    
    return list ? (NSString *)[list substringToIndex:[list length]-1] : nil;
}

@end
