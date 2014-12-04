//
//  VCardParser.h
//  Handoff
//
//  Created by Yifei Zhou on 12/4/14.
//  Copyright (c) 2014 Yifei Zhou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VCardParser : NSObject

+ (NSArray *)parseWithContentOfFile:(NSString *)filePath;
+ (NSArray *)parseWithData:(NSData *)data;

@end
