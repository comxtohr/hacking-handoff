#import "PhoneCallMonitor.h"

@interface PhoneCallMonitor ()


@property (nonatomic, assign) BOOL starting;
@property (nonatomic, assign) IOBluetoothUserNotification *connectionNotification;

@property (nonatomic, retain) IOBluetoothHandsFree *phone;

@end

@implementation PhoneCallMonitor


@synthesize starting;
@synthesize connectionNotification;

@synthesize phone;

-(void)dealloc {
	[connectionNotification unregister];
	connectionNotification = nil;
    
    [phone release];
    phone = nil;
    
	[super dealloc];
}

#ifndef NSFoundationVersionNumber10_7
#define NSFoundationVersionNumber10_7   833.1
#endif
#ifndef NSFoundationVersionNumber10_7_3
#define NSFoundationVersionNumber10_7_3 833.24
#endif

+(instancetype)sharedMonitor
{
    static PhoneCallMonitor *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PhoneCallMonitor alloc] init];
    });
    return sharedInstance;
}

-(id)init {
	if((self = [super init])){
		NSString *path = [[NSBundle mainBundle] pathForResource:@"HandsFreeDeviceSDPRecord" ofType:@"plist"];
		NSDictionary *serviceDict = [NSDictionary dictionaryWithContentsOfFile:path];
		if(serviceDict){
			IOReturn result = IOBluetoothAddServiceDict((CFDictionaryRef)serviceDict, NULL);
			if(result != kIOReturnSuccess){
				NSLog(@"Error 0x%x", result);
			}
		}else{
			NSLog(@"couldnt read");
		}
	}
	return self;
}

-(void)postRegistrationInit {
NSLog(@"postRegistrationInit");
	self.connectionNotification = [IOBluetoothDevice registerForConnectNotifications:self 
																									selector:@selector(bluetoothConnection:device:)];
}

-(void)bluetoothDisconnection:(IOBluetoothUserNotification*)note 
							  device:(IOBluetoothDevice*)device
{
	NSLog(@"disconnected");
	self.phone = nil;
	[note	unregister];
}

/* UNDOCUMETED DELEGATE CALL */
-(void)handsFree:(IOBluetoothDevice*)device incomingCallFrom:(NSString*)number {
    if (!Some1Calling) {
        Some1Calling = TRUE;
        NSLog(@"Call %@", number);
//        registerDevice = (IOBluetoothHandsFreeDevice*)device;
        NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Getting Call From : %@",number]
                                         defaultButton:NSLocalizedString(@"Yes", nil)
                                       alternateButton:NSLocalizedString(@"No", nil)
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@":P", nil)];
        
        NSInteger result = [alert runModal];
        if(result == NSOKButton){
            [registerDevice acceptCall];
            //Some1Calling = FALSE;
        }else{
            [registerDevice endCall];
            //Some1Calling = FALSE;
        }
    }
//    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
//    [notificationCenter addObserver:self selector:@selector(PickUpCall) name:@"call" object:nil];
    //[_delegate CallServer:number];
}
-(void)dialNumber:(NSString *)number
{
    if (!Some1Calling && registerDevice) {
        Some1Calling = TRUE;
        [registerDevice dialNumber:number];
    }
}
-(void)endCalling
{
    if (Some1Calling) {
        Some1Calling = FALSE;
        [registerDevice endCall];
    }
}
//-(void)PickUpCall{
//    
//}
-(void)handsFree:(IOBluetoothHandsFreeDevice *)device
		currentCall:(NSDictionary *)currentCall
{
	NSLog(@"Call %@", currentCall);	
}

-(void)handsFree:(IOBluetoothHandsFreeDevice *)device 
		incomingSMS:(NSDictionary *)sms
{
	NSLog(@"SMS %@", sms);
}

- (void)handsFree:(IOBluetoothHandsFree *)device connected:(NSNumber *)status {
	
}
- (void)handsFree:(IOBluetoothHandsFree *)device disconnected:(NSNumber *)status {
	
}
- (void)handsFree:(IOBluetoothHandsFree *)device scoConnectionOpened:(NSNumber *)status {
	
}
- (void)handsFree:(IOBluetoothHandsFree *)device scoConnectionClosed:(NSNumber *)status {
	
}

-(void)bluetoothConnection:(IOBluetoothUserNotification*)note 
						  device:(IOBluetoothDevice*)device 
{
    if (!self.starting) {
        self.starting = YES;
    }else{
        return;
    }
	if(device.isHandsFreeAudioGateway){
		NSLog(@"%@", [device name]);
		if(IOBluetoothLaunchHandsFreeAgent([device addressString]))
			NSLog(@"agent launched?");
		
		NSDictionary *scoDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																			 forKey:@"Autoconfig hidden"];
		IOReturn result = IOBluetoothAddSCOAudioDevice((IOBluetoothDeviceRef)[device getDeviceRef], (CFDictionaryRef)scoDict); 
		if (result != kIOReturnSuccess)
		{
			NSLog(@"error 0x%x, trying removing and readding", result);
			result = IOBluetoothRemoveSCOAudioDevice((IOBluetoothDeviceRef)device);
			NSLog(@"remove result 0x%x", result);
			result = IOBluetoothAddSCOAudioDevice([device getDeviceRef], (CFDictionaryRef)scoDict);
			if (result != kIOReturnSuccess)
			{
				NSLog(@"error adding SCO audio device. 0x%x", result);
			}
		}
		
		__block PhoneCallMonitor *blockSelf = self;
		double delayInSeconds = 0.0;
        NSLog(@"delayInSeconds");
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			IOBluetoothHandsFreeDevice *handsFree = [[IOBluetoothHandsFreeDevice alloc] initWithDevice:device 
																														 delegate:self];
			if(handsFree){
				NSLog(@"yay!");
                registerDevice = handsFree;
				[handsFree setSupportedFeatures:handsFree.supportedFeatures | IOBluetoothHandsFreeDeviceFeatureCLIPresentation];
				[handsFree connect];
				[blockSelf setPhone:handsFree];
				[handsFree release];
				[device registerForDisconnectNotification:blockSelf selector:@selector(bluetoothDisconnection:device:)];
			}else{
				NSLog(@"Sigh");
			}
		});
	}
}


-(NSString*)pluginDisplayName{
	return NSLocalizedString(@"Phone Module", @"");
}
-(NSImage*)preferenceIcon {
	static NSImage *_icon = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_icon = [[NSImage imageNamed:@"HWGPrefsPhone"] retain];
	});
	return _icon;
}
-(NSView*)preferencePane {
	return nil;
}

-(void)fireOnLaunchNotes {
	IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:@"<insert device address here for testing>"];
	[device openConnection];
}


-(NSArray*)noteNames {
	return [NSArray arrayWithObjects:@"IncomingPhoneCall", @"IncomingSMS", nil];
}
-(NSDictionary*)localizedNames {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Incoming Phone Call", @""), @"IncomingPhoneCall", NSLocalizedString(@"Incoming SMS", @""), @"IncomingSMS", nil];
}
-(NSDictionary*)noteDescriptions {
	return [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Incoming Phone Call", @""), @"IncomingPhoneCall", NSLocalizedString(@"Incoming SMS", @""), @"IncomingSMS", nil];
}
-(NSArray*)defaultNotifications {
	return [NSArray arrayWithObjects:@"IncomingPhoneCall", @"IncomingSMS", nil];
}

@end
