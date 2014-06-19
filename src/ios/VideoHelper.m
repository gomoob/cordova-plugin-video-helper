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
    }
    // create MediaFile object
    NSDictionary* fileDict = [self getMediaDictionaryFromPath:argPath ofType:nil];
    NSArray* fileArray = [NSArray arrayWithObject:fileDict];
    
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}

- (NSDictionary*)getMediaDictionaryFromPath:(NSString*)fullPath ofType:(NSString*)type
{
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSMutableDictionary* fileDict = [NSMutableDictionary dictionaryWithCapacity:5];
    
    CDVFile *fs = [self.commandDelegate getCommandInstance:@"File"];
    
    // Get canonical version of localPath
    NSURL *fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", fullPath]];
    NSURL *resolvedFileURL = [fileURL URLByResolvingSymlinksInPath];
    NSString *path = [resolvedFileURL path];
    
    CDVFilesystemURL *url = [fs fileSystemURLforLocalPath:path];
    
    [fileDict setObject:[fullPath lastPathComponent] forKey:@"name"];
    [fileDict setObject:fullPath forKey:@"fullPath"];
    if (url) {
        [fileDict setObject:[url absoluteURL] forKey:@"localURL"];
    }
    // determine type
    if (!type) {
        id command = [self.commandDelegate getCommandInstance:@"File"];
        if ([command isKindOfClass:[CDVFile class]]) {
            CDVFile* cdvFile = (CDVFile*)command;
            NSString* mimeType = [cdvFile getMimeTypeFromPath:fullPath];
            [fileDict setObject:(mimeType != nil ? (NSObject*)mimeType : [NSNull null]) forKey:@"type"];
        }
    }
    NSDictionary* fileAttrs = [fileMgr attributesOfItemAtPath:fullPath error:nil];
    [fileDict setObject:[NSNumber numberWithUnsignedLongLong:[fileAttrs fileSize]] forKey:@"size"];
    NSDate* modDate = [fileAttrs fileModificationDate];
    NSNumber* msDate = [NSNumber numberWithDouble:[modDate timeIntervalSince1970] * 1000];
    [fileDict setObject:msDate forKey:@"lastModifiedDate"];
    
    return fileDict;
}

@end