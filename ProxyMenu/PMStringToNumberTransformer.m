//
//  PMStringToNumberTransformer.m
//  ProxyMenu
//
//  Created by Xu Jiwei on 13-9-4.
//  Copyright (c) 2013年 TickPlant. All rights reserved.
//

#import "PMStringToNumberTransformer.h"

@implementation PMStringToNumberTransformer

- (id)transformedValue:(id)value {
    return [value description];
}


- (id)reverseTransformedValue:(id)value {
    return [NSNumber numberWithInt:[value intValue]];
}

@end
