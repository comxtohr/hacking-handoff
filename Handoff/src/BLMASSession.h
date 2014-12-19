#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>


@protocol BLMASSessionDelegate;


@interface BLMASSession : NSObject
{
    NSString *textVal;
}
@property (nonatomic, retain, readonly) IOBluetoothDevice *device;
@property (nonatomic, retain, readonly) NSData *connectionId;
@property (nonatomic, assign) id<BLMASSessionDelegate> delegate;

- (id)initWithDevice:(IOBluetoothDevice *)device;
- (void)connect;
- (void)setNotificationsEnabled:(BOOL)enabled;
- (void)loadMessage:(NSString *)messageHandle;
- (void)disconnect;

@end


@protocol BLMASSessionDelegate <NSObject>

@optional

- (void)masSessionConnected:(BLMASSession *)session;
- (void)masSession:(BLMASSession *)session connectionError:(NSError *)error;
- (void)masSessionNotificationsEnabled:(BLMASSession *)session;
- (void)masSessionNotificationsDisabled:(BLMASSession *)session;
- (void)masSession:(BLMASSession *)session notificationsChangeError:(NSError *)error;
- (void)masSession:(BLMASSession *)session message:(NSString *)messageHandle dataLoaded:(NSDictionary *)messageData;
- (void)masSession:(BLMASSession *)session message:(NSString *)messageHandle loadError:(NSError *)error;
- (void)masSessionDisconnected:(BLMASSession *)session;
- (void)masSession:(BLMASSession *)session disconnectionError:(NSError *)error;
- (void)masSessionDeviceDisconnected:(BLMASSession *)session;

@end