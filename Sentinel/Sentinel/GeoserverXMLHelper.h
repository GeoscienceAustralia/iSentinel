//
//  GeoserverXMLHelper.h
//  Sentinel
//
//  Created by Matt Rankin on 28/04/2014.
//

#import <Foundation/Foundation.h>
#import "TBXML.h"

@interface GeoserverXMLHelper : NSObject

+ (NSDictionary *)buildFilteredFeatureList:(NSDictionary *)featureDictionary;
+ (NSDictionary *)dictionaryWithTBXMLElement:(TBXMLElement *)element;

@end
