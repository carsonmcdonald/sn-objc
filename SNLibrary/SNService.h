#import <Foundation/Foundation.h>

#import "SNResponse.h"

@interface SNService : SNResponse

@property (strong, nonatomic) NSString *serviceType;
@property (strong, nonatomic) NSString *serviceId;
@property (strong, nonatomic) NSString *controlURL;
@property (strong, nonatomic) NSString *eventSubURL;
@property (strong, nonatomic) NSString *SCPDURL;

@end
