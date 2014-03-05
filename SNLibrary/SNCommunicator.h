#import <Foundation/Foundation.h>

#import "SNDevice.h"
#import "SNResponse.h"

#define SNCommunicatorDomain @"SNCommunicatorDomain"

typedef void (^ResponseSuccessBlock)(SNResponse *response);
typedef void (^ResponseErrorBlock)(NSError *error);

@interface SNCommunicator : NSObject

@property (copy, nonatomic) ResponseSuccessBlock successBlock;
@property (copy, nonatomic) ResponseErrorBlock errorBlock;

- (void)requestDeviceInformation:(SNDevice *)device;
- (void)requestServiceSpecInformation:(SNDevice *)device withSCPDURL:(NSString *)SCPDURL;

@end
