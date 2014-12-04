//
//  VCardParser.m
//  Handoff
//
//  Created by Yifei Zhou on 12/4/14.
//  Copyright (c) 2014 Yifei Zhou. All rights reserved.
//

#import "VCardParser.h"
#import <AddressBook/AddressBook.h>

@implementation VCardParser

+ (NSArray *)parseWithContentOfFile:(NSString *)filePath
{
    return [VCardParser parseWithData:[NSData dataWithContentsOfFile:filePath]];
}

+ (NSArray *)parseWithData:(NSData *)data
{
    NSMutableArray *contacts = [@[] mutableCopy];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *array = [string componentsSeparatedByString:@"\n"];
    NSMutableArray *singleCard = [@[] mutableCopy];
    for (NSString *line in array) {
        if ([line hasPrefix:@"BEGIN:VCARD"])
            [singleCard addObject:line];
        else if ([line hasPrefix:@"END:VCARD"]) {
            [singleCard addObject:line];
            [contacts addObjectsFromArray:[VCardParser readSingle:[[singleCard valueForKey:@"description"] componentsJoinedByString:@"\n"]]];
            [singleCard removeAllObjects];
        }
        else
            [singleCard addObject:line];
    }
    return contacts;
}

+ (NSArray *)readSingle:(NSString *)content
{
    NSMutableSet *contact = [NSMutableSet set];
    ABPersonRef person = (__bridge ABRecordRef)[[ABPerson alloc] initWithVCardRepresentation:[content dataUsingEncoding:NSUTF8StringEncoding]];
    CFStringRef firstName = ABRecordCopyValue(person, (__bridge CFStringRef)kABFirstNameProperty);
    CFStringRef lastName = ABRecordCopyValue(person, (__bridge CFStringRef)kABLastNameProperty);
    CFStringRef middleName = ABRecordCopyValue(person, (__bridge CFStringRef)kABMiddleNameProperty);
    NSString *name = [NSString stringWithFormat:@"%@%@%@", lastName == NULL ? @"" : (__bridge NSString *)lastName, middleName == NULL ? @"" : (__bridge NSString *)middleName, firstName == NULL ? @"" : (__bridge NSString *)firstName];
    
    ABMultiValueRef multiPhones = ABRecordCopyValue(person, (__bridge CFStringRef)kABPhoneProperty);
    for (CFIndex i = 0; i < ABMultiValueCount(multiPhones); i++) {
        CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
        NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
        CFRelease(phoneNumberRef);
        phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        [contact addObject:@{@"Name": name, @"Number": phoneNumber}];
    }
    CFRelease(multiPhones);
//    CFRelease(firstName);
//    CFRelease(lastName);
    return [contact allObjects];
}

@end