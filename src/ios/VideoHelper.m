#import "VideoHelper.h"
#import "CDVFile.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetTrack.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVComposition.h>
#import <AVFoundation/AVVideoComposition.h>
#import <AVFoundation/AVCompositionTrack.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVAudioSession.h>

@implementation VideoHelper

- (void)saveToUserLibrary:(CDVInvokedUrlCommand *)command
{

    CDVPluginResult* result = nil;
    
    NSString* videoPath = [command argumentAtIndex:0 withDefault:nil];
    
    // Checks if path is given in parameters
    if (videoPath == nil) {
        NSLog(@"Video Helper - Save to user library failed, file path is required !");
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Video Helper - Save to user library failed, file path is required !"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    
    // Checks if movie url is an existing file
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath] == FALSE){
        NSLog(@"Video Helper - Save to user library failed, video file does not exist at the indicated path %@ !", videoPath);
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Video Helper - Save to user library failed, video file does not exist at the indicated path !"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    
    // Checks file compatibility with photos album
    if (&UIVideoAtPathIsCompatibleWithSavedPhotosAlbum != NULL && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath) == YES) {
        NSLog(@"try to save movie");
        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, nil, nil, nil);
        NSLog(@"finished saving movie");
        
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:videoPath];
        
    }else{
        
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error when saving video"];
        
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}

- (void)cropSquareVideo:(CDVInvokedUrlCommand *)command
{
    
    NSString* videoPath = [command argumentAtIndex:0 withDefault:nil];
    
    // Checks if video path is given in parameters
    if (videoPath == nil) {
        NSLog(@"Video Helper - Crop square video failed, video file path is required !");
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Video Helper - Crop square video failed, video file path is required !"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    
    // Checks if movie url is an existing file
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath] == FALSE){
        NSLog(@"Video Helper - Crop square video failed, video file does not exist at indicated path %@ !", videoPath);
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Video Helper - Crop square video failed, video file does not exist at indicated path !"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
    
    // Get Movie url
    NSURL *movieURL = [NSURL fileURLWithPath:videoPath];
    
    // Video asset
    AVURLAsset * videoAsset = [[AVURLAsset alloc]initWithURL:movieURL options:nil];
    
    // Checks is video and audio tracks exist
    BOOL hasSourceVideoTracks = ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] > 0);
    BOOL hasSourceAudioTracks = ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0);
    
    // If no tracks found, return with error status
    if (hasSourceVideoTracks == FALSE) {

        NSLog(@"Export Failed, no video track found !");
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Export Failed, no video track found !"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        
    }
    
    // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    
    // Builds video composition
    AVAssetTrack *sourceVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:sourceVideoTrack atTime:kCMTimeZero error:nil];
    
    // Builds audio composition if audio track exists
    if(hasSourceAudioTracks) {

        AVAssetTrack *sourceAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:sourceAudioTrack atTime:kCMTimeZero error:nil];
        
    }
    
    // Prepares video compostion instructions
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    // Defines the size of the square video to crop
    CGSize videoSize = sourceVideoTrack.naturalSize;
    CGFloat cropSize;
    
    if(videoSize.width < videoSize.height){
        
        cropSize = videoSize.width;
        
    }else{
        
        cropSize = videoSize.height;
        
    }
    
    // Configures transformations to rotate the video to the right side
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
    
    // Defines video composition for the export
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
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]){
        
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
         NSDictionary* fileDict;
         NSArray* fileArray;
         
         switch (assetExport.status)
         {
             case AVAssetExportSessionStatusCompleted:
                 
                 NSLog(@"Export Complete");
                 
                 // create MediaFile object
                 fileDict = [self getMediaDictionaryFromPath:exportPath ofType:nil];
                 fileArray = [NSArray arrayWithObject:fileDict];
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

- (void)checkMicrophoneAccessPermission:(CDVInvokedUrlCommand *)command
{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        
        if (granted) {
            
            NSLog(@"Record audio permission granted !");
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:granted];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            
        }
        else {
            
            NSLog(@"Record audio permission not granted !");
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:granted];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            
        }
    }];
}

@end