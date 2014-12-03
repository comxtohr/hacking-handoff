//
//  AppDelegate.h
//  Handoff
//
//  Created by Yifei Zhou on 12/3/14.
//  Copyright (c) 2014 Yifei Zhou. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BLMNSService.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, BLMNSServiceDelegate, NSUserNotificationCenterDelegate>
{
    BLMNSService *service;
}

@end

