#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface VideoHelper : CDVPlugin
- (void)saveToUserLibrary:(CDVInvokedUrlCommand*)command;
@end
