#import "SNService.h"

@implementation SNService

-(NSString *)description
{
    return [NSString stringWithFormat:@"Service: serviceType=%@, serviceId=%@, controlURL=%@, eventSubURL=%@, SCPDURL=%@", _serviceType, _serviceId, _controlURL, _eventSubURL, _SCPDURL];
}

@end
