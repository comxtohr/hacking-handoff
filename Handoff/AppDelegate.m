//
//  AppDelegate.m
//  Handoff
//
//  Created by Yifei Zhou on 12/3/14.
//  Copyright (c) 2014 Yifei Zhou. All rights reserved.
//

#import "AppDelegate.h"
#import <IOBluetooth/IOBluetooth.h>
#import <IOBluetoothUI/IOBluetoothUI.h>
#import "PhoneCallMonitor.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    service = [[BLMNSService alloc] init];
    [service setDelegate:self];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [self connectToDevice];
}

- (void)connectToDevice {
    IOBluetoothDeviceSelectorController *ff = [IOBluetoothDeviceSelectorController deviceSelector];
    int t = [ff runModal];
    
    if (t == kIOBluetoothUISuccess) {
        IOBluetoothDevice *device = [[[ff getResults] lastObject] retain];
        if ([device openConnection] == kIOReturnSuccess) {
            NSLog(@"Connection open");
        } else {
            NSLog(@"Connection failed");
        }
        if ([device isConnected]) {
            NSLog(@"Working Called");
            PhoneCallMonitor *some = [PhoneCallMonitor sharedMonitor];
            [some postRegistrationInit];
            [service startListening:device reconnect:NO];
        }
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

- (void)mnsService:(BLMNSService *)service messageReceived:(NSDictionary *)message{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Emosewa";
    notification.informativeText = [message valueForKey:@"body"];
    notification.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
