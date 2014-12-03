#import <Foundation/Foundation.h>
#import "BLBluetoothOBEXSession.h"


@protocol BLMNSServerDelegate;


@interface BLMNSServer : NSObject <CSBluetoothOBEXSessionDelegate>

@property (nonatomic, assign) id<BLMNSServerDelegate> delegate;
@property (nonatomic, readonly, assign) BOOL isPublished;

- (BOOL)publishService;
- (void)unpublishService;

@end


@protocol BLMNSServerDelegate <NSObject>

@optional

- (void)mnsServer:(BLMNSServer *)server listeningToDevice:(IOBluetoothDevice *)device;
- (void)mnsServer:(BLMNSServer *)server receivedMessage:(NSString *)messageHandle fromDevice:(IOBluetoothDevice *)device;
- (void)mnsServer:(BLMNSServer *)server deviceDisconnected:(IOBluetoothDevice *)device;
- (void)mnsServer:(BLMNSServer *)server sessionError:(NSError *)error device:(IOBluetoothDevice *)device;

@end
