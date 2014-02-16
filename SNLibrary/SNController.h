#import <Foundation/Foundation.h>

#import "SNDevice.h"

@interface SNController : NSObject

typedef void (^DeviceRegistrationBlock)(SNDevice *device);

- (void)monitorForDevices:(DeviceRegistrationBlock)deviceRegistrationBlock error:(NSError * __autoreleasing *)error;
- (void)stopMonitoringForDevices;
- (void)requestDeviceList:(NSError * __autoreleasing *)error;

@end
