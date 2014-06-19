#import "VideoHelper.h"

@implementation VideoHelper
- (void)saveToUserLibrary:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* result = nil;
    NSString* argPath = [command.arguments objectAtIndex:0];
    
    /* don't need, it should automatically get saved*/
    NSLog(@"can save %@: %d ?", argPath, UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(argPath));
    if (&UIVideoAtPathIsCompatibleWithSavedPhotosAlbum != NULL && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(argPath) == YES) {
        NSLog(@"try to save movie");
        UISaveVideoAtPathToSavedPhotosAlbum(argPath, nil, nil, nil);
        NSLog(@"finished saving movie");
        
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:argPath];
        
    }else{
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error when saving video"];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}
@end