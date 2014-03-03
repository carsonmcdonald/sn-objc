#import "SNDeviceDetail.h"

@implementation SNDeviceDetail

- (id)init
{
    if ( self = [super init] )
    {
        self.responseType = DeviceDetail;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"DeviceDetail: deviceType=%@, friendlyName=%@, modelNumber=%@, modelDescription=%@, modelName=%@, softwareVersion=%@, hardwareVersion=%@, serialNum=%@, UDN=%@, iconURLList=%@, roomName=%@, displayName=%@, services=%@", _deviceType, _friendlyName, _modelNumber, _modelDescription, _modelName, _softwareVersion, _hardwareVersion, _serialNum, _UDN, _iconURLList, _roomName, _displayName, _services];
}

@end
