//
//  GeoserverXMLHelper.m
//  Sentinel
//
//  Created by Matt Rankin on 28/04/2014.
//

#import "GeoserverXMLHelper.h"

@implementation GeoserverXMLHelper

//
// Convert raw dictionary representation of the XML into useful feature set
//
+ (NSDictionary *)buildFilteredFeatureList:(NSDictionary *)featureDictionary
{
    NSDictionary *featureDataTags = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FeatureInfo" ofType:@"plist"]];
    NSMutableDictionary *filteredFeatureDictionary = [NSMutableDictionary dictionary];
    id featureList = [[featureDictionary valueForKey:@"wfs:FeatureCollection"] valueForKey:@"gml:featureMember"];
    
    if ([featureList isKindOfClass:[NSDictionary class]]) {
        featureList = @[featureList];
    }
    
    for (NSDictionary *feature in featureList) {
        NSString *featureName = [[feature allKeys] lastObject];
        NSDictionary *featureData = [feature valueForKey:featureName];
        NSString *featureType = [featureName stringByReplacingOccurrencesOfString:@"esri:" withString:@""];
        NSMutableDictionary *filteredFeatureData = [NSMutableDictionary dictionary];
        for (NSString *featureDataTag in [featureDataTags allKeys]) {
            [filteredFeatureData setValue:[featureData valueForKey:[featureDataTags valueForKey:featureDataTag]] forKey:featureDataTag];
        }
        NSMutableArray *dataForFeatureType = [filteredFeatureDictionary valueForKey:featureType];
        if (dataForFeatureType != nil) {
            [dataForFeatureType addObject:(NSDictionary *)filteredFeatureData];
        } else {
            [filteredFeatureDictionary setValue:[NSMutableArray arrayWithObject:(NSDictionary *)filteredFeatureData] forKey:featureType];
        }
    }
    
    return (NSDictionary *)filteredFeatureDictionary;
}


//
// Convert a TBXML tree into an NSDictionary.
//
// Notes:
// 1. Attributes are ignored
// 2. Non-leaf text is ignored
// 3. To improve performance, arrays are left mutable
//
// TODO: add attributes as properties. This isn't necessary just at the moment.
//
+ (NSDictionary *)dictionaryWithTBXMLElement:(TBXMLElement *)element
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    do {
        NSString *elementName = [TBXML elementName:element];
        
        //        NSMutableDictionary *attributes;
        //        TBXMLAttribute * attribute = element->firstAttribute;
        //
        //        while (attribute) {
        //            if (!attributes) attributes = [NSMutableDictionary dictionary];
        //
        //            [TBXML attributeName:attribute];
        //
        //            NSLog(@"%@->%@ = %@",  [TBXML elementName:element],
        //                  [TBXML attributeName:attribute],
        //                  [TBXML attributeValue:attribute]);
        //
        //            // Obtain the next attribute
        //            attribute = attribute->next;
        //        }
        
        id nodeData = nil;
        
        if (element->firstChild) {
            nodeData = [self dictionaryWithTBXMLElement:element->firstChild];
        } else {
            nodeData = [TBXML textForElement:element];
        }
        
        id data = [dictionary valueForKey:elementName];
        
        if (data != nil) {
            if ([data isKindOfClass:[NSMutableArray class]]) {
                [(NSMutableArray *)data addObject:nodeData];
            } else {
                [dictionary setValue:[NSMutableArray arrayWithObject:nodeData] forKey:elementName];
            }
        } else {
            [dictionary setValue:nodeData forKey:elementName];
        }
        
    } while ((element = element->nextSibling));
    
    return (NSDictionary *)dictionary;
}

@end
