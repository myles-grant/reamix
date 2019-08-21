//
//  Voiceover.m
//  Reamix
//
//  Created by myles grant on 2015-01-03.
//  Copyright (c) 2015 Pinecone . All rights reserved.
//

#import "Voiceover.h"

@implementation Voiceover
{
    
    NSTimer *recordTimer;
    NSTimer *levelTimer;
    
    AVAudioSession *voiceoverSession;
    AVPlayer *voiceoverVideoPlayer;
    AVPlayerLayer *layer;

    AVAsset *videoAsset;
    AVAsset *audioAsset;
    
    NSString *path;
    NSURL *voiceoverFileName;
    NSURL *voiceoverPlayback;
    
    BOOL voiceoverPaused;
    
    //
    int timerCount;
}
@synthesize camera;


#pragma mark - Video Selection


-(void)videoSelected
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)
    {
        //Selected video to voiceover
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No Saved Album Found"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        [self startMediaBrowserFromViewController:camera usingDelegate:self];
    }
    
    //UI
    camera.overlayTypeView.hidden = YES;
}


-(BOOL)startMediaBrowserFromViewController:(UIViewController*)controller usingDelegate:(id)delegate
{
    // 1 - Validation
    if(([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)
        || (delegate == nil)
        || (controller == nil))
    {
        return NO;
    }
    
    //Get Video
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    mediaUI.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, nil];
    mediaUI.allowsEditing = YES;
    mediaUI.delegate = delegate;
    [controller presentViewController:mediaUI animated:YES completion:nil];
    return YES;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //Handle video selection
    if (CFStringCompare ((__bridge_retained CFStringRef) [info objectForKey: UIImagePickerControllerMediaType], kUTTypeMovie, 0) == kCFCompareEqualTo)
    {
        
        //Load assets
        videoAsset = [AVAsset assetWithURL:[info objectForKey:UIImagePickerControllerMediaURL]];
        audioAsset = nil;
        
        //Setup View for voiceover
        voiceoverVideoPlayer = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:videoAsset]];
        
        layer = [AVPlayerLayer playerLayerWithPlayer:voiceoverVideoPlayer];
        [layer setFrame: camera.view.frame];
        [camera.view.layer insertSublayer:layer atIndex:1];
        [layer setBackgroundColor:[[UIColor blackColor] CGColor]];
        
        [voiceoverVideoPlayer setMuted:YES]; //Default
        
        //Setup tools
        [self tools];
        
        if(videoAsset != nil)
        {
            //Let user know video has been selected
            NSLog(@"Video Asset Loaded");
            
            //Setup voiceover view
            [self uiControl:@"viewSetup"];
            
            voiceoverPlayback = [info objectForKey:UIImagePickerControllerMediaURL];
            camera.overlayType = @"voiceover existing";
        }
        else
        {
            //Handle Error
        }
    }
    
    [camera dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -

-(void)audioIndicatorPlay
{
    //Play beep audio indicator before recording
    //audio indicator
    if(voiceoverPaused == YES)
    {
        [camera audioPlayerDidFinishPlaying:camera.musicPlayer successfully:YES];
        voiceoverPaused = NO;
    }
    else
    {
        [camera recordingIndicator:YES];
    }
}


#pragma mark - Audio Control

-(void)audioVolumeControl
{
    //Turn off or on audio
    if(voiceoverVideoPlayer.muted)
    {
        //Turn on audio
        [voiceoverVideoPlayer setMuted:NO];
        
        //UI hub
        [self hub:@"audio"];
        [self tools];
    }
    else
    {
        //Turn off audio
        [voiceoverVideoPlayer setMuted:YES];
        
        //UI hub
        [self hub:@"audio"];
        [self tools];
    }
}



#pragma mark - Recording

-(void)record
{
    if(audioAsset == nil)
    {
        // Define the recorder setting
        NSDictionary *recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,
                                       [NSNumber numberWithInt:44100],AVSampleRateKey,
                                       [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                                       [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                       [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                       [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey, nil];
        
        voiceoverFileName = [camera->connect setNewFile:@"voiceover" fileFormat:@".m4a"];
        
        // Initiate and prepare the recorder
        camera.recorder = [[AVAudioRecorder alloc] initWithURL:voiceoverFileName settings:recordSetting error:nil];
        camera.recorder.delegate = (id<AVAudioRecorderDelegate>)self;
        camera.recorder.meteringEnabled = YES;
        [camera.recorder prepareToRecord];
        
        voiceoverSession = [AVAudioSession sharedInstance];
        [voiceoverSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [voiceoverSession setActive:YES error:nil];
        
        //Load audio asset
        audioAsset = [AVAsset assetWithURL:voiceoverFileName];
        NSLog(@"audio asset loaded");
    }
    
    // Start voiceover recording
    [camera.recorder record];
    
    //Start video
    [voiceoverVideoPlayer play];
    
    //Start Timer
    [levelTimer invalidate];
    [recordTimer invalidate];
    
    //
    levelTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:camera selector:@selector(levelTimerCallback:) userInfo: nil repeats: YES];
    recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timer) userInfo:self repeats:YES];
    
    //UI Setup while recording voiceover
    [self uiControl:@"record"];
}


-(void)pause
{
    NSLog(@"pause");
    
    //Pause recording and timer
    [levelTimer invalidate];
    [recordTimer invalidate];

    
    [camera.recorder pause];
    [voiceoverVideoPlayer pause];
    
    //UI setup on paused recording
    [self uiControl:@"pause"];
}


-(void)stop
{
    NSLog(@"stop");
    
    //Pause audio recorder
    [camera.recorder stop];
    [voiceoverVideoPlayer pause];
    
    //Stop timer
    [levelTimer invalidate];
    [recordTimer invalidate];
    
    //audio indicator
    [camera recordingIndicator:NO];
    
    //Send to merge and export
    [self captureOutput:nil didFinishRecordingToOutputFileAtURL:nil fromConnections:nil error:nil];
}



#pragma mark - Merging


-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    
    //UI setup while merging video
    [self uiControl:@"merge"];
    
    NSLog(@"merging...");
    //Merge assets
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    //Set video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    
    //Set audio track
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    
    //ORIENTATION
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    AVAssetTrack *FirstAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    UIImageOrientation FirstAssetOrientation_  = UIImageOrientationUp;
    
    BOOL  isFirstAssetPortrait_  = NO;
    
    CGAffineTransform firstTransform = FirstAssetTrack.preferredTransform;
    
    if(firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0)
    {
        FirstAssetOrientation_= UIImageOrientationRight; isFirstAssetPortrait_ = YES;
    }
    if(firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0)
    {
        FirstAssetOrientation_ =  UIImageOrientationLeft; isFirstAssetPortrait_ = YES;
    }
    if(firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0)
    {
        FirstAssetOrientation_ =  UIImageOrientationUp;
    }
    if(firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0)
    {
        FirstAssetOrientation_ = UIImageOrientationDown;
    }
    
    CGFloat FirstAssetScaleToFitRatio = 320.0/FirstAssetTrack.naturalSize.width;
    
    if(isFirstAssetPortrait_)
    {
        FirstAssetScaleToFitRatio = 320.0/FirstAssetTrack.naturalSize.height;
        CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
        [FirstlayerInstruction setTransform:CGAffineTransformConcat(FirstAssetTrack.preferredTransform, FirstAssetScaleFactor) atTime:kCMTimeZero];
    }
    else
    {
        CGAffineTransform FirstAssetScaleFactor = CGAffineTransformMakeScale(FirstAssetScaleToFitRatio,FirstAssetScaleToFitRatio);
        [FirstlayerInstruction setTransform:CGAffineTransformConcat(CGAffineTransformConcat(FirstAssetTrack.preferredTransform, FirstAssetScaleFactor),CGAffineTransformMakeTranslation(0, 160)) atTime:kCMTimeZero];
    }
    [FirstlayerInstruction setOpacity:0.0 atTime:audioAsset.duration];
    
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,nil];;
    
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = CGSizeMake(320.0, 480.0);
    
    
    
    
    //Export
    NSURL *outputLink = [camera->connect setNewFile:@"mix" fileFormat:@".mov"];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = outputLink;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = MainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self exportDidFinish:exporter sender:@"voiceoverMix"];
        });
    }];
    
    
    NSString *sec = [NSString stringWithFormat:@"%i", ((int)CMTimeGetSeconds(audioAsset.duration))%60];
    NSString *min = [NSString stringWithFormat:@"%i", ((int)CMTimeGetSeconds(audioAsset.duration))/60];
    
    if([sec intValue] < 10)
    {
        sec = [NSString stringWithFormat:@"0%i", [sec intValue]];
    }
    if([min intValue] < 10)
    {
        min = [NSString stringWithFormat:@"0%i", [min intValue] ];
    }
    
    //Log info to db
    [camera->connect addNewRowIn:@"Videos" setValue:[outputLink lastPathComponent] forKeyPath:@"videoUrl"];
    [camera->connect updateRowIn:@"Videos" setValue:[NSString stringWithFormat:@"%@:%@", min, sec] forKeyPath:@"duration" atIndex:([[camera->connect getContextArray:@"Videos"] count]-1)];
}


#pragma mark - Exporting

-(void)exportDidFinish:(AVAssetExportSession*)exportSession sender:(NSString *)type
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success;
    if([type isEqualToString:@"voiceoverMix"])
    {
        NSLog(@"exporting...");
        
        //Delete plain audio file
        success = [fileManager removeItemAtPath:[voiceoverFileName path] error:&error];
        if (!success)
        {
            NSLog(@"Could not delete recorded file -: %@ ",[error localizedDescription]);
        }
    }
    
    
    //UI setup when saving finished
    [camera viewSetup];
    
    //Segue Back to chats view
    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [camera.view.window.layer addAnimation:transition forKey:nil];
    [camera dismissViewControllerAnimated:NO completion:nil];
    
    [voiceoverSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    audioAsset = nil;
    videoAsset = nil;
    
    //Set timer
    timerCount = 0;
}



#pragma mark - View

-(void)uiControl:(NSString *)type
{
    if([type isEqualToString:@"viewSetup"])
    {
        //UI setup before voiceover record
        camera.flashlightButton.hidden = YES;
        camera.frontBackButton.hidden = YES;
        camera.videosButton.hidden = YES;
        camera.overlayTypeButton.hidden = YES;
        camera.voiceoverExitView.hidden = NO;
        camera.toolsButton.hidden = NO;
        
        voiceoverPaused = NO;
    
        //UI hub
        [self hub:@"audio"];
    }
    else if([type isEqualToString:@"record"])
    {
        camera.pauseButton.hidden = NO; //Stop button
        [camera.pauseButton setImage:nil forState:UIControlStateNormal];
        [camera.pauseButton setBackgroundColor:[UIColor redColor]];
        camera.recordPauseButton.layer.cornerRadius = 0;
        [camera.recordPauseButton setBackgroundColor:[UIColor clearColor]];
        [camera.recordPauseButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        [camera.recordPauseButton setTintColor:[UIColor whiteColor]];
        camera.voiceoverExitView.hidden = YES;
        camera.audioVisual.hidden = NO;
    }
    else if([type isEqualToString:@"pause"])
    {
        camera.pauseButton.hidden = YES;
        camera.recordPauseButton.layer.cornerRadius = camera.recordPauseButton.bounds.size.width/2;
        [camera.recordPauseButton setBackgroundColor:[UIColor redColor]];
        [camera.recordPauseButton setImage:nil forState:UIControlStateNormal];
        camera.voiceoverExitView.hidden = NO;
        camera.audioVisual.hidden = YES;
        voiceoverPaused = YES;
    }
    else if([type isEqualToString:@"stop"] || [type isEqualToString:@"merge"])
    {
        [camera.indicator startAnimating];
        camera.indicatorView.hidden = NO;
        camera.recordPauseButton.hidden = YES;
        camera.pauseButton.hidden = YES;
        camera.toolsButton.hidden = YES;
        camera.toolsBoxView.hidden = YES;
        camera.audioVisual.hidden = YES;
        camera.hub1.hidden = YES;
    }
}


-(void)hub:(NSString *)type
{
    if([type isEqualToString:@"audio"])
    {
        if(voiceoverVideoPlayer.muted)
        {
            camera.hub1.hidden = NO;
            [camera.hub1 setImage:[UIImage imageNamed:@"mute_hub"]];
        }
        else
        {
            camera.hub1.hidden = YES;
        }
    }
}


-(void)tools
{
    //Setup activate tools for music video
    camera.toolsButton.hidden = NO;
    camera.tool1.hidden = NO;
    camera.tool2.hidden = YES;
    camera.tool3.hidden = YES;
    
    //Change mute button if audio is muted
    if(voiceoverVideoPlayer.muted)
    {
        [camera.tool1 setImage:[UIImage imageNamed:@"unmute"] forState:UIControlStateNormal]; //temp
    }
    else
    {
        [camera.tool1 setImage:[UIImage imageNamed:@"mute"] forState:UIControlStateNormal]; //temp
    }
}


-(void)viewExit
{
    //Exit voiceover overlay view
    //Delete plain audio file
    if(audioAsset != nil)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        BOOL success;
        success = [fileManager removeItemAtPath:[voiceoverFileName path] error:&error];
        if (!success)
        {
            NSLog(@"Could not delete recorded file -: %@ ",[error localizedDescription]);
        }
    }
    
    
    //Set view to default
    [camera viewSetup];
    
    //Remove player layer
    [layer removeFromSuperlayer];
    [voiceoverSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    videoAsset = nil;
    audioAsset = nil;
    camera.overlayType = nil;
}


#pragma mark - Timer


//Timer Method
-(void)timer
{
    timerCount++; //Get previous duration for chop
    
    //Set timer to countdown the video
    Float64 countdown = CMTimeGetSeconds(videoAsset.duration) - timerCount;
    
    NSString *sec = [NSString stringWithFormat:@"%i", (int)(countdown)%60];
    NSString *min = [NSString stringWithFormat:@"%i", (int)(countdown)/60];
    
    if([sec intValue] < 10)
    {
        sec = [NSString stringWithFormat:@"0%@", sec];
    }
    if([min intValue] < 10)
    {
        min = [NSString stringWithFormat:@"0%@", min];
    }
    
    if(countdown <= 0)
    {
        //If video finishes stop the recording... merge export
        [self stop];
    }

    camera.timeLabel.text = [NSString stringWithFormat:@"%@:%@", min, sec];

}

@end
