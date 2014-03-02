#import "SNDevice.h"

@implementation SNDevice

- (NSString *)description
{
    return [NSString stringWithFormat:@"Device: ip=%@, descriptionURL=%@, baseURL=%@", _ipAddr, _descriptionURL, _baseURL];
}

@end
