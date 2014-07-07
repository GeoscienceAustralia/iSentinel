//
//  GeoserverXMLHelper.h
//  Sentinel
//
//

#import <Foundation/Foundation.h>
#import "TBXML.h"

@interface GeoserverXMLHelper : NSObject

+ (NSDictionary *)buildFilteredFeatureList:(NSDictionary *)featureDictionary
                                   filters:(NSArray *)filterFeatures;

+ (NSDictionary *)dictionaryWithTBXMLElement:(TBXMLElement *)element;

@end
