#import "BLMASSession.h"
#import "BLBluetoothOBEXSession.h"


@interface BLMASSession ()
@property (nonatomic, retain) BLBluetoothOBEXSession *session;
@property (nonatomic, assign) IOBluetoothUserNotification *disconnectNotification;
@end


@implementation BLMASSession

- (id)initWithDevice:(IOBluetoothDevice *)device {
    self = [super init];
    if(self) {
        _device = [device retain];
    }
    return self;
}

#define MAS_TARGET_HEADER_UUID "\xBB\x58\x2B\x40\x42\x0C\x11\xDB\xB0\xDE\x08\x00\x20\x0C\x9A\x66"
- (void)connect {
    IOBluetoothSDPServiceRecord *record = [_device getServiceRecordForUUID:[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassMessageAccessServer]];
    [_session release];
    _session = [[BLBluetoothOBEXSession alloc] initWithSDPServiceRecord:record];

    [_session sendConnect:@{
        (id)kOBEXHeaderIDKeyTarget: [NSData dataWithBytesNoCopy:MAS_TARGET_HEADER_UUID length:16 freeWhenDone:NO]
    } handler:^(BLBluetoothOBEXSession *session, NSDictionary *headers, NSError *error) {
        if(error) {
            if([_delegate respondsToSelector:@selector(masSession:connectionError:)]) {
                [_delegate masSession:self connectionError:error];
            }
        } else {
            // Get connection id
            [_connectionId release];
            _connectionId = [headers[(id)kOBEXHeaderIDKeyConnectionID] retain];

            // Register for disconnect
            _disconnectNotification = [_device registerForDisconnectNotification:self selector:@selector(disconnectedNotification:device:)];

            // Notify delegate
            if([_delegate respondsToSelector:@selector(masSessionConnected:)]) {
                [_delegate masSessionConnected:self];
            }
        }
    }];
}

- (void)setNotificationsEnabled:(BOOL)enabled {
    if(!_connectionId) return;
    
    NSMutableData *emptyBody = [NSMutableData dataWithBytes:"\x30" length:1];
    NSData *appParams = [NSData dataWithBytesNoCopy:(enabled ? "\x0E\x01\x01" : "\x0E\x01\x00") length:3 freeWhenDone:NO];
    [_session sendPut:@{
        (id)kOBEXHeaderIDKeyConnectionID: _connectionId,
        (id)kOBEXHeaderIDKeyType: @"x-bt/MAP-NotificationRegistration",
        (id)kOBEXHeaderIDKeyAppParameters: appParams
    } body:emptyBody handler:^(BLBluetoothOBEXSession *session, NSDictionary *headers, NSError *error) {
        if(error) {
            if([_delegate respondsToSelector:@selector(masSession:notificationsChangeError:)]) {
                [_delegate masSession:self notificationsChangeError:error];
            }
        } else if(enabled) {
            if([_delegate respondsToSelector:@selector(masSessionNotificationsEnabled:)]) {
                [_delegate masSessionNotificationsEnabled:self];
            }
        } else {
            if([_delegate respondsToSelector:@selector(masSessionNotificationsDisabled:)]) {
                [_delegate masSessionNotificationsDisabled:self];
            }
        }
    }];
}

- (void)loadMessage:(NSString *)messageHandle {
    if(!_connectionId) return;

    [_session sendGet:@{
        (id)kOBEXHeaderIDKeyConnectionID: _connectionId,
        (id)kOBEXHeaderIDKeyType: @"x-bt/message",
        (id)kOBEXHeaderIDKeyName: messageHandle,
        (id)kOBEXHeaderIDKeyAppParameters: [NSData dataWithBytesNoCopy:"\x0A\x01\x00\x14\x01\x01" length:6 freeWhenDone:NO] // Attachment Off & Charset UTF-8
    } handler:^(BLBluetoothOBEXSession *session, NSDictionary *headers, NSError *error) {
        if(error) {
            if([_delegate respondsToSelector:@selector(masSession:message:loadError:)]) {
                [_delegate masSession:self message:messageHandle loadError:error];
            }
        } else {
            NSString *body = [[NSString alloc] initWithData:headers[(id)kOBEXHeaderIDKeyEndOfBody] encoding:NSUTF8StringEncoding];
            if([_delegate respondsToSelector:@selector(masSession:message:dataLoaded:)]) {
                NSDictionary *message = [self parseMessageBody:body];
                [_delegate masSession:self message:messageHandle dataLoaded:message];
            }
            [body release];
        }
    }];
}

- (NSDictionary *)parseMessageBody:(NSString *)body {
    // Parse out message
    //NSLog(@"%@ : ",body);
    NSRange messageStart = [body rangeOfString:@"\r\nBEGIN:MSG\r\n"];
    NSRange messageEnd = [body rangeOfString:@"\r\nEND:MSG\r\n" options:NSBackwardsSearch];
    NSUInteger start = messageStart.location+messageStart.length;
    NSString *messageText = [body substringWithRange:NSMakeRange(start, messageEnd.location - start)];
    
    /*NSRange r1 = [body rangeOfString:@"\r\nFN;CHARSET=UTF-8:"];
    NSRange r2 = [body rangeOfString:@"\r\nN;CHARSET=UTF-8:"];
    NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
    NSString *sendBy = [body substringWithRange:rSub];
    NSLog(@"sendBy : %@",sendBy);*/
    return @{@"rawMessage": body, @"body": messageText};
    return nil;
}

- (void)disconnect {
    [_session sendDisconnect:@{
        (id)kOBEXHeaderIDKeyConnectionID: _connectionId
    } handler:^(BLBluetoothOBEXSession *session, NSDictionary *headers, NSError *error) {
        if(error) {
            if([_delegate respondsToSelector:@selector(masSession:disconnectionError:)]) {
                [_delegate masSession:self disconnectionError:error];
            }
        } else {
            [self handleDisconnect];
            if([_delegate respondsToSelector:@selector(masSessionDisconnected:)]) {
                [_delegate masSessionDisconnected:self];
            }
        }
    }];
}

- (void)disconnectedNotification:(IOBluetoothUserNotification *)notification device:(IOBluetoothDevice *)device {
    [self handleDisconnect];
    if([_delegate respondsToSelector:@selector(masSessionDeviceDisconnected:)]) {
        [_delegate masSessionDeviceDisconnected:self];
    }
}

- (void)handleDisconnect {
    [_disconnectNotification unregister];
    _disconnectNotification = nil;
    [_connectionId release];
    _connectionId = nil;
    [_session release];
    _session = nil;
}

- (void)dealloc {
    [_disconnectNotification unregister];
    [_device release];
    [_session release];
    [_connectionId release];

    [super dealloc];
}

@end
