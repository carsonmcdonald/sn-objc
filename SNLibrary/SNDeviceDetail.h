#import <Foundation/Foundation.h>

#import "SNResponse.h"

@interface SNDeviceDetail : SNResponse

@property (strong, nonatomic) NSString *deviceType;
@property (strong, nonatomic) NSString *friendlyName;
@property (strong, nonatomic) NSString *modelNumber;
@property (strong, nonatomic) NSString *modelDescription;
@property (strong, nonatomic) NSString *modelName;
@property (strong, nonatomic) NSString *softwareVersion;
@property (strong, nonatomic) NSString *hardwareVersion;
@property (strong, nonatomic) NSString *serialNum;
@property (strong, nonatomic) NSString *UDN;
@property (strong, nonatomic) NSArray *iconURLList;
@property (strong, nonatomic) NSString *roomName;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) NSArray *services;

@end
