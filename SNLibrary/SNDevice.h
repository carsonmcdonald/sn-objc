#import <Foundation/Foundation.h>

@interface SNDevice : NSObject

@property (strong, nonatomic) NSString *ipAddr;
@property (strong, nonatomic) NSURL *descriptionURL;
@property (strong, nonatomic) NSURL *baseURL;

@end
