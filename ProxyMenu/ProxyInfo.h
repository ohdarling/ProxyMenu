//
//  ProxyInfo.h
//  ProxyMenu
//
//  Created by Xu Jiwei on 13-9-4.
//  Copyright (c) 2013年 TickPlant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ProxyInfo : NSManagedObject

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSString * name;

@end
