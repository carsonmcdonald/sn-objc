#import "SNCommunicator.h"

#import "SNDeviceDetail.h"
#import "SNService.h"
#import "SNServiceSpec.h"
#import "SNServiceActionResponse.h"

#import <libxml/parser.h>
#import <libxml/tree.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@interface SNCommunicator(Private)

- (SNResponse *)convertXML:(NSString *)xmlData withAction:(SNServiceSpecAction *)serviceAction withActionURN:(NSString *)actionURN;
- (void)convertXML:(NSString *)xmlData toObject:(NSObject *)obj usingXPathToProperties:(NSDictionary *)xpathToProp;

@end

@implementation SNCommunicator
{
    NSURLSession *session;
}

- (id)init
{
    if ( self = [super init] )
    {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:nil
                                           delegateQueue:nil];
    }
    return self;
}

- (void)requestDeviceInformation:(SNDevice *)device
{
    NSURL *deviceURL = [NSURL URLWithString:@"/xml/device_description.xml" relativeToURL:device.baseURL];
    
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
                                                       [self convertXML:responseValue
                                                               toObject:deviceDetail
                                                 usingXPathToProperties:@{@"//gns:root/gns:device/gns:friendlyName/text()": @"friendlyName",
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
                                                                          @"//gns:root/gns:device/gns:iconList/gns:icon/gns:url/text()": @{@"type": [NSArray class], @"name": @"iconURLList"}}
                                                        withCurrentRoot:nil];
                                                       
                                                       if(_successBlock)
                                                       {
                                                           _successBlock(deviceDetail);
                                                       }
                                                   }
                                                   
                                               }];
    
    [requestTask resume];
}

- (void)requestServiceSpecInformation:(SNDevice *)device withSCPDURL:(NSString *)SCPDURL
{
    NSURL *deviceURL = [NSURL URLWithString:SCPDURL relativeToURL:device.baseURL];
    
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
                                                       
                                                       SNServiceSpec *spec = [[SNServiceSpec alloc] init];
                                                       [self convertXML:responseValue
                                                               toObject:spec
                                                 usingXPathToProperties:@{@"//gns:scpd/gns:serviceStateTable/gns:stateVariable": @{@"type": [NSDictionary class], @"name": @"stateTable"},
                                                                          @"//gns:scpd/gns:actionList/gns:action": @{@"type": [NSDictionary class], @"name": @"actionTable"}}
                                                        withCurrentRoot:nil];
                                                      
                                                       if(_successBlock)
                                                       {
                                                           _successBlock(spec);
                                                       }
                                                   }
                                               }];
    
    [requestTask resume];
}

- (void)requestServiceAction:(SNDevice *)device withService:(SNService *)service withActionSpec:(SNServiceSpecAction *)specAction withParameters:(NSDictionary *)paramters
{
    NSURL *deviceURL = [NSURL URLWithString:service.controlURL relativeToURL:device.baseURL];
    
    NSMutableString *postRequest = [[NSMutableString alloc] init];
    [postRequest appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"];
    [postRequest appendString:@"<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"];
    [postRequest appendString:@"<s:Body>"];
    [postRequest appendString:[NSString stringWithFormat:@"<b:%@ xmlns:b=\"%@\">", specAction.name, service.serviceType]];
    // todo set input params here
    [postRequest appendString:[NSString stringWithFormat:@"</b:%@>", specAction.name]];
    [postRequest appendString:@"</s:Body>"];
    [postRequest appendString:@"</s:Envelope>"];
    
    NSMutableURLRequest *postURLRequest = [NSMutableURLRequest requestWithURL:deviceURL];
    [postURLRequest setHTTPMethod:@"POST"];
    [postURLRequest setValue:[NSString stringWithFormat:@"%@#%@", service.serviceType, specAction.name] forHTTPHeaderField:@"SOAPAction"];
    [postURLRequest setValue:@"text/xml; charset=utf8" forHTTPHeaderField:@"Content-type"];
    [postURLRequest setHTTPBody:[postRequest dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *requestTask = [session dataTaskWithRequest:postURLRequest
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
                                                       NSString *responseValue = [NSString stringWithFormat:@"%@\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ];

                                                       if(_successBlock)
                                                       {
                                                           _successBlock([self convertXML:responseValue withAction:specAction withActionURN:service.serviceType]);
                                                       }
                                                   }
                                                   
                                               }];
    [requestTask resume];
}

- (SNResponse *)convertXML:(NSString *)xmlData withAction:(SNServiceSpecAction *)serviceAction withActionURN:(NSString *)actionURN
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
        return nil;
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
        return nil;
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
        return nil;
    }
    
    if(xmlXPathRegisterNs(xpathCtx, rootNode->ns->prefix == NULL ? (BAD_CAST "s") : rootNode->ns->prefix, rootNode->ns->href) != 0)
    {
        xmlXPathFreeContext(xpathCtx);
        xmlFreeDoc(doc);
        if(_errorBlock)
        {
            _errorBlock([NSError errorWithDomain:SNCommunicatorDomain
                                            code:-103
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to parse response document, unable to register namespace", nil)}]);
        }
        return nil;
    }
    
    if(xmlXPathRegisterNs(xpathCtx, (BAD_CAST "u"), (BAD_CAST [actionURN UTF8String])) != 0)
    {
        xmlXPathFreeContext(xpathCtx);
        xmlFreeDoc(doc);
        if(_errorBlock)
        {
            _errorBlock([NSError errorWithDomain:SNCommunicatorDomain
                                            code:-103
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to parse response document, unable to register namespace", nil)}]);
        }
        return nil;
    }
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    
    [serviceAction.argumentList enumerateKeysAndObjectsUsingBlock:^(NSString *name, SNServiceSpecActionArgument *actionArg, BOOL *stop) {
        
        if([actionArg.direction isEqualToString:@"out"])
        {
            NSString *xpath = [NSString stringWithFormat:@"//s:Envelope/s:Body/u:%@Response/%@/text()", serviceAction.name, actionArg.name];
            
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
                *stop = YES;
            }
            
            if(!*stop)
            {
                if(xpathObj->nodesetval != NULL && xpathObj->nodesetval->nodeNr > 0)
                {
                    // todo use for correct parsing actionArg.relatedStateVariable
                    values[actionArg.name] = [NSString stringWithFormat:@"%s", xpathObj->nodesetval->nodeTab[0]->content];
                }
            }
        }
        
    }];
    
    SNServiceActionResponse *response = [[SNServiceActionResponse alloc] init];
    response.responseType = ServiceActionResponse;
    response.responseValues = values;
    return response;
}

- (void)convertXML:(NSString *)xmlData toObject:(NSObject *)obj usingXPathToProperties:(NSDictionary *)xpathToProp withCurrentRoot:(NSString *)xpathRoot
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
                                [self convertXML:xmlData
                                        toObject:service
                          usingXPathToProperties:@{[NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:serviceType/text()", i+1]: @"serviceType",
                                                   [NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:serviceId/text()", i+1]: @"serviceId",
                                                   [NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:controlURL/text()", i+1]: @"controlURL",
                                                   [NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:eventSubURL/text()", i+1]: @"eventSubURL",
                                                   [NSString stringWithFormat:@"//gns:root/gns:device/gns:serviceList/gns:service[%d]/gns:SCPDURL/text()", i+1]: @"SCPDURL"}
                                 withCurrentRoot:nil];
                                [propValue addObject:service];
                            }
                        }
                    }
                    [obj setValue:propValue forKey:propName];
                }
                else if([prop[@"type"] isEqualTo:[NSDictionary class]])
                {
                    NSMutableDictionary *propValue = [[NSMutableDictionary alloc] init];
                    for(int i=0; i<xpathObj->nodesetval->nodeNr; i++)
                    {
                        if([xpath isEqualToString:@"//gns:scpd/gns:serviceStateTable/gns:stateVariable"])
                        {
                            // todo handle allowedValueList and allowedValueRange
                            
                            SNServiceSpecVariable *variable = [[SNServiceSpecVariable alloc] init];
                            [self convertXML:xmlData
                                    toObject:variable
                      usingXPathToProperties:@{[NSString stringWithFormat:@"//gns:scpd/gns:serviceStateTable/gns:stateVariable[%d]/gns:name/text()", i+1]: @"name",
                                               [NSString stringWithFormat:@"//gns:scpd/gns:serviceStateTable/gns:stateVariable[%d]/gns:dataType/text()", i+1]: @"dataType"}
                             withCurrentRoot:nil];
                            
                            propValue[variable.name] = variable;
                        }
                        else if([xpath isEqualToString:@"//gns:scpd/gns:actionList/gns:action"])
                        {
                            SNServiceSpecAction *action = [[SNServiceSpecAction alloc] init];
                            [self convertXML:xmlData
                                    toObject:action
                      usingXPathToProperties:@{[NSString stringWithFormat:@"//gns:scpd/gns:actionList/gns:action[%d]/gns:name/text()", i+1]: @"name",
                                               [NSString stringWithFormat:@"//gns:scpd/gns:actionList/gns:action[%d]/gns:argumentList/gns:argument", i+1]: @{@"type": [NSDictionary class], @"name": @"argumentList"}}
                             withCurrentRoot:[NSString stringWithFormat:@"//gns:scpd/gns:actionList/gns:action[%d]/gns:argumentList/gns:argument", i+1]];
                            
                            propValue[action.name] = action;
                        }
                        else if([xpath rangeOfString:@"//gns:scpd/gns:actionList/gns:action\\[\\d+]/gns:argumentList/gns:argument" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch].location != NSNotFound)
                        {                            
                            SNServiceSpecActionArgument *argument = [[SNServiceSpecActionArgument alloc] init];
                            [self convertXML:xmlData
                                    toObject:argument
                      usingXPathToProperties:@{[NSString stringWithFormat:@"%@[%d]/gns:name/text()", xpathRoot, i+1]: @"name",
                                               [NSString stringWithFormat:@"%@[%d]/gns:direction/text()", xpathRoot, i+1]: @"direction",
                                               [NSString stringWithFormat:@"%@[%d]/gns:relatedStateVariable/text()", xpathRoot, i+1]: @"relatedStateVariable"}
                             withCurrentRoot:nil];
                            
                            propValue[argument.name] = argument;
                        }
                        else
                        {
                            NSLog(@"Missed: %@", xpath);
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
