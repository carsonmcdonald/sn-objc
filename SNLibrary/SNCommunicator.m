#import "SNCommunicator.h"

#import "SNDeviceDetail.h"
#import "SNService.h"

#import <libxml/parser.h>
#import <libxml/tree.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@interface SNCommunicator(Private)

- (void)convertXML:(NSString *)xmlData toObject:(NSObject *)obj usingXPathToProperties:(NSDictionary *)xpathToProp;

@end

@implementation SNCommunicator

- (void)requestDeviceInformation:(SNDevice *)device
{
    NSURL *deviceURL = [NSURL URLWithString:@"/xml/device_description.xml" relativeToURL:device.baseURL];
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:nil
                                                     delegateQueue:nil];
    
    NSURLSessionDataTask *requestTask = [session dataTaskWithURL:deviceURL
                                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                   
                                                   if(error)
                                                   {
                                                       if(_errorBlock)
                                                       {
                                                           _errorBlock(error);
                                                       }
                                                   }
                                                   else
                                                   {
                                                       NSString *responseValue = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                       
                                                       SNDeviceDetail *deviceDetail = [[SNDeviceDetail alloc] init];
                                                       [self convertXML:responseValue toObject:deviceDetail usingXPathToProperties:@{@"//gns:root/gns:device/gns:friendlyName/text()": @"friendlyName",
                                                                                                                                     @"//gns:root/gns:device/gns:modelName/text()": @"modelName",
                                                                                                                                     @"//gns:root/gns:device/gns:serialNum/text()": @"serialNum",
                                                                                                                                     @"//gns:root/gns:device/gns:roomName/text()": @"roomName",
                                                                                                                                     @"//gns:root/gns:device/gns:deviceType/text()": @"deviceType",
                                                                                                                                     @"//gns:root/gns:device/gns:modelNumber/text()": @"modelNumber",
                                                                                                                                     @"//gns:root/gns:device/gns:modelDescription/text()": @"modelDescription",
                                                                                                                                     @"//gns:root/gns:device/gns:softwareVersion/text()": @"softwareVersion",
                                                                                                                                     @"//gns:root/gns:device/gns:hardwareVersion/text()": @"hardwareVersion",
                                                                                                                                     @"//gns:root/gns:device/gns:UDN/text()": @"UDN",
                                                                                                                                     @"//gns:root/gns:device/gns:displayName/text()": @"displayName",
                                                                                                                                     @"//gns:root/gns:device/gns:serviceList/gns:service": @{@"type": [NSArray class], @"name": @"services"},
                                                                                                                                     @"//gns:root/gns:device/gns:iconList/gns:icon/gns:url/text()": @{@"type": [NSArray class], @"name": @"iconURLList"}}];
                                                       
                                                       if(_successBlock)
                                                       {
                                                           _successBlock(deviceDetail);
                                                       }
                                                   }
                                                   
                                               }];
    
    [requestTask resume];
}

- (void)convertXML:(NSString *)xmlData toObject:(NSObject *)obj usingXPathToProperties:(NSDictionary *)xpathToProp
{
    xmlDocPtr doc = xmlReadMemory([xmlData UTF8String], (int)xmlData.length, NULL, NULL, 0);
    
    if (doc == NULL)
    {
        if(_errorBlock)
        {
            _errorBlock([NSError errorWithDomain:SNCommunicatorDomain
                                            code:-100
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to parse response document.", nil)}]);
        }
        return;
    }
    
    xmlNodePtr rootNode = xmlDocGetRootElement(doc);
    if(rootNode == NULL)
    {
        xmlFreeDoc(doc);
        if(_errorBlock)
        {
            _errorBlock([NSError errorWithDomain:SNCommunicatorDomain
                                            code:-101
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to parse response document, unable to find root node.", nil)}]);
        }
        return;
    }
    
    xmlXPathContextPtr xpathCtx = xmlXPathNewContext(doc);
    if(xpathCtx == NULL)
    {
        xmlFreeDoc(doc);
        if(_errorBlock)
        {
            _errorBlock([NSError errorWithDomain:SNCommunicatorDomain
                                            code:-102
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to parse response document, unable to create new xpath context.", nil)}]);
        }
        return;
    }
    
    if(xmlXPathRegisterNs(xpathCtx, rootNode->ns->prefix == NULL ? (BAD_CAST "gns") : rootNode->ns->prefix, rootNode->ns->href) != 0)
    {
        xmlXPathFreeContext(xpathCtx);
        xmlFreeDoc(doc);
        if(_errorBlock)
        {
            _errorBlock([NSError errorWithDomain:SNCommunicatorDomain
                                            code:-103
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to parse response document, unable to register namespace", nil)}]);
        }
        return;
    }
    
    [xpathToProp enumerateKeysAndObjectsUsingBlock:^(NSString *xpath, id prop, BOOL *stop) {
        
        const xmlChar* xpathExpr = BAD_CAST [xpath UTF8String];
        
        xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression(xpathExpr, xpathCtx);
        if(xpathObj == NULL)
        {
            xmlXPathFreeContext(xpathCtx);
            xmlFreeDoc(doc);
            if(_errorBlock)
            {
                _errorBlock([NSError errorWithDomain:SNCommunicatorDomain
                                                code:-104
                                            userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to parse response document, unable to evaluate xpath expression %s", xpathExpr)}]);
            }
            return;
        }
        
        if(xpathObj->nodesetval != NULL && xpathObj->nodesetval->nodeNr > 0)
        {
            if([prop isKindOfClass:[NSString class]])
            {
                [obj setValue:[NSString stringWithFormat:@"%s", xpathObj->nodesetval->nodeTab[0]->content] forKey:prop];
            }
            else if([prop isKindOfClass:[NSDictionary class]])
            {
                NSString *propName = prop[@"name"];
                if([prop[@"type"] isEqualTo:[NSArray class]])
                {
                    NSMutableArray *propValue = [[NSMutableArray alloc] init];
                    for(int i=0; i<xpathObj->nodesetval->nodeNr; i++)
                    {
                        if([xpath hasSuffix:@"text()"])
                        {
                            [propValue addObject:[NSString stringWithFormat:@"%s", xpathObj->nodesetval->nodeTab[i]->content]];
                        }
                        else
                        {
                            if([xpath isEqualToString:@"//gns:root/gns:device/gns:serviceList/gns:service"])
                            {
                                SNService *service = [[SNService alloc] init];
                                [self convertXML:xmlData toObject:service usingXPathToProperties:@{[NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:serviceType/text()", i+1]: @"serviceType",
                                                                                                   [NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:serviceId/text()", i+1]: @"serviceId",
                                                                                                   [NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:controlURL/text()", i+1]: @"controlURL",
                                                                                                   [NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:eventSubURL/text()", i+1]: @"eventSubURL",
                                                                                                   [NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:SCPDURL/text()", i+1]: @"SCPDURL"}];
                                [propValue addObject:service];
                            }
                        }
                    }
                    [obj setValue:propValue forKey:propName];
                }
            }
        }
        else
        {
            if(_errorBlock)
            {
                _errorBlock([NSError errorWithDomain:SNCommunicatorDomain
                                                code:-105
                                            userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Property not found: %@", prop)}]);
            }
        }
        
        xmlXPathFreeObject(xpathObj);
        
    }];
    
    xmlXPathFreeContext(xpathCtx);
    xmlFreeDoc(doc);
    xmlCleanupParser();
}

@end
