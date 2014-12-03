#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import <Cocoa/Cocoa.h>

@protocol CallServerDelegate;
@interface PhoneCallMonitor : NSObject <IOBluetoothHandsFreeDelegate, IOBluetoothHandsFreeDeviceDelegate>{
    IOBluetoothHandsFreeDevice *registerDevice;
    BOOL Some1Calling;
}
+(instancetype)sharedMonitor;
@property (nonatomic, assign) id<CallServerDelegate> delegate;
-(void)dialNumber:(NSString *)number;
-(void)endCalling;
@end
//@protocol CallServerDelegate <NSObject>
//
//-(void)CallServer:(NSString *)FromNumber;
//-(void)PickUpCall;
//@optional
//@end