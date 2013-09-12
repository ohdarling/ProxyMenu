//
//  PMAppDelegate.m
//  ProxyMenu
//
//  Created by Xu Jiwei on 13-9-4.
//  Copyright (c) 2013年 TickPlant. All rights reserved.
//

#import "PMAppDelegate.h"

#import "ProxyInfo.h"

#define kProxyPAC       @"PAC"
#define kProxySOCKS     @"SOCKS"
#define kProxyHTTP      @"HTTP"

static AuthorizationRef authRef;
static AuthorizationFlags authFlags;


@interface PMAppDelegate ()
@property (nonatomic, strong)   ProxyInfo       *selectedProxy;
@end


@implementation PMAppDelegate {
    IBOutlet    NSMenu                  *statusItemMenu;
    IBOutlet    NSArrayController       *proxiesArrayController;
    
    NSStatusItem                        *statusItem;
    
    NSMutableDictionary                 *previousDeviceProxies;
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:28.0];
    statusItem.image = [NSImage imageNamed:@"status_item_icon"];
    statusItem.alternateImage = [NSImage imageNamed:@"status_item_icon_alt"];
    statusItem.menu = statusItemMenu;
    [statusItem setHighlightMode:YES];
    
    previousDeviceProxies = [NSMutableDictionary new];
}


- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if ([proxiesArrayController.content count] == 0) {
        [self showMainWindow:nil];
    }
}


#pragma mark - Menu delegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    while (![menu.itemArray[2] isSeparatorItem]) {
        [menu removeItemAtIndex:2];
    }
    
    BOOL hasProxies = NO;
    
    for (ProxyInfo *proxy in [proxiesArrayController.content reverseObjectEnumerator]) {
        if (proxy.name.length > 0 && proxy.address.length > 0) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:proxy.name action:@selector(setProxyWithMenuItem:) keyEquivalent:@""];
            menuItem.target = self;
            menuItem.representedObject = proxy;
            
            if (self.selectedProxy == proxy) {
                [menuItem setState:NSOnState];
            }
            
            [menu insertItem:menuItem atIndex:2];
            hasProxies = YES;
        }
    }
    
    if (!hasProxies) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"No Proxies" action:NULL keyEquivalent:@""];
        [menuItem setEnabled:NO];
        [menu insertItem:menuItem atIndex:2];
    }
    
    [menu.itemArray[0] setState:(self.selectedProxy != nil ? NSOffState : NSOnState)];
}

#pragma mark - Actions

- (IBAction)quitApp:(id)sender {
    if ([self applicationShouldTerminate:NSApp] == NSTerminateNow) {
        [NSApp terminate:nil];
    }
}


- (IBAction)setProxyWithMenuItem:(id)sender {
    self.selectedProxy = [sender representedObject];
}


- (IBAction)useDirectConnection:(id)sender {
    self.selectedProxy = nil;
}


- (IBAction)useSelectedProxy:(id)sender {
    if (proxiesArrayController.selectedObjects.count > 0) {
        self.selectedProxy = proxiesArrayController.selectedObjects.lastObject;
    }
}


- (IBAction)showMainWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [self.window orderFront:nil];
}


- (IBAction)refreshCurrentProxy:(id)sender {
    ProxyInfo *proxy = self.selectedProxy;
    self.selectedProxy = nil;
    [NSThread sleepForTimeInterval:0.1];
    self.selectedProxy = proxy;
}


#pragma mark - NSWindow delegate

- (BOOL)windowShouldClose:(id)sender {
    [self.window orderOut:nil];
    return NO;
}


#pragma mark - Properties

- (NSArray *)proxyTypes {
    return @[@"SOCKS", @"HTTP", @"PAC"];
}


- (void)setSelectedProxy:(ProxyInfo *)selectedProxy {
    if (_selectedProxy != selectedProxy) {
        _selectedProxy = selectedProxy;
        
        [self toggleSystemProxy:(selectedProxy != nil)];
    }
}


#pragma mark - Modify System Proxy

- (NSString *)proxiesPathOfDevice:(NSString *)devId {
    NSString *path = [NSString stringWithFormat:@"/%@/%@/%@", kSCPrefNetworkServices, devId, kSCEntNetProxies];
    return path;
}


//! 修改代理设置的字典
- (void)modifyPrefProxiesDictionary:(NSMutableDictionary *)proxies withProxyEnabled:(BOOL)enabled {
    // 先禁用所有代理，防止之前已经设置过一些会导致冲突
    [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
    [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPSEnable];
    [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
    [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];
    
    if (enabled) {
        NSInteger proxyPort = [self.selectedProxy.port intValue];
        NSString *proxyAddress = self.selectedProxy.address;
        NSString *proxyType = self.selectedProxy.type;
        
        if (proxyType == nil || [proxyType isEqualToString:kProxyPAC]) {
            // 使用 PAC
            [proxies setObject:proxyAddress forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
            
        } else if ([proxyType isEqualToString:kProxyHTTP]) {
            // 使用 HTTP 代理
            [proxies setObject:[NSNumber numberWithInteger:proxyPort] forKey:(NSString *)kCFNetworkProxiesHTTPPort];
            [proxies setObject:proxyAddress forKey:(NSString *)kCFNetworkProxiesHTTPProxy];
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
            [proxies setObject:[NSNumber numberWithInteger:proxyPort] forKey:(NSString *)kCFNetworkProxiesHTTPSPort];
            [proxies setObject:proxyAddress forKey:(NSString *)kCFNetworkProxiesHTTPSProxy];
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesHTTPSEnable];
            
        } else if ([proxyType isEqualToString:kProxySOCKS]) {
            // 使用 SOCKS 代理
            [proxies setObject:[NSNumber numberWithInteger:proxyPort] forKey:(NSString *)kCFNetworkProxiesSOCKSPort];
            [proxies setObject:proxyAddress forKey:(NSString *)kCFNetworkProxiesSOCKSProxy];
            [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];
        }
    }
}


- (void)toggleSystemProxy:(BOOL)useProxy {
    if (authRef == NULL) {
        
        authFlags = kAuthorizationFlagDefaults
                        | kAuthorizationFlagExtendRights
                        | kAuthorizationFlagInteractionAllowed
                        | kAuthorizationFlagPreAuthorize;
        OSStatus authErr = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, authFlags, &authRef);
        if (authErr != noErr) {
            authRef = nil;
            NSLog(@"No authorization has been granted to modify network configuration");
            return;
        }
    }
    
    SCPreferencesRef prefRef = SCPreferencesCreateWithAuthorization(nil, CFSTR("GoAgentX"), nil, authRef);
    
    NSDictionary *sets = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);
    
    // 遍历系统中的网络设备列表，设置 AirPort 和 Ethernet 的代理
    if (previousDeviceProxies.count == 0) {
        for (NSString *key in [sets allKeys]) {
            NSMutableDictionary *dict = [sets objectForKey:key];
            NSString *hardware = [dict valueForKeyPath:@"Interface.Hardware"];
            if ([hardware isEqualToString:@"AirPort"] || [hardware isEqualToString:@"Ethernet"]) {
                NSDictionary *proxies = [dict objectForKey:(NSString *)kSCEntNetProxies];
                if (proxies != nil) {
                    [previousDeviceProxies setObject:[proxies mutableCopy] forKey:key];
                }
            }
        }
    }
    
    if (useProxy) {
        // 如果已经获取了旧的代理设置就直接用之前获取的，防止第二次获取到设置过的代理
        for (NSString *deviceId in previousDeviceProxies) {
            CFDictionaryRef proxies = SCPreferencesPathGetValue(prefRef, (__bridge CFStringRef)[self proxiesPathOfDevice:deviceId]);
            [self modifyPrefProxiesDictionary:(__bridge NSMutableDictionary *)proxies withProxyEnabled:YES];
            SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)[self proxiesPathOfDevice:deviceId], proxies);
        }
        
    } else {
        for (NSString *deviceId in previousDeviceProxies) {
            // 防止之前获取的代理配置还是启用了 SOCKS 代理或者 PAC 的，直接将两种代理方式禁用
            NSMutableDictionary *dict = [previousDeviceProxies objectForKey:deviceId];
            [self modifyPrefProxiesDictionary:dict withProxyEnabled:NO];
            SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)[self proxiesPathOfDevice:deviceId], (__bridge CFDictionaryRef)dict);
        }
        
        [previousDeviceProxies removeAllObjects];
    }
    
    SCPreferencesCommitChanges(prefRef);
    SCPreferencesApplyChanges(prefRef);
    SCPreferencesSynchronize(prefRef);
}


#pragma mark - Core Data

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.xujiwei.ProxyMenu" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"ProxyMenu"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ProxyMenu" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"ProxyMenu.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
