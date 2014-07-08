//
//  GeoserverXMLHelper.m
//  Sentinel
//
//

#import "GeoserverXMLHelper.h"

@implementation GeoserverXMLHelper

//
// Convert raw dictionary representation of the XML into useful feature set
// FilterFeatures are in the form filter-minHrs-maxHrs. The data will be placed into
// the filter-min-max feature min (inc) max(exclusive). non-filtered elements will be
// left in the original layer.
//
+ (NSDictionary *)buildFilteredFeatureList:(NSDictionary *)featureDictionary
                                   filters:(NSArray *)filterFeatures
{
    NSDictionary *featureDataTags = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FeatureInfo" ofType:@"plist"]];
    NSMutableDictionary *filteredFeatureDictionary = [NSMutableDictionary dictionary];
    
    // Split the filterFeatures into pieces and store min/max
    // We will use these to split the list
    // NOTE: This could all be done via WFS filters on the age field directly to the server.
    // At this time we have no knowledge on the performance and resource implications of the production system
    // so keeping it low key for the backend for prototype.
    NSMutableDictionary *filtersExpanded = [NSMutableDictionary dictionary];
    for (NSString *filter in filterFeatures) {
        NSArray *filterParts = [filter componentsSeparatedByString:@"-"];
        int min = [[filterParts objectAtIndex:1] integerValue];
        int max = [[filterParts objectAtIndex:2] integerValue];
        NSMutableArray *dataArray = [[NSMutableArray alloc] initWithCapacity: 2];
        [dataArray insertObject:[NSNumber numberWithInt:min] atIndex:0];
        [dataArray insertObject:[NSNumber numberWithInt:max] atIndex:1];
        [filtersExpanded setValue:dataArray forKey:filter];
    }
    
    id featureList = [[featureDictionary valueForKey:@"wfs:FeatureCollection"] valueForKey:@"gml:featureMembers"];
    
    if(![featureList isKindOfClass:[NSDictionary class]]) {
        return filteredFeatureDictionary;
    }
    
    for (NSString *featureName in [featureList allKeys]) {
      // In iOS7.0 on an iPad 3(HD) this casts incorrectly inline. Splitting
      // appears to resolve the crash
      NSArray *featureDatas = [featureList valueForKey:featureName];
      for (NSMutableDictionary *featureData in featureDatas) {
        NSString *featureType = [featureName stringByReplacingOccurrencesOfString:@"sentinel:" withString:@""];
        NSMutableDictionary *filteredFeatureData = [NSMutableDictionary dictionary];
        for (NSString *featureDataTag in [featureDataTags allKeys]) {
            NSString * newKey = [featureDataTags valueForKey:featureDataTag];
            NSString * keyValue = [featureData valueForKey:newKey];
            if (keyValue) {
                [filteredFeatureData setValue:keyValue forKey:featureDataTag];
            }
        }
        
        // Default to the feature we are in
        NSString *name = featureType;

        // Whats the age of the feature
        NSString *ageAsString = [filteredFeatureData valueForKey:@"age"];
        if (ageAsString) {
           int age = [ageAsString integerValue];
            
           // Now we need to determine which list to stick it in.
           for(id key in filtersExpanded) {
              NSArray *elements = [filtersExpanded objectForKey:key];
              int min = [[elements objectAtIndex:0] integerValue];
              int max = [[elements objectAtIndex:1] integerValue];
                
              if (age <= max && age > min) {
                 name = key;
                 break;
              }
           }
        }

        NSMutableArray *dataForFeatureType = [filteredFeatureDictionary valueForKey:name];
        if (dataForFeatureType != nil) {
            [dataForFeatureType addObject:(NSDictionary *)filteredFeatureData];
        } else {
            [filteredFeatureDictionary setValue:[NSMutableArray arrayWithObject:(NSDictionary *)filteredFeatureData] forKey:name];
        }
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
