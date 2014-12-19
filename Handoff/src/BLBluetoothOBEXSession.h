#import <IOBluetooth/IOBluetooth.h>


@protocol CSBluetoothOBEXSessionDelegate;
@class BLBluetoothOBEXSession;
typedef void(^ResponseHandler)(BLBluetoothOBEXSession*, NSDictionary*, NSError*);


@interface BLBluetoothOBEXSession : NSObject

@property (nonatomic, assign) id<CSBluetoothOBEXSessionDelegate> delegate;

- (IOBluetoothDevice *)getDevice;

// Server sessions
+ (IOBluetoothSDPServiceRecord *)publishService:(NSDictionary *)recordAttributes startHandler:(void (^)(BLBluetoothOBEXSession*))handler;
+ (void)unpublishService:(IOBluetoothSDPServiceRecord *)serviceRecord;
- (void)sendConnectResponse:(OBEXOpCode)responseCode headers:(NSDictionary *)headers;
- (void)sendPutContinueResponse;
- (void)sendPutSuccessResponse;

// Client sessions
- (instancetype)initWithSDPServiceRecord:(IOBluetoothSDPServiceRecord *)record;
- (void)sendConnect:(NSDictionary *)headers handler:(ResponseHandler)handler;
- (void)sendGet:(NSDictionary *)headers handler:(ResponseHandler)handler;
- (void)sendPut:(NSDictionary *)headers body:(NSMutableData *)body handler:(ResponseHandler)handler;
- (void)sendDisconnect:(NSDictionary *)headers handler:(ResponseHandler)handler;

@end


@protocol CSBluetoothOBEXSessionDelegate
@required

- (void)OBEXSession:(BLBluetoothOBEXSession *)session receivedConnect:(NSDictionary *)headers;
- (void)OBEXSession:(BLBluetoothOBEXSession *)session receivedPut:(NSDictionary *)headers;
- (void)OBEXSession:(BLBluetoothOBEXSession *)session receivedDisconnect:(NSDictionary *)headers;
- (void)OBEXSession:(BLBluetoothOBEXSession *)session receivedError:(NSError *)error;

@end