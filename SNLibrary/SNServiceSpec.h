#import <Foundation/Foundation.h>

#import "SNResponse.h"

@interface SNServiceSpecVariable : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *dataType;

@end

@interface SNServiceSpecActionArgument : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *direction;
@property (strong, nonatomic) NSString *relatedStateVariable;

@end

@interface SNServiceSpecAction : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSDictionary *argumentList;

@end

@interface SNServiceSpec : SNResponse

@property (strong, nonatomic) NSDictionary *stateTable;
@property (strong, nonatomic) NSDictionary *actionTable;

@end
