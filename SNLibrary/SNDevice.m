#import "SNDevice.h"

@implementation SNDevice

-(NSString *)description
{
    return [NSString stringWithFormat:@"Device: ip=%@, descriptionURL=%@", _ipAddr, _descriptionURL];
}

@end
