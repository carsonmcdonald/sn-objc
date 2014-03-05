#import "SNServiceSpec.h"

@implementation SNServiceSpecVariable

- (NSString *)description
{
    return [NSString stringWithFormat:@"Variable: name=%@, dataType=%@", _name, _dataType];
}

@end

@implementation SNServiceSpecActionArgument

- (NSString *)description
{
    return [NSString stringWithFormat:@"ActionArgument: name=%@, direction=%@, relatedStateVariable=%@", _name, _direction, _relatedStateVariable];
}

@end

@implementation SNServiceSpecAction

- (NSString *)description
{
    return [NSString stringWithFormat:@"Action: name=%@, argumentList=%@", _name, _argumentList];
}

@end

@implementation SNServiceSpec

- (id)init
{
    if ( self = [super init] )
    {
        self.responseType = ServiceSpec;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"ServiceSpec: stateTable=%@, actionTable=%@", _stateTable, _actionTable];
}

@end
