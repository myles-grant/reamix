//
//  Web.m
//  Reamix
//
//  Created by myles grant on 2015-01-06.
//  Copyright (c) 2015 Pinecone . All rights reserved.
//

#import "Web.h"

@implementation Web
{
    NSURL *webVoiceoverFileName;
    NSURL *filepath;
    NSString *extensionType;
    NSArray *responseExt;
    
    AVAsset *videoAsset;
    AVAsset *musicAsset;
    AVAsset *audioAsset;
    
    NSTimer *clockTimer;
    NSTimer *levelTimer;
    
    NSMutableArray *musicPausePoints;
    NSMutableArray *musicPlayPoints;
    NSMutableArray *audioPausePoints;
    NSMutableArray *audioPlayPoints;

    float audioVolume;
    
    AVAudioSession *webVoiceoverSession;
    AVPlayer *webVideoPlayer;
    AVPlayerLayer *layer;
    BOOL webVideoPaused;
    
    BOOL autoPause; BOOL autoPauseAccepted; BOOL pausedTrack;
    BOOL trackSegmented;
    BOOL trackDelay;
    BOOL playerDelay;
    
    NSString *path;
    
    //
    Float64 upperValue;
    Float64 lowerValue;
    
    //
    int timerCountdown;
    int musicTimeLine;
    
    Float64 videoTimeLine;
    Float64 pausePlayPoints;
    
    //
    int trackSegmentPreviewLower;
    int trackSegmentPreviewUpper;
    
    //
    int musicPausePlayCount;
}
@synthesize camera;


#pragma mark - Validation

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Start indicator
    [camera.indicator startAnimating];
    [camera.indicatorLabel setText:@"Searching..."];
    camera.indicatorView.hidden = NO;
    camera->urlInput.enabled = NO;

    
    //Hide exit button
    camera->exitURLInput.hidden = YES;
    
    [camera->urlInput resignFirstResponder];
    
    //Check if URL input leads to video source
    //Get response
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:camera->urlInput.text]];
    request.timeoutInterval = 30;
    
    //Send request
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if ([data length] > 0 && error == nil)
         {
             //Get main thread
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 //Check if url gave a response
                 if(response != nil)
                 {
                     responseExt = [response.MIMEType componentsSeparatedByString:@"/"];
                     
                     //Check if response is a video
                     if([[responseExt objectAtIndex:0] isEqualToString:@"video"])
                     {
                         //Check if the video file is supported
                         if([[responseExt objectAtIndex:1] isEqualToString:@"mp4"] || [[responseExt objectAtIndex:1] isEqualToString:@"mov"] || [[responseExt objectAtIndex:1] isEqualToString:@"m4v"] || [[responseExt objectAtIndex:1] isEqualToString:@"3pg"])
                         {
                             //Set ext type
                             extensionType = [NSString stringWithFormat:@".%@", [responseExt objectAtIndex:1]];
                             
                             //Stop indicator
                             camera.indicatorView.hidden = YES;
                             [camera.indicator stopAnimating];
                             [camera.indicatorLabel setText:@"Saving Reamix"];
                             
                             
                             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:/*@"Preview Video", */@"Reamix!", nil];
                             [alert show];
                         }
                         else
                         {
                             //Stop indicator
                             camera.indicatorView.hidden = YES;
                             [camera.indicator stopAnimating];
                             [camera.indicatorLabel setText:@"Saving Reamix"];
                             camera->urlInput.enabled = YES;
                             
                             //Hide exit button
                             camera->exitURLInput.hidden = NO;
                             
                             [camera->urlInput becomeFirstResponder];
                             
                             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The file recieved was not a supported video file" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                             [alert show];
                         }
                     }
                     else
                     {
                         //Stop indicator
                         camera.indicatorView.hidden = YES;
                         [camera.indicator stopAnimating];
                         [camera.indicatorLabel setText:@"Saving Reamix"];
                         camera->urlInput.enabled = YES;
                         
                         //Hide exit button
                         camera->exitURLInput.hidden = NO;
                         
                         [camera->urlInput becomeFirstResponder];
                         
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The file recieved was not a video file" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                         [alert show];
                     }
                 }
                 else
                 {
                     //Stop indicator
                     camera.indicatorView.hidden = YES;
                     [camera.indicator stopAnimating];
                     [camera.indicatorLabel setText:@"Saving Reamix"];
                     camera->urlInput.enabled = YES;
                     
                     //Hide exit button
                     camera->exitURLInput.hidden = NO;
                     
                     [camera->urlInput becomeFirstResponder];
                     
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Reamix was unable to locate your video. Make sure to include the full URL address to the video file including ( http:// )" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                     [alert show];
                 }
             });
         }
         else if ([data length] == 0 && error == nil)
         {
             //Get main thread
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 //Stop indicator
                 camera.indicatorView.hidden = YES;
                 [camera.indicator stopAnimating];
                 [camera.indicatorLabel setText:@"Saving Reamix"];
                 camera->urlInput.enabled = YES;
                 
                 //Hide exit button
                 camera->exitURLInput.hidden = NO;
                 
                 [camera->urlInput becomeFirstResponder];
                 
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to access file" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                 [alert show];
             });
         }
         else if (error != nil)
         {
             //Get main thread
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 //Stop indicator
                 camera.indicatorView.hidden = YES;
                 [camera.indicator stopAnimating];
                 [camera.indicatorLabel setText:@"Saving Reamix"];
                 camera->urlInput.enabled = YES;
                 
                 //Hide exit button
                 camera->exitURLInput.hidden = NO;
                 
                 [camera->urlInput becomeFirstResponder];
                 
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Reamix was unable to locate your video. Make sure to include the full URL address to the video file including ( http:// )" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                 [alert show];
             });
         }
     }];
    
    return  YES;
}


-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //Cancel
    if(buttonIndex == 0)
    {
        //Stop indicator
        camera.indicatorView.hidden = YES;
        [camera.indicator stopAnimating];
        [camera.indicatorLabel setText:@"Saving Reamix"];
        camera->urlInput.enabled = YES;
        
        //Hide exit button
        camera->exitURLInput.hidden = NO;
        
        [camera->urlInput becomeFirstResponder];
    }
    /*
    //Preview the video
    else if(buttonIndex == 1)
    {
        //Setup video preview view
        
    }
     */
    //Reamix the video
    else if(buttonIndex == 1)
    {
        //
        camera.overlayType = @"web";
        
        //Setup video preview view
        [camera webURLExit];
        [camera selectWeb:camera];
    }
}



#pragma mark - Music Selection

-(void)musicSelected:(UIViewController *)view
{
    //
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    mediaPicker.delegate = (id<MPMediaPickerControllerDelegate>)self;
    mediaPicker.prompt = @"Select a Track";
    [view presentViewController:mediaPicker animated:YES completion:nil];
}


-(void) mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    
    NSArray *selectedSong = [mediaItemCollection items];
    
    if ([selectedSong count] > 0)
    {
        //Load audio asset
        MPMediaItem *songItem = [selectedSong objectAtIndex:0];
        NSURL *songURL = [songItem valueForProperty:MPMediaItemPropertyAssetURL];
        
        //Set player
        NSError *error = nil;
        camera.musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:songURL error:&error];
        [camera.musicPlayer prepareToPlay];
        
        //
        camera->trackSelected = YES;
        
        //Load assets
        musicAsset = [AVAsset assetWithURL:songURL];
        
        if(musicAsset != nil)
        {
            //Let user know track has been selected
            NSLog(@"Music Asset Loaded");
            
            //Setup tools
            [self tools];
            
        }
        else
        {
            //Handle Error
        }
        
        //Load video
        videoAsset = [AVAsset assetWithURL:[NSURL URLWithString:camera->urlInput.text]];
        
        if(videoAsset != nil)
        {
            NSLog(@"Video Asset loaded");
            
            //Setup existing video view
            [self uiControl:@"viewSetup"];
        }
        else
        {
            //Handle Error
        }
    }
    
    //UI
    camera.overlayTypeView.hidden = YES;
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}


-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    //UI
    camera.overlayTypeView.hidden = YES;
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Web Voiceover Setup


-(void)webVoiceoverSetup
{
        //Load assets
        videoAsset = [AVAsset assetWithURL:[NSURL URLWithString:camera->urlInput.text]];
        audioAsset = nil;
        
        //Setup View for voiceover
        webVideoPlayer = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:videoAsset]];
        
        layer = [AVPlayerLayer playerLayerWithPlayer:webVideoPlayer];
        [layer setFrame: camera.view.frame];
        [camera.view.layer insertSublayer:layer atIndex:1];
        [layer setBackgroundColor:[[UIColor blackColor] CGColor]];
        
        [webVideoPlayer setMuted:YES]; //Default
        
        //Setup tools
        [self tools];
        
        if(videoAsset != nil)
        {
            //Let user know video has been selected
            NSLog(@"Video Asset Loaded");
            
            //Setup voiceover view
            [self uiControl:@"viewSetup"];
        }
        else
        {
            //Handle Error
        }
}


#pragma mark - Audio Control

-(void)audioVolumeControl
{
    //Turn off or on audio
    if(webVideoPlayer.muted)
    {
        //Turn on audio
        [webVideoPlayer setMuted:NO];
        
        //UI hub
        [self hub:@"audio"];
        [self tools];
    }
    else
    {
        //Turn off audio
        [webVideoPlayer setMuted:YES];
        
        //UI hub
        [self hub:@"audio"];
        [self tools];
    }
}


#pragma mark - Music Segment Selection

-(void)setTrackSegment
{
    //set maximum value with music length
    [camera trackSegmentSetup];
    
    [camera->rangeSlider setMaximumValue:CMTimeGetSeconds(musicAsset.duration)];
    [camera->rangeSlider setUpperValue:camera->rangeSlider.maximumValue];
    
    //Set Label for track length
    NSString *minUpper = [NSString stringWithFormat:@"%i", (int)camera->rangeSlider.upperValue/60];
    NSString *secUpper = [NSString stringWithFormat:@"%i", (int)camera->rangeSlider.upperValue%60];
    
    if(([secUpper intValue]) < 10)
    {
        secUpper = [NSString stringWithFormat:@"0%@", secUpper];
    }
    
    if(([minUpper intValue]) < 10)
    {
        minUpper = [NSString stringWithFormat:@"0%@", minUpper];
    }
    
    [camera->trackEnd setText:[NSString stringWithFormat:@"%@:%@", minUpper, secUpper]];
}



- (void)slideValueChanged:(id)control
{
    //Show pause at if upper value changes
    if(camera->rangeSlider.upperValue < camera->rangeSlider.maximumValue)
    {
        camera->autoPause.hidden = NO;
        
        //UI push preview play
        camera->previewPlay.frame = CGRectMake((camera.optionView.frame.size.width/2)-10, (camera.optionView.frame.size.height/2)+30, 100, 40);
    }
    else
    {
        camera->autoPause.hidden = YES;
        
        //UI pull preview play
        camera->previewPlay.frame = CGRectMake((camera.optionView.frame.size.width/2)-50, (camera.optionView.frame.size.height/2)+30, 100, 40);
    }
    
    if(camera->rangeSlider.upperValue == camera->rangeSlider.maximumValue)
    {
        //Hub
        camera.hub2.hidden = YES;
    }
    
    //Set segment label text
    int lower = (int)camera->rangeSlider.lowerValue;
    int upper = (int)camera->rangeSlider.upperValue;
    
    if(lower == upper)
    {
        lower = lower-1;
        
        if(lower < 0)
        {
            lower = 0;
            upper = upper+1;
        }
    }
    
    //Get preview length
    upperValue = upper;
    lowerValue = lower;
    
    NSString *minLower = [NSString stringWithFormat:@"%i", lower/60];
    NSString *secLower = [NSString stringWithFormat:@"%i", lower%60];
    NSString *minUpper = [NSString stringWithFormat:@"%i", upper/60];
    NSString *secUpper = [NSString stringWithFormat:@"%i", upper%60];
    
    if(([secLower intValue]) < 10)
    {
        secLower = [NSString stringWithFormat:@"0%@", secLower];
    }
    
    if(([minLower intValue]) < 10)
    {
        minLower = [NSString stringWithFormat:@"0%@", minLower];
    }
    
    if(([secUpper intValue]) < 10)
    {
        secUpper = [NSString stringWithFormat:@"0%@", secUpper];
    }
    
    if(([minUpper intValue]) < 10)
    {
        minUpper = [NSString stringWithFormat:@"0%@", minUpper];
    }
    
    [camera->trackStart setText:[NSString stringWithFormat:@"%@:%@", minLower, secLower]];
    [camera->trackEnd setText:[NSString stringWithFormat:@"%@:%@", minUpper, secUpper]];
}


-(void)previewTrackSegment
{
    //Play track segment
    if(![camera.musicPlayer isPlaying])
    {
        [camera.musicPlayer setCurrentTime:camera->rangeSlider.lowerValue];
        [camera.musicPlayer play];
        
         //Change play button to stop button
        [camera->previewPlay setImage:[UIImage imageNamed:@"preview_stop"] forState:UIControlStateNormal];
        
        //Start timer to end preview
        [clockTimer invalidate];
        
        //Set start and end point
        trackSegmentPreviewLower = (int)camera->rangeSlider.lowerValue;
        trackSegmentPreviewUpper = (int)camera->rangeSlider.upperValue;
        
        if(trackSegmentPreviewLower == trackSegmentPreviewUpper)
        {
            trackSegmentPreviewLower = trackSegmentPreviewLower-1;
            
            if(trackSegmentPreviewLower < 0)
            {
                trackSegmentPreviewLower = 0;
                trackSegmentPreviewUpper = trackSegmentPreviewUpper+1;
            }
        }
        
        clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(trackSegmentPreviewLength) userInfo:self repeats:YES];
    }
    else
    {
        //Stop timer
        [clockTimer invalidate];
        [camera->previewPlay setImage:[UIImage imageNamed:@"preview_play"] forState:UIControlStateNormal];
        [camera.musicPlayer setCurrentTime:0.0];
        [camera.musicPlayer stop];
    }
}

-(void)createNewAudioAssetFromTrackSegment
{
    //User segmented the track
    if((int)camera->rangeSlider.lowerValue <= 0 && (int)camera->rangeSlider.upperValue >= (int)camera->rangeSlider.maximumValue)
    {
        trackSegmented = NO;
    }
    else
    {
        trackSegmented = YES;
    }
    
    if([camera.musicPlayer isPlaying])
    {
        [camera.musicPlayer stop];
    }
    
    //Set view for accepted
    [camera tool2:camera];
}


-(void)autoPause
{
    //Set Pause
    if(autoPause)
    {
        autoPause = NO;
        
        //Set hub
        [self hub:@"prePause"];
    }
    else
    {
        autoPause = YES;
        
        //Set hub
        [self hub:@"prePause"];
    }
}

-(void)autoPauseAccepted
{
    autoPauseAccepted = autoPause;
}



#pragma mark - Option View

-(void)optionViewExit:(NSString *)type
{
    //Exit auto pause
    if([type isEqualToString:@"autoPauseExit"])
    {
        if(autoPause)
        {
            autoPause = NO;
            
            //Turn off hub2
            camera.hub2.hidden = YES;
        }
    }
}


#pragma mark - Music Volume .. Delay On Start Selection


-(void)musicVolume:(NSString *)type trackDelay:(BOOL)delay
{
    if([type isEqualToString:@"trackDelay"])
    {
        //set player delay
        playerDelay = delay;
        
        if([camera.overlayType isEqualToString:@"web musicVideo"])
        {
            if(!webVideoPaused)
            {
                if(!isRecording)
                {
                    //user has set track delay
                    trackDelay = delay;
                }
            }
        }
        
        NSLog(@"track Delay %i ... player Delay %i", trackDelay, playerDelay);
    }
    
    //Play or pause audio
    if(isRecording)
    {
        if([camera.musicPlayer isPlaying])
        {
            //Turn on audio
            [webVideoPlayer setMuted:NO]; //Existing
            
            [camera.musicPlayer pause];
            [musicPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
            [audioPlayPoints addObject:[NSString stringWithFormat:@"%f", videoTimeLine]];
            
            NSLog(@"music Pause Point added - %f", pausePlayPoints);
            NSLog(@"audio Play Point added - %f", videoTimeLine);
        }
        else
        {
            //Turn off audio
            [webVideoPlayer setMuted:YES]; //Music Video
            
            [camera.musicPlayer play];
            [musicPlayPoints addObject:[NSString stringWithFormat:@"%f", videoTimeLine]];
            [audioPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
            
            NSLog(@"music Play Point added - %f", videoTimeLine);
            NSLog(@"audio Pause Point added - %f", pausePlayPoints);
        }
        
        musicPausePlayCount++;
        pausePlayPoints = 0;
    }
    
    
    //UI Change
    [camera.hub1 setImage:[UIImage imageNamed:@"track_delay_hub"]];
    if(isRecording && delay == YES)
    {
        [camera.tool1 setImage:[UIImage imageNamed:@"track_play"] forState:UIControlStateNormal];
        [camera.hub1 setImage:[UIImage imageNamed:@"track_pause_hub"]];
    }
    else if(isRecording && delay == NO)
    {
        [camera.tool1 setImage:[UIImage imageNamed:@"track_pause"] forState:UIControlStateNormal];
    }
}




#pragma mark -

-(void)audioIndicatorPlay
{
    //Play beep audio indicator before recording
    //audio indicator
    if(webVideoPaused)
    {
        [camera audioPlayerDidFinishPlaying:camera.musicPlayer successfully:YES];
        webVideoPaused = NO;
    }
    else
    {
        [camera recordingIndicator:YES];
    }
    
}




#pragma mark - Recording

-(void)record
{
    NSLog(@"record");
    
    if([camera.overlayType isEqualToString:@"web musicVideo"])
    {
        
        //Start Timer
        [camera->recordFlashTimer invalidate];
        [clockTimer invalidate];
        
        //
        camera->recordFlashTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:camera selector:@selector(flash) userInfo:self repeats:YES];
        clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(clockTimer) userInfo:self repeats:YES];
        
        
        //Stop and play
        [camera.musicPlayer stop];
        
        if(!webVideoPaused)
        {
            //
            musicPausePoints = [[NSMutableArray alloc] init];
            musicPlayPoints = [[NSMutableArray alloc] init];
            audioPausePoints = [[NSMutableArray alloc] init];
            audioPlayPoints = [[NSMutableArray alloc] init];
            
            //Play from selected track time if user selected to segment track
            (trackSegmented) ? [camera.musicPlayer setCurrentTime:camera->rangeSlider.lowerValue] : [camera.musicPlayer setCurrentTime:0.0];
            
            if(!trackDelay)
            {
                [musicPlayPoints addObject:[NSString stringWithFormat:@"%f", -1.0]];
                pausePlayPoints = 0;
            }
            else
            {
                [audioPlayPoints addObject:[NSString stringWithFormat:@"%f", -1.0]];
                pausePlayPoints = 0;
            }
        }
        else
        {
            if(playerDelay)
            {
                [audioPlayPoints addObject:[NSString stringWithFormat:@"%f", videoTimeLine]];
                pausePlayPoints = 0;
                NSLog(@"audio Play Point added - %f", videoTimeLine);
            }
            else
            {
                [musicPlayPoints addObject:[NSString stringWithFormat:@"%f", videoTimeLine]];
                pausePlayPoints = 0;
                NSLog(@"music Play Point added - %f", videoTimeLine);
            }
        }
        
        //Dont play music if track is on delay
        if(!trackDelay || !playerDelay)
        {
            //Track is not on delay... play
            [camera.musicPlayer play];
            
            //Turn off audio
            [webVideoPlayer setMuted:YES];
            
            if(!webVideoPaused)
            {
                musicTimeLine = 0;
            }
        }
        
        
        //Start existing video music video recording
        [webVideoPlayer play];
        isRecording = YES;
        
        //UI setup
        [self uiControl:@"record"];
    }
    else if([camera.overlayType isEqualToString:@"web voiceover"])
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
            
            webVoiceoverFileName = [camera->connect setNewFile:@"voiceover" fileFormat:@".m4a"];
            
            // Initiate and prepare the recorder
            camera.recorder = [[AVAudioRecorder alloc] initWithURL:webVoiceoverFileName settings:recordSetting error:nil];
            camera.recorder.delegate = (id<AVAudioRecorderDelegate>)self;
            camera.recorder.meteringEnabled = YES;
            [camera.recorder prepareToRecord];
            
            webVoiceoverSession = [AVAudioSession sharedInstance];
            [webVoiceoverSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            [webVoiceoverSession setActive:YES error:nil];
            
            //Load audio asset
            audioAsset = [AVAsset assetWithURL:webVoiceoverFileName];
            NSLog(@"audio asset loaded");
        }
        
        // Start voiceover recording
        [camera.recorder record];
        
        //Start video
        [webVideoPlayer play];
        
        //Start Timer
        [levelTimer invalidate];
        [clockTimer invalidate];
        
        //
        levelTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:camera selector:@selector(levelTimerCallback:) userInfo: nil repeats: YES];
        clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timer) userInfo:self repeats:YES];
        
        //UI Setup while recording voiceover
        [self uiControl:@"record"];
    }
}


-(void)stop
{
    /******  STOP RECORDING ******/
    NSLog(@"stop");
    
    if([camera.overlayType isEqualToString:@"web musicVideo"])
    {
        //Stop players
        [camera.musicPlayer stop];
        [webVideoPlayer pause];
        isRecording = NO;
        
        //Unselect track
        camera->trackSelected = NO;
        
        //Stop timer
        [camera->recordFlashTimer invalidate];
        [clockTimer invalidate];
        
        //audio indicator
        [camera recordingIndicator:NO];
        
        //Send to merge and export
        [self captureOutput:nil didFinishRecordingToOutputFileAtURL:nil fromConnections:nil error:nil];
    }
    else if([camera.overlayType isEqualToString:@"web voiceover"])
    {
        NSLog(@"stop");
        
        //Pause audio recorder
        [camera.recorder stop];
        [webVideoPlayer pause];
        
        //Stop timer
        [levelTimer invalidate];
        [clockTimer invalidate];
        
        //audio indicator
        [camera recordingIndicator:NO];
        
        //Send to merge and export
        [self captureOutput:nil didFinishRecordingToOutputFileAtURL:nil fromConnections:nil error:nil];
    }
}


-(void)pause
{
    /******  PAUSE RECORDING ******/
    NSLog(@"pause");
    
    if([camera.overlayType isEqualToString:@"web musicVideo"])
    {
        //Pause players
        [camera->recordFlashTimer invalidate];
        [clockTimer invalidate];
        
        //Set Pause points
        if([camera.musicPlayer isPlaying])
        {
            //Music was last playing set pause point for music
            [musicPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
            NSLog(@"music Pause Point added - %f", pausePlayPoints);
            musicPausePlayCount++;
            pausePlayPoints = 0;
        }
        else
        {
            //Audio was last playing set audio pause point
            [audioPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
            NSLog(@"audio Pause Point added - %f", pausePlayPoints);
            musicPausePlayCount++;
            pausePlayPoints = 0;
        }
        
        [camera.musicPlayer pause];
        [webVideoPlayer pause];
        
        //Turn on audio
        [webVideoPlayer setMuted:NO];
        isRecording = NO;
        webVideoPaused = YES;
        
        //UI setup on paused recording
        [self uiControl:@"pause"];
    }
    else if([camera.overlayType isEqualToString:@"web voiceover"])
    {
        NSLog(@"pause");
        
        //Pause recording and timer
        [levelTimer invalidate];
        [clockTimer invalidate];
        
        
        [camera.recorder pause];
        [webVideoPlayer pause];
        
        //UI setup on paused recording
        [self uiControl:@"pause"];
    }
}





#pragma mark - Merging


-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if([camera.overlayType isEqualToString:@"web musicVideo"])
    {
        //UI setup while merging video
        [self uiControl:@"merge"];
        
        if(musicAsset != nil && videoAsset != nil)
        {
            NSLog(@"merging...");
            //Merge assets
            AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
            
            //Set video track
            AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(videoTimeLine, NSEC_PER_SEC)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            
            
            //Set music track
            AVMutableCompositionTrack *musicTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            //Set audio track
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            
            
            //Last music pause point
            if([musicPlayPoints count] > [musicPausePoints count])
            {
                [musicPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
            }
            
            //Last audio pause point
            if([audioPlayPoints count] > [audioPausePoints count])
            {
                [audioPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
            }
            
            //music CMTimes
            Float64 trackLengthSum = 0.0;
            CMTime startTime;
            CMTime endTime;
            CMTime atTime;
            
            //audio CMTimes
            CMTime startTimeAudio;
            CMTime endTimeAudio;
            CMTime atTimeAudio;
            
            NSLog(@"%i - %i - %i", trackDelay, trackSegmented, musicPausePlayCount);
            NSLog(@"music play count - %lu", (unsigned long)[musicPlayPoints count]);
            NSLog(@"music pause count - %lu", (unsigned long)[musicPausePoints count]);
            NSLog(@"audio play count - %lu", (unsigned long)[audioPlayPoints count]);
            NSLog(@"audio pause count - %lu", (unsigned long)[audioPausePoints count]);
            
            //TTT
            //TT
            if(trackDelay && trackSegmented && musicPausePlayCount > 0)
            {
                //Music
                for(int i=0; i<[musicPlayPoints count]; i++)
                {
                    
                    if(i == 0)
                    {
                        //Music
                        startTime = CMTimeMakeWithSeconds(camera->rangeSlider.lowerValue, NSEC_PER_SEC);
                    }
                    else
                    {
                        //Sum of previous tracks lengths
                        trackLengthSum = trackLengthSum + [[musicPausePoints objectAtIndex:i-1] floatValue];
                        //Music
                        startTime = CMTimeMakeWithSeconds(camera->rangeSlider.lowerValue+trackLengthSum, NSEC_PER_SEC);
                    }
                    
                    //Music
                    endTime = CMTimeMakeWithSeconds([[musicPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    atTime = CMTimeMakeWithSeconds([[musicPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    
                    [musicTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Music
                }
                
                //Audio
                for(int i=0; i<[audioPlayPoints count]; i++)
                {
                    if(i == 0)
                    {
                        //Audio
                        startTimeAudio = kCMTimeZero;
                        atTimeAudio = kCMTimeZero;
                    }
                    else
                    {
                        //Audio
                        startTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                        atTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    }
                    
                    //Audio
                    endTimeAudio = CMTimeMakeWithSeconds([[audioPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    
                    [audioTrack insertTimeRange:CMTimeRangeMake(startTimeAudio, endTimeAudio) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTimeAudio error:nil]; //Audio
                }
            }
            //FFF
            //FF
            else if(!trackDelay && !trackSegmented && musicPausePlayCount == 0)
            {
                //Music
                [musicTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(videoTimeLine, NSEC_PER_SEC)) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            }
            //TFT
            //TF
            else if(trackDelay && trackSegmented && musicPausePlayCount == 0)
            {
                //There is no music in this option
                //Add audio
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(videoTimeLine, NSEC_PER_SEC)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            }
            //FTT
            //FT
            else if(!trackDelay && trackSegmented && musicPausePlayCount > 0)
            {
                //Music
                for(int i=0; i<[musicPlayPoints count]; i++)
                {
                    //Music
                    endTime = CMTimeMakeWithSeconds([[musicPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    
                    if(i == 0)
                    {
                        //Music
                        startTime = CMTimeMakeWithSeconds(camera->rangeSlider.lowerValue, NSEC_PER_SEC);
                        atTime = kCMTimeZero;
                    }
                    else
                    {
                        //Sum of previous tracks lengths
                        trackLengthSum = trackLengthSum + [[musicPausePoints objectAtIndex:i-1] floatValue];
                        //Music
                        startTime = CMTimeMakeWithSeconds(camera->rangeSlider.lowerValue+trackLengthSum, NSEC_PER_SEC);
                        atTime = CMTimeMakeWithSeconds([[musicPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    }
                    
                    [musicTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Music
                }
                
                //Audio
                for(int i=0; i<[audioPlayPoints count]; i++)
                {
                    //Audio
                    startTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    endTimeAudio = CMTimeMakeWithSeconds([[audioPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    atTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    
                    
                    [audioTrack insertTimeRange:CMTimeRangeMake(startTimeAudio, endTimeAudio) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTimeAudio error:nil]; //Audio
                }
                
            }
            //TTF
            //TT
            else if(trackDelay && !trackSegmented && musicPausePlayCount > 0)
            {
                //Music
                for(int i=0; i<[musicPlayPoints count]; i++)
                {
                    //Music
                    endTime = CMTimeMakeWithSeconds([[musicPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    atTime = CMTimeMakeWithSeconds([[musicPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    
                    if(i == 0)
                    {
                        //Music
                        startTime = kCMTimeZero;
                    }
                    else
                    {
                        //Sum of previous tracks lengths
                        trackLengthSum = trackLengthSum + [[musicPausePoints objectAtIndex:i-1] floatValue];
                        //Music
                        startTime = CMTimeMakeWithSeconds(trackLengthSum, NSEC_PER_SEC);
                    }
                    
                    [musicTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Music
                }
                
                //Audio
                for(int i=0; i<[audioPlayPoints count]; i++)
                {
                    //Audio
                    startTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    endTimeAudio = CMTimeMakeWithSeconds([[audioPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    atTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    
                    if(i == 0)
                    {
                        //Audio
                        startTimeAudio = kCMTimeZero;
                        atTimeAudio = kCMTimeZero;
                    }
                    
                    [audioTrack insertTimeRange:CMTimeRangeMake(startTimeAudio, endTimeAudio) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTimeAudio error:nil]; //Audio
                }
            }
            //FFT
            //FF
            else if(!trackDelay && trackSegmented && musicPausePlayCount == 0)
            {
                startTime = CMTimeMakeWithSeconds(camera->rangeSlider.lowerValue, NSEC_PER_SEC);
                atTime = kCMTimeZero;
                
                if((upperValue-lowerValue) < CMTimeGetSeconds(videoAsset.duration))
                {
                    endTime = CMTimeMakeWithSeconds((upperValue-lowerValue), NSEC_PER_SEC);
                }
                else
                {
                    endTime = CMTimeMakeWithSeconds(videoTimeLine, NSEC_PER_SEC);
                }
                
                [musicTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil];
            }
            //FTF
            //FT
            else if(!trackDelay && !trackSegmented && musicPausePlayCount > 0)
            {
                for(int i=0; i<[musicPlayPoints count]; i++)
                {
                    //Music
                    endTime = CMTimeMakeWithSeconds([[musicPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    atTime = CMTimeMakeWithSeconds([[musicPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    
                    if(i == 0)
                    {
                        //Music
                        startTime = kCMTimeZero;
                        atTime = kCMTimeZero;
                    }
                    else
                    {
                        //Sum of previous tracks lengths
                        trackLengthSum = trackLengthSum + [[musicPausePoints objectAtIndex:i-1] floatValue];
                        //Music
                        startTime = CMTimeMakeWithSeconds(trackLengthSum, NSEC_PER_SEC);
                    }
                    
                    [musicTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Music
                }
                
                //Audio
                for(int i=0; i<[audioPlayPoints count]; i++)
                {
                    //Audio
                    startTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    endTimeAudio = CMTimeMakeWithSeconds([[audioPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    atTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                    
                    [audioTrack insertTimeRange:CMTimeRangeMake(startTimeAudio, endTimeAudio) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTimeAudio error:nil]; //Audio
                }
            }
            //TFF
            else if(trackDelay && !trackSegmented && musicPausePlayCount == 0)
            {
                //There is no music for this option
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(videoTimeLine, NSEC_PER_SEC)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            }
            
    
            
            
            
            
            
            //Export
            NSURL *outputLink = [camera->connect setNewFile:@"mix" fileFormat:@".mov"];
            
            AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
            exporter.outputURL = outputLink;
            exporter.outputFileType = AVFileTypeQuickTimeMovie;
            exporter.shouldOptimizeForNetworkUse = YES;
            //exporter.videoComposition = MainCompositionInst;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self exportDidFinish:exporter sender:@"webMuiscVideoMix"];
                });
            }];
            
            
            NSString *sec = [NSString stringWithFormat:@"%i", (int)videoTimeLine%60];
            NSString *min = [NSString stringWithFormat:@"%i", (int)videoTimeLine/60];
            
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
    }
    else if([camera.overlayType isEqualToString:@"web voiceover"])
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
        
        
        
        
        
        //Export
        NSURL *outputLink = [camera->connect setNewFile:@"mix" fileFormat:@".mov"];
        
        AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL = outputLink;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        //exporter.videoComposition = MainCompositionInst;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self exportDidFinish:exporter sender:@"webVoiceoverMix"];
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
}



#pragma mark - Exporting


-(void)exportDidFinish:(AVAssetExportSession*)exportSession sender:(NSString *)type
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success;
    if([type isEqualToString:@"webVoiceoverMix"])
    {
        NSLog(@"exporting...");
        
        //Delete plain audio file
        success = [fileManager removeItemAtPath:[webVoiceoverFileName path] error:&error];
        if (!success)
        {
            NSLog(@"Could not delete recorded file -: %@ ",[error localizedDescription]);
        }
    }
    else if([type isEqualToString:@"webMuiscVideoMix"])
    {
        NSLog(@"exporting...");
    }
    
    
    //UI setup when saving finished
    [camera viewSetup];
    [webVoiceoverSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    musicAsset = nil;
    videoAsset = nil;
    audioAsset = nil;
    musicPausePoints = nil;
    musicPlayPoints = nil;
    audioPausePoints = nil;
    audioPlayPoints = nil;
    
    //Set values
    timerCountdown = 0;
    videoTimeLine = 0;
    musicTimeLine = 0;
    musicPausePlayCount = 0;
    pausePlayPoints = 0;
    
    [camera performSegueWithIdentifier:@"cameraViewToVideosView" sender:camera];
}




#pragma mark - View


-(void)uiControl:(NSString *)type
{
    if([camera.overlayType isEqualToString:@"web musicVideo"])
    {
        if([type isEqualToString:@"record"])
        {
            //Setup view for recording music video
            //UI setup while recording
            camera.recordPauseButton.layer.cornerRadius = 0;
            camera.pauseButton.hidden = NO;
            camera.toolsButton.hidden = NO;
            camera.videosButton.hidden = YES;
            camera.frontBackButton.hidden = YES;
            camera.overlayTypeButton.hidden = YES;
            camera.overlayTypeView.hidden = YES;
            camera.recIndicator.hidden = NO;
            camera.recIndicator2.hidden = NO;
            //camera.toolsBoxView.hidden = NO;
            camera.optionTitle.hidden = YES;
            camera.optionView.hidden = YES;
            camera.voiceoverExitView.hidden = YES;
            
            
            //Set tool1 to pause
            [camera.tool1 setImage:[UIImage imageNamed:@"track_pause"] forState:UIControlStateNormal];
            
            //hub
            [self hub:@"record"];
            
            //Tools while recording
            camera.tool1.hidden = NO;
            camera.tool2.hidden = YES;
        }
        else if([type isEqualToString:@"pause"])
        {
            camera.recordPauseButton.layer.cornerRadius = camera.recordPauseButton.bounds.size.width/2;
            camera.recIndicator.hidden = YES;
            camera.recIndicator2.hidden = YES;
            camera.pauseButton.hidden = YES;
            
            //Set tool1 to play
            [camera.tool1 setImage:[UIImage imageNamed:@"track_delay"] forState:UIControlStateNormal];
            
            //hub
            [self hub:@"pause"];
        }
        else if([type isEqualToString:@"viewSetup"])
        {
            //UI
            camera.flashlightButton.hidden = YES;
            camera.frontBackButton.hidden = YES;
            camera.videosButton.hidden = YES;
            camera.overlayTypeButton.hidden = YES;
            camera.voiceoverExitView.hidden = NO;
            camera.recordPauseButton.hidden = NO;
            camera.timeLabel.hidden = NO;
            camera.toolsButton.hidden = NO;
            
            //Setup video player
            AVPlayerItem *item =[AVPlayerItem playerItemWithAsset:videoAsset];
            webVideoPlayer = [AVPlayer playerWithPlayerItem:item];
            
            layer = [AVPlayerLayer playerLayerWithPlayer:webVideoPlayer];
            [layer setFrame:camera.view.frame];
            [camera.view.layer insertSublayer:layer atIndex:1];
            [layer setBackgroundColor:[[UIColor blackColor] CGColor]];
        }
        else if([type isEqualToString:@"merge"] || [type isEqualToString:@"stop"])
        {
            [camera.indicator startAnimating];
            camera.indicatorView.hidden = NO;
            camera.recordPauseButton.hidden = YES;
            camera.pauseButton.hidden = YES;
            camera.recIndicator.hidden = YES;
            camera.recIndicator2.hidden = YES;
            camera.toolsButton.hidden = YES;
            camera.toolsBoxView.hidden = YES;
            camera.hub1.hidden = YES;
            camera.hub2.hidden = YES;
        }
        
    }
    else if([camera.overlayType isEqualToString:@"web voiceover"])
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
            camera.overlayTypeView.hidden = YES;
            
            webVideoPaused = NO;
            
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
            webVideoPaused = YES;
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
}


-(void)hub:(NSString *)type
{
    if([camera.overlayType isEqualToString:@"web musicVideo"])
    {
        if([type isEqualToString:@"record"])
        {
            if(camera.hub1.hidden == NO)
            {
                //Set hub1 to music paused
                [camera.hub1 setImage:[UIImage imageNamed:@"track_pause_hub"]];
                
                //Set tool1 to play
                [camera.tool1 setImage:[UIImage imageNamed:@"track_play"] forState:UIControlStateNormal];
            }
            
            if(!autoPauseAccepted)
            {
                camera.hub2.hidden = YES;
            }
        }
        else if([type isEqualToString:@"pause"])
        {
            if(camera.hub1.hidden == NO)
            {
                //Set hub1 to music paused
                [camera.hub1 setImage:[UIImage imageNamed:@"track_delay_hub"]];
            }
        }
        else if([type isEqualToString:@"prePause"])
        {
            if(camera.hub2.hidden == YES)
            {
                camera.hub2.hidden = NO;
                //Set hub2 to music pre-pause
                [camera.hub2 setImage:[UIImage imageNamed:@"auto_pause_hub"]];
            }
            else
            {
                camera.hub2.hidden = YES;
            }
        }
    }
    else if([camera.overlayType isEqualToString:@"web voiceover"])
    {
        if([type isEqualToString:@"audio"])
        {
            if(webVideoPlayer.muted)
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
}



-(void)tools
{
    if([camera.overlayType isEqualToString:@"web musicVideo"])
    {
        //Setup activate tools for music video
        camera.toolsButton.hidden = NO;
        
        [self setTrackSegment];
    }
    else if([camera.overlayType isEqualToString:@"web voiceover"])
    {
        //Setup activate tools for music video
        camera.toolsButton.hidden = NO;
        camera.tool1.hidden = NO;
        camera.tool2.hidden = YES;
        camera.tool3.hidden = YES;
        
        //Change mute button if audio is muted
        if(webVideoPlayer.muted)
        {
            [camera.tool1 setImage:[UIImage imageNamed:@"unmute"] forState:UIControlStateNormal];
        }
        else
        {
            [camera.tool1 setImage:[UIImage imageNamed:@"mute"] forState:UIControlStateNormal];
        }
    }
}


-(void)webVideoViewExit
{
    if([camera.overlayType isEqualToString:@"web voiceover"])
    {
        //Exit voiceover overlay view
        //Delete plain audio file
        if(audioAsset != nil)
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error;
            BOOL success;
            success = [fileManager removeItemAtPath:[webVoiceoverFileName path] error:&error];
            if (!success)
            {
                NSLog(@"Could not delete recorded file -: %@ ",[error localizedDescription]);
            }
        }

        [webVoiceoverSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
    //Return back to camera view
    [camera viewSetup];
    
    audioAsset = nil;
    musicAsset = nil;
    videoAsset = nil;
    camera.overlayType = nil;
    
    [layer removeFromSuperlayer];
}



#pragma mark - Timer




-(void)clockTimer
{
    //Stop player if track segmented
    if(isRecording)
    {
        if(trackSegmented && musicTimeLine >= (upperValue-lowerValue))
        {
            if(autoPauseAccepted)
            {
                //Pause
                [self pause];
                
                //Turn off auto pause
                [self optionViewExit:@"autoPauseExit"];
                
                autoPauseAccepted = NO;
                pausedTrack = YES;
            }
            
            if([camera.musicPlayer isPlaying] && !pausedTrack)
            {
                //Turn on audio
                [webVideoPlayer setMuted:NO];
                
                [camera.musicPlayer pause];
                
                //Add music pause point
                [musicPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
                [audioPlayPoints addObject:[NSString stringWithFormat:@"%f", videoTimeLine]];
                NSLog(@"music Pause Point added - %f", pausePlayPoints);
                NSLog(@"audio Play Point added - %f", videoTimeLine);
                musicPausePlayCount++;
                pausePlayPoints = 0;
                pausedTrack = YES;
                
                //Set hub
                [self hub:@"record"];
            }
        }
        
        if([camera.musicPlayer isPlaying])
        {
            musicTimeLine++;
        }
    }
    
    
    videoTimeLine++;
    pausePlayPoints++;
    timerCountdown++;
    
    if([camera.overlayType isEqualToString:@"web musicVideo"])
    {
        //Set timer to countdown the video
        Float64 timeCountdown = CMTimeGetSeconds(videoAsset.duration) - timerCountdown;
        
        NSString *sec = [NSString stringWithFormat:@"%i", (int)(timeCountdown)%60];
        NSString *min = [NSString stringWithFormat:@"%i", (int)(timeCountdown)/60];
        
        if([sec intValue] < 10)
        {
            sec = [NSString stringWithFormat:@"0%@", sec];
        }
        if([min intValue] < 10)
        {
            min = [NSString stringWithFormat:@"0%@", min];
        }
        
        if(timeCountdown <= 0)
        {
            //If video finishes stop the recording... merge export
            [self stop];
        }
        
        camera.timeLabel.text = [NSString stringWithFormat:@"%@:%@", min, sec];
    }
}


//Timer Method
-(void)timer
{
    timerCountdown++; //Get previous duration for chop
    
    //Set timer to countdown the video
    Float64 countdown = CMTimeGetSeconds(videoAsset.duration) - timerCountdown;
    
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


-(void)trackSegmentPreviewLength
{
    NSString *sec = [NSString stringWithFormat:@"%i", trackSegmentPreviewLower%60];
    NSString *min = [NSString stringWithFormat:@"%i", trackSegmentPreviewLower/60];
    
    if([sec intValue] < 10)
    {
        sec = [NSString stringWithFormat:@"0%@", sec];
    }
    if([min intValue] < 10)
    {
        min = [NSString stringWithFormat:@"0%@", min];
    }
    [camera->trackTime setText:[NSString stringWithFormat:@"%@:%@", min, sec]];
    
    //Get the amount of seconds to run before stopping track
    if(trackSegmentPreviewLower >= trackSegmentPreviewUpper)
    {
        //Stop timer
        [clockTimer invalidate];
        
        //Stop playing
        [camera.musicPlayer stop];
        [camera->previewPlay setTitle:@"preview" forState:UIControlStateNormal];
    }
    
    trackSegmentPreviewLower++;
}



@end
