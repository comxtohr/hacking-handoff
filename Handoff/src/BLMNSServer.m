#import "BLMNSServer.h"


@interface BLMNSServer ()
@property (nonatomic, retain) IOBluetoothSDPServiceRecord *sdpRecord;
@property (nonatomic, retain) NSMutableDictionary *mnsSessions;
@end


@implementation BLMNSServer

- (id)init {
    self = [super init];
    if(self) {
        self.mnsSessions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)isPublished {
    return !!_sdpRecord;
}

- (BOOL)publishService {
    if([self isPublished]) return YES;
    NSLog(@"publishService .....");
    // Build SDP record attributes
    NSDictionary *recordAttributes = @{
        @"0001 - ServiceClassIDList": @[
            [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassMessageNotificationServer]
        ],
        @"0009 - BluetoothProfileDescriptorList": @[
            @[
                [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassMessageAccessProfile],
                @(0x100) // v1.0
            ]
        ],
        @"0100 - ServiceName*": @"CSMNSService"
    };
    // Publish SDP record
    _sdpRecord = [[BLBluetoothOBEXSession publishService:recordAttributes startHandler:^(BLBluetoothOBEXSession *session) {
        session.delegate = self;
        [_mnsSessions setObject:session forKey:[session getDevice]];
    }] retain];

    return !!_sdpRecord;
}

- (void)unpublishService {
    if(_sdpRecord) [BLBluetoothOBEXSession unpublishService:_sdpRecord];
    self.sdpRecord = nil;
}

#define MNS_TARGET_HEADER_UUID "\xBB\x58\x2B\x41\x42\x0C\x11\xDB\xB0\xDE\x08\x00\x20\x0C\x9A\x66"
#define CONNECTION_ID "\xDE\xAD\xBE\xEF"
- (void)OBEXSession:(BLBluetoothOBEXSession *)session receivedConnect:(NSDictionary *)headers {
    [session sendConnectResponse:kOBEXResponseCodeSuccessWithFinalBit headers:@{
        (id)kOBEXHeaderIDKeyConnectionID: [NSData dataWithBytesNoCopy:CONNECTION_ID length:4 freeWhenDone:NO],
        (id)kOBEXHeaderIDKeyWho: [NSData dataWithBytesNoCopy:MNS_TARGET_HEADER_UUID length:16 freeWhenDone:NO]
    }];

    if([_delegate respondsToSelector:@selector(mnsServer:listeningToDevice:)]) {
        [_delegate mnsServer:self listeningToDevice:[session getDevice]];
    }
}

- (void)OBEXSession:(BLBluetoothOBEXSession *)session receivedPut:(NSDictionary *)headers {
    NSData *endOfBody = headers[(id)kOBEXHeaderIDKeyEndOfBody];
    if(endOfBody) {
        NSString *body = [[NSString alloc] initWithData:endOfBody encoding:NSUTF8StringEncoding];
        NSXMLDocument *doc = [[NSXMLDocument alloc] initWithXMLString:body options:0 error:nil];
        NSArray *newMessageHandles = [doc nodesForXPath:@".//event[@type='NewMessage']/@handle" error:nil];
        if([newMessageHandles count] > 0) {
            NSString *handle = [[newMessageHandles objectAtIndex:0] stringValue];
            if([_delegate respondsToSelector:@selector(mnsServer:receivedMessage:fromDevice:)]) {
                [_delegate mnsServer:self receivedMessage:handle fromDevice:[session getDevice]];
            }
        }
        [doc release];
        [body release];
        
        [session sendPutSuccessResponse];
    } else {
        [session sendPutContinueResponse];
    }
}

- (void)OBEXSession:(BLBluetoothOBEXSession *)session receivedDisconnect:(NSDictionary *)headers {
    IOBluetoothDevice *device = [session getDevice];
    [_mnsSessions removeObjectForKey:device];
    if([_delegate respondsToSelector:@selector(mnsServer:deviceDisconnected:)]) {
        [_delegate mnsServer:self deviceDisconnected:device];
    }
}

- (void)OBEXSession:(BLBluetoothOBEXSession *)session receivedError:(NSError *)error {
    if([_delegate respondsToSelector:@selector(mnsServer:sessionError:device:)]) {
        [_delegate mnsServer:self sessionError:error device:[session getDevice]];
    }
}

- (void)dealloc {
    self.mnsSessions = nil;
    [self unpublishService];

    [super dealloc];
}

@end
