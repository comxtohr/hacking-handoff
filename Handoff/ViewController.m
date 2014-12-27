//
//  ViewController.m
//  Handoff
//
//  Created by Yifei Zhou on 12/3/14.
//  Copyright (c) 2014 Yifei Zhou. All rights reserved.
//

#import "ViewController.h"
#import "PhoneCallMonitor.h"
#import "VCardParser.h"
#import <QREncoder/QREncoderOSX.h>
#import <netdb.h>
#import "UDPEcho.h"

@interface ViewController () <UDPEchoDelegate>

@property (strong, nonatomic) NSString *dialNumber;
@property (strong, nonatomic) NSArray *contacts;
@property (assign, nonatomic) PhoneCallMonitor *monitor;

@property (nonatomic, strong, readwrite) UDPEcho *      echo;
@property (nonatomic, strong, readwrite) NSMutableData *udpData;
@end

@implementation ViewController

@synthesize echo      = _echo;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    _dialNumber = @"";

    _monitor = [PhoneCallMonitor sharedMonitor];
    
//    NSString *filePath = @"/Users/Yifei/Downloads/c.vcf";
//    _contacts = [VCardParser parseWithContentOfFile:filePath];
    _contacts = @[];
    
    [_numberField setStringValue:_dialNumber];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setDoubleAction:@selector(selectNumber:)];
    
    NSString *address;
    NSArray *addresses = [[NSHost currentHost] addresses];
    for (NSString *anAddress in addresses) {
        if (![anAddress hasPrefix:@"127"] && [[anAddress componentsSeparatedByString:@"."] count] == 4) {
            address = anAddress;
            break;
        }
    }
    NSImage *image = [QREncoderOSX encode:address scale:2];
    _qrImageView.wantsLayer = YES;
    [_qrImageView setImage:image];
    [_qrImageView setImageScaling:NSScaleToFit];
    [_qrImageView layer].magnificationFilter = kCAFilterNearest;
    
    _udpData = [NSMutableData data];
    [self setupUDPServer];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)numberBtnClicked:(NSButton *)sender
{
    _dialNumber = [[_numberField stringValue] stringByAppendingString:sender.title];
    [_numberField setStringValue:_dialNumber];
}

- (IBAction)clearBtnClicked:(NSButton *)sender
{
    _dialNumber = @"";
    [_numberField setStringValue:_dialNumber];
}

- (IBAction)dialBtnClicked:(NSButton *)sender
{
    if ([sender.title isEqualToString:@"Dial"]) {
        NSLog(@"%@", _dialNumber);
        [_monitor dialNumber:_dialNumber];
        sender.title = @"Hang Off";
    } else {
        [_monitor endCalling];
        sender.title = @"Dial";
    }
}

#pragma mark - NSTableView DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return _contacts.count;
}

#pragma mark - NSTableView Delegate


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *result = nil;
    if ([tableColumn.identifier isEqualToString:@"Name"]) {
        result = [tableView makeViewWithIdentifier:@"Name" owner:self];
        result.textField.stringValue = [[_contacts objectAtIndex:row] objectForKey:@"Name"];
    } else if ([tableColumn.identifier isEqualToString:@"Number"]) {
        result = [tableView makeViewWithIdentifier:@"Number" owner:self];
        result.textField.stringValue = [[_contacts objectAtIndex:row] objectForKey:@"Number"];
    }
    return result;
}

- (void)selectNumber:(id)sender
{
    if ([sender isKindOfClass:[NSTableView class]]) {
        NSInteger row = ((NSTableView *)sender).selectedRow;
        NSString *number = [[_contacts objectAtIndex:row] objectForKey:@"Number"];
        _dialNumber = number;
        [_numberField setStringValue:_dialNumber];
    }
}

- (void)setupUDPServer
{
    self.echo = [[UDPEcho alloc] init];
    self.echo.delegate = self;
    [self.echo startServerOnPort:9999];
}

- (void)echo:(UDPEcho *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr
// This UDPEcho delegate method is called after successfully receiving data.
{
    assert(echo == self.echo);
#pragma unused(echo)
    assert(data != nil);
    assert(addr != nil);
    [_udpData appendData:data];
    if (data.length < 8192) {
        NSMutableString *   result;
        NSUInteger          dataLength;
        NSUInteger          dataIndex;
        const uint8_t *     dataBytes;
        
        dataLength = [_udpData length];
        dataBytes  = [_udpData bytes];
        
        result = [NSMutableString stringWithCapacity:dataLength];
        assert(result != nil);
        
//        [result appendString:@"\""];
        for (dataIndex = 0; dataIndex < dataLength; dataIndex++) {
            uint8_t     ch;
            
            ch = dataBytes[dataIndex];
            if (ch == 10) {
                [result appendString:@"\n"];
//            } else if (ch == 13) {
//                [result appendString:@"\r"];
//            } else if (ch == '"') {
//                [result appendString:@"\\\""];
//            } else if (ch == '\\') {
//                [result appendString:@"\\\\"];
//            } else if ( (ch >= ' ') && (ch < 127) ) {
//                [result appendFormat:@"%c", (int) ch];
//            } else {
            } else {
//                [result appendFormat:@"\\x%02x", (unsigned int) ch];
                [result appendFormat:@"%c", (int) ch];
            }
        }
//        [result appendString:@"\""];
        _contacts = [VCardParser parseWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
        [_tableView reloadData];
        _udpData = [NSMutableData data];
    }
}

- (void)echo:(UDPEcho *)echo didReceiveError:(NSError *)error
// This UDPEcho delegate method is called after a failure to receive data.
{
    assert(echo == self.echo);
#pragma unused(echo)
    assert(error != nil);
    NSLog(@"received error: %@", [error localizedDescription]);
}


@end
