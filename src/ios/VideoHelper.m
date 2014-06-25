#import "VideoHelper.h"
#import "CDVFile.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetTrack.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVComposition.h>
#import <AVFoundation/AVVideoComposition.h>
#import <AVFoundation/AVCompositionTrack.h>
#import <AVFoundation/AVAssetExportSession.h>

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

- (void)cropSquareVideo:(CDVInvokedUrlCommand *)command
{
    NSString* argPath = [command.arguments objectAtIndex:0];
    
    // Get Movie url
    NSURL *movieURL = [NSURL fileURLWithPath:argPath];
    
    // Video asset
    AVURLAsset * videoAsset = [[AVURLAsset alloc]initWithURL:movieURL options:nil];
    
    // Video track assets
    AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *sourceAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:sourceVideoTrack atTime:kCMTimeZero error:nil];
    //[compositionVideoTrack setPreferredTransform:sourceVideoTrack.preferredTransform];
    
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:sourceAudioTrack atTime:kCMTimeZero error:nil];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    CGSize videoSize = sourceVideoTrack.naturalSize;
    CGFloat cropSize;
    //CGRect cropRect;
    
    if(videoSize.width < videoSize.height){
        
        cropSize = videoSize.width;
        //cropRect = CGRectMake(0, (videoSize.height - videoSize.width)/2, videoSize.width, videoSize.width);
        
    }else{
        
        cropSize = videoSize.height;
        //cropRect = CGRectMake((videoSize.width - videoSize.height)/2, 0, videoSize.height, videoSize.height);
        
    }
    
    //[layerInstruction setCropRectangle:cropRect atTime:kCMTimeZero];
    
    CGAffineTransform t = sourceVideoTrack.preferredTransform;
    CGAffineTransform rotationTransform;
    CGAffineTransform translationTransform;
    
    // 90° (portrait)
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
    {
        
        translationTransform = CGAffineTransformMakeTranslation(cropSize, 0);
        rotationTransform = CGAffineTransformRotate(translationTransform, M_PI_2);
        [layerInstruction setTransform:rotationTransform atTime:kCMTimeZero];
        
    }
    // 180° (portrait upside down)
    if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)  {
        
        translationTransform = CGAffineTransformMakeTranslation(0, cropSize);
        rotationTransform = CGAffineTransformRotate(translationTransform, M_PI*1.5);
        [layerInstruction setTransform:rotationTransform atTime:kCMTimeZero];
    
    }
    // 0° (turn left form portrait)
    if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
    {
        
        // Nothing to do
        
    }
    // 270° (turn right from portrait)
    if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
    {
        
        translationTransform = CGAffineTransformMakeTranslation(cropSize, cropSize);
        rotationTransform = CGAffineTransformRotate(translationTransform, -M_PI);
        [layerInstruction setTransform:rotationTransform atTime:kCMTimeZero];
        
    }
    
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1,30);
    videoComposition.renderScale = 1.0;
    videoComposition.renderSize = CGSizeMake(cropSize, cropSize);
    instruction.layerInstructions = [NSArray arrayWithObject: layerInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    // Configure export
    NSString* videoName = @"export.mov";
    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
    NSURL * exportUrl = [NSURL fileURLWithPath:exportPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }
    
    AVAssetExportSession * assetExport = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    assetExport.outputURL = exportUrl;
    assetExport.videoComposition = videoComposition;
    assetExport.shouldOptimizeForNetworkUse = YES;
    
    // Trigger export
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         
         CDVPluginResult *result;
         
         // create MediaFile object
         NSDictionary* fileDict = [self getMediaDictionaryFromPath:exportPath ofType:nil];
         NSArray* fileArray = [NSArray arrayWithObject:fileDict];
         
         switch (assetExport.status)
         {
             case AVAssetExportSessionStatusCompleted:
                 
                 NSLog(@"Export Complete");
                 //UISaveVideoAtPathToSavedPhotosAlbum(exportPath, nil, nil, nil);
                 result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:fileArray];
                 [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                 
                 break;
             case AVAssetExportSessionStatusFailed:
                 
                 NSLog(@"Export Failed");
                 NSLog(@"ExportSessionError: %@", [assetExport.error localizedDescription]);
                 result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Export Failed"];
                 [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                 
                 break;
             case AVAssetExportSessionStatusCancelled:
                 
                 NSLog(@"Export Failed");
                 NSLog(@"ExportSessionError: %@", [assetExport.error localizedDescription]);
                 result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Export Failed"];
                 
                 break;
         }
         
         [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
         
         return;
         
     }];
    
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