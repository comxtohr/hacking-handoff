#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "BLMASSession.h"
#import "BLMNSServer.h"


@protocol BLMNSServiceDelegate;


@interface BLMNSService : NSObject <BLMNSServerDelegate, BLMASSessionDelegate>

@property (nonatomic, assign) id<BLMNSServiceDelegate> delegate;

- (void)startListening:(IOBluetoothDevice *)device;
- (void)startListening:(IOBluetoothDevice *)device reconnect:(BOOL)autoReconnect;
- (void)stopListening:(IOBluetoothDevice *)device;
- (void)stopListeningAll;

@end


@protocol BLMNSServiceDelegate <NSObject>

@optional

- (void)mnsService:(BLMNSService *)service listeningToDevice:(IOBluetoothDevice *)device;
- (void)mnsService:(BLMNSService *)service stoppedListeningToDevice:(IOBluetoothDevice *)device;
- (void)mnsService:(BLMNSService *)service messageReceived:(NSDictionary *)message;

@end