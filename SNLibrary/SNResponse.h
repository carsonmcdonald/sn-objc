#import <Foundation/Foundation.h>

@interface SNResponse : NSObject

enum SNResponseType {
    DeviceDetail,
    Service
};

@property (assign, nonatomic) enum SNResponseType responseType;

@end
