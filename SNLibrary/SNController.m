#import "SNController.h"

#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#define SN_ERROR_DOMAIN @"SNErrorDomain"
#define ST_URN @"urn:schemas-upnp-org:device:ZonePlayer:1"
#define M_SEARCH_TTL 3

@implementation SNController
{
    dispatch_queue_t deviceListenQueue;
    DeviceRegistrationBlock currentDeviceRegistrationBlock;
    BOOL deviceMonitorEnabled;
    int deviceMonitorSocket;
}

- (id)init
{
    if(self = [super init])
    {
        deviceListenQueue = dispatch_queue_create("sn.device.listen.queue", 0);
        deviceMonitorEnabled = YES;
    }
    return self;
}

- (void)dealloc
{
    [self stopMonitoringForDevices];
}

- (void)monitorForDevices:(DeviceRegistrationBlock)deviceRegistrationBlock error:(NSError * __autoreleasing *)error
{
    currentDeviceRegistrationBlock = [deviceRegistrationBlock copy];
    
    deviceMonitorEnabled = YES;
    
    deviceMonitorSocket = socket(AF_INET, SOCK_DGRAM, 0);
    if(deviceMonitorSocket < 0)
    {
        if(error)
        {
            *error = [NSError errorWithDomain:SN_ERROR_DOMAIN
                                         code:errno
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", strerror(errno)]}];
        }
        
        deviceMonitorEnabled = NO;
        return;
    }
    
    struct sockaddr_in servaddr;
    bzero(&servaddr, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    servaddr.sin_port = htons(1900);
    
    if(bind(deviceMonitorSocket, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0)
    {
        if(error)
        {
            *error = [NSError errorWithDomain:SN_ERROR_DOMAIN
                                         code:errno
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", strerror(errno)]}];
        }
        
        deviceMonitorEnabled = NO;
        return;
    }
    
    dispatch_async(deviceListenQueue, ^{
        
        while (deviceMonitorEnabled)
        {
            char mesg[64 * 1024];
            struct sockaddr_in clientAddr;
            socklen_t clientAddrLen = sizeof(clientAddr);
            
            ssize_t mesgLen = recvfrom(deviceMonitorSocket, mesg, sizeof(mesg), 0, (struct sockaddr *)&clientAddr, &clientAddrLen);
            if(mesgLen >= 0)
            {
                mesg[mesgLen] = 0;
                
                __block NSString *descriptionLocation = nil;
                __block NSString *st = nil;
                
                NSString *response = [NSString stringWithFormat:@"%s", mesg];
                
                NSArray *responseLines = [response componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
                [responseLines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
                   
                    NSArray *lineParts = [line componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@":"]];
                    if(lineParts.count >= 2)
                    {
                        if([lineParts[0] caseInsensitiveCompare:@"location"] == NSOrderedSame)
                        {
                            descriptionLocation = [[line substringFromIndex:@"location:".length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        }
                        else if([lineParts[0] caseInsensitiveCompare:@"st"] == NSOrderedSame)
                        {
                            st = [[line substringFromIndex:@"st:".length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        }
                    }
                }];
                
                if(descriptionLocation != nil && st != nil && [st caseInsensitiveCompare:@"urn:schemas-upnp-org:device:ZonePlayer:1"] == NSOrderedSame)
                {
                    SNDevice *device = [[SNDevice alloc] init];
                    device.ipAddr = [NSString stringWithFormat:@"%s", inet_ntoa(clientAddr.sin_addr)];
                    device.descriptionURL = [NSURL URLWithString:descriptionLocation];
                    device.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@/", device.descriptionURL.scheme, device.descriptionURL.host, device.descriptionURL.port]];
                    deviceRegistrationBlock(device);
                }
            }
        }
    });
}

- (void)stopMonitoringForDevices
{
    deviceMonitorEnabled = NO;
    
    close(deviceMonitorSocket);
}

- (void)requestDeviceList:(NSError * __autoreleasing *)error
{
    if(deviceMonitorEnabled)
    {
        unsigned char TTL = M_SEARCH_TTL;
        if (setsockopt(deviceMonitorSocket, IPPROTO_IP, IP_MULTICAST_TTL, (char *)&TTL, sizeof(TTL)) < 0)
        {
            if(error)
            {
                *error = [NSError errorWithDomain:SN_ERROR_DOMAIN
                                             code:errno
                                         userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s", strerror(errno)]}];
            }
            return;
        }

        NSString *bcastStr = [NSString stringWithFormat:@"M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:reservedSSDPport\r\nMAN: ssdp:discover\r\nMX: %d\r\nST: %@\r\n\0", M_SEARCH_TTL, ST_URN];

        struct sockaddr_in bcastaddr;
        bzero(&bcastaddr, sizeof(bcastaddr));
        bcastaddr.sin_len = sizeof(bcastaddr);
        bcastaddr.sin_family = AF_INET;
        bcastaddr.sin_port = htons(1900);
        bcastaddr.sin_addr.s_addr = inet_addr("239.255.255.250");
        
        sendto(deviceMonitorSocket, [bcastStr UTF8String], bcastStr.length, 0, (struct sockaddr *)&bcastaddr, sizeof(bcastaddr));
    }
    else
    {
        NSLog(@"Request device list while not monitoring device responses, ignoring request.");
    }
}

@end
