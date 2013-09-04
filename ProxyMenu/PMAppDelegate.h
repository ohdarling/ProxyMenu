//
//  PMAppDelegate.h
//  ProxyMenu
//
//  Created by Xu Jiwei on 13-9-4.
//  Copyright (c) 2013年 TickPlant. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PMAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (readonly, nonatomic) NSArray *proxyTypes;

- (IBAction)saveAction:(id)sender;

@end
