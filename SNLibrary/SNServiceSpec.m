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

- (BOOL)hasInParameters
{
    __block BOOL hasInParam = NO;
    [_argumentList enumerateKeysAndObjectsUsingBlock:^(NSString *name, SNServiceSpecActionArgument *arg, BOOL *stop) {
        if([arg.direction isEqualToString:@"in"])
        {
            *stop = YES;
            hasInParam = YES;
        }
    }];
    return hasInParam;
}

- (BOOL)hasOutParameters
{
    __block BOOL hasOutParam = NO;
    [_argumentList enumerateKeysAndObjectsUsingBlock:^(NSString *name, SNServiceSpecActionArgument *arg, BOOL *stop) {
        if([arg.direction isEqualToString:@"out"])
        {
            *stop = YES;
            hasOutParam = YES;
        }
    }];
    return hasOutParam;
}

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
