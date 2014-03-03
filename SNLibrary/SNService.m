#import "SNService.h"

@implementation SNService

- (id)init
{
    if ( self = [super init] )
    {
        self.responseType = Service;
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"Service: serviceType=%@, serviceId=%@, controlURL=%@, eventSubURL=%@, SCPDURL=%@", _serviceType, _serviceId, _controlURL, _eventSubURL, _SCPDURL];
}

@end
