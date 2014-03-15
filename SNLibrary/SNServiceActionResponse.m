#import "SNServiceActionResponse.h"

@implementation SNServiceActionResponse

- (NSString *)description
{
    return [NSString stringWithFormat:@"ServiceActionResponse: responseValues=%@", _responseValues];
}

@end
