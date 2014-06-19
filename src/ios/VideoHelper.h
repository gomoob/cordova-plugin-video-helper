#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "CDVFile.h"

@interface VideoHelper : CDVPlugin
- (void)saveToUserLibrary:(CDVInvokedUrlCommand*)command;
- (NSDictionary*)getMediaDictionaryFromPath:(NSString*)fullPath ofType:(NSString*)type;
@end
