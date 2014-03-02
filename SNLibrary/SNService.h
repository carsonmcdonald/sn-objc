#import <Foundation/Foundation.h>

@interface SNService : NSObject

@property (strong, nonatomic) NSString *serviceType;
@property (strong, nonatomic) NSString *serviceId;
@property (strong, nonatomic) NSString *controlURL;
@property (strong, nonatomic) NSString *eventSubURL;
@property (strong, nonatomic) NSString *SCPDURL;

@end
