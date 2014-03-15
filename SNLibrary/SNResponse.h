#import <Foundation/Foundation.h>

@interface SNResponse : NSObject

enum SNResponseType {
    DeviceDetail,
    Service,
    ServiceSpec,
    ServiceActionResponse
};

@property (assign, nonatomic) enum SNResponseType responseType;

@end
