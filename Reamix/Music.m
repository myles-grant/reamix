//
//  Music.m
//  Reamix
//
//  Created by myles grant on 2014-12-30.
//  Copyright (c) 2014 Pinecone . All rights reserved.
//

#import "Music.h"

@implementation Music
{
    NSTimer *clockTimer;
    NSTimer *levelTimer;
    
    //Multiple video merge
    BOOL multipleVideos;
    BOOL finishedVideo;
    
    NSMutableArray *musicPausePoints;
    NSMutableArray *musicPlayPoints;
    NSMutableArray *audioPausePoints;
    NSMutableArray *audioPlayPoints;
    
    AVAsset *videoAsset;
    AVAsset *musicAsset;
    AVAsset *audioAsset;
    float audioVolume;
    
    AVPlayer *existingVideoPlayer;
    AVPlayerLayer *layer;
    BOOL existingVideoPaused;
    
    BOOL autoPause; BOOL autoPauseAccepted; BOOL pausedTrack;
    BOOL trackSegmented;
    BOOL trackDelay;
    BOOL playerDelay;
    
    NSString *path;
    
    //
    int timerCountdown; //Existing Video
    int musicTimeLine;
    
    Float64 videoTimeLine;
    Float64 pausePlayPoints;
    
    //
    int trackSegmentPreviewLower;
    int trackSegmentPreviewUpper;
    
    //
    unsigned int countdown;
    
    //
    Float64 upperValue;
    Float64 lowerValue;
    
    //
    int musicPausePlayCount;
}
@synthesize camera;
@synthesize extraVideos, pathArray, videoPlayPoints;

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
        videoAsset = nil;
        
        if(musicAsset != nil)
        {
            //Let user know track has been selected
            NSLog(@"Music Asset Loaded");
            
            //Setup tools
            [self tools];
            
            //Get Existing Video
            if([camera.overlayType isEqualToString:@"music existing"])
            {
                if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)
                {
                    //Selected video to voiceover
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No Saved Album Found" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
                else
                {
                    //UI
                    camera.overlayTypeView.hidden = YES;
                    [camera nullViewSetup];
                    
                    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
                    [self startMediaBrowserFromViewController:camera usingDelegate:self];
                    
                    return;
                }
            }
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


#pragma mark - Existing Video Selection

-(BOOL)startMediaBrowserFromViewController:(UIViewController *)controller usingDelegate:(id)delegate
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
    if (CFStringCompare ((__bridge_retained CFStringRef) [info objectForKey:UIImagePickerControllerMediaType], kUTTypeMovie, 0) == kCFCompareEqualTo)
    {
        
        //Load assets
        videoAsset = [AVAsset assetWithURL:[info objectForKey:UIImagePickerControllerMediaURL]];
        
        if(videoAsset != nil)
        {
            //Let user know video has been selected
            NSLog(@"Video Asset Loaded");
            
            //Setup existing video view
            [self uiControl:@"viewSetup"];
        }
        else
        {
            //Handle Error
        }
    }
    
    [camera dismissViewControllerAnimated:YES completion:nil];
}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    //Return back to camera view
    [camera viewSetup];
    musicAsset = nil;
    videoAsset = nil;
    camera.overlayType = nil;
    
    [camera dismissViewControllerAnimated:YES completion:nil];
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
    //Exit pause at
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
        
        if([camera.overlayType isEqualToString:@"music recording"])
        {
            if(!multipleVideos)
            {
                if(![camera.videoOutput isRecording])
                {
                    //user has set track delay
                    trackDelay = delay;
                }
            }
        }
        else if([camera.overlayType isEqualToString:@"music existing"])
        {
            if(!existingVideoPaused)
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
    if([camera.videoOutput isRecording] || isRecording)
    {
        if([camera.musicPlayer isPlaying])
        {
            //Turn on audio
            [existingVideoPlayer setMuted:NO]; //Existing
            
            [camera.musicPlayer pause];
            [musicPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
            [audioPlayPoints addObject:[NSString stringWithFormat:@"%f", videoTimeLine]];
            
            NSLog(@"music Pause Point added - %f", pausePlayPoints);
            NSLog(@"audio Play Point added - %f", videoTimeLine);
        }
        else
        {
            //Turn off audio
            [existingVideoPlayer setMuted:YES]; //Existing
            
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
    if([camera.videoOutput isRecording] && delay == YES)
    {
        [camera.tool1 setImage:[UIImage imageNamed:@"track_play"] forState:UIControlStateNormal];
        [camera.hub1 setImage:[UIImage imageNamed:@"track_pause_hub"]];
    }
    else if([camera.videoOutput isRecording] && delay == NO)
    {
        [camera.tool1 setImage:[UIImage imageNamed:@"track_pause"] forState:UIControlStateNormal];
    }
    else if(isRecording && delay == YES)
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
    if([camera.overlayType isEqualToString:@"music recording"])
    {
        if(multipleVideos)
        {
            //Video is paused dont play beep audio indicator
            [camera audioPlayerDidFinishPlaying:camera.musicPlayer successfully:YES];
        }
        else
        {
            //Play beep audio indicator
            [camera recordingIndicator:YES];
        }
    }
    else if([camera.overlayType isEqualToString:@"music existing"])
    {
        //audio indicator
        if(existingVideoPaused)
        {
            [camera audioPlayerDidFinishPlaying:camera.musicPlayer successfully:YES];
            existingVideoPaused = NO;
        }
        else
        {
            [camera recordingIndicator:YES];
        }
    }
}




#pragma mark - Recording

-(void)record
{
    NSLog(@"record");
    
    if([camera.overlayType isEqualToString:@"music recording"])
    {
        //Start Timer
        [camera->recordFlashTimer invalidate]; //flashing "recording label"
        [clockTimer invalidate];
        
        //Timer
        camera->recordFlashTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:camera selector:@selector(flash) userInfo:self repeats:YES];
        clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(clockTimer) userInfo:self repeats:YES];
        
        
        //Play Selected music if any selected
        //Stop and play
        [camera.musicPlayer stop];

        
        if(!multipleVideos)
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
                NSLog(@"music Play Point added - %f", -1.0);
            }
            else
            {
                [audioPlayPoints addObject:[NSString stringWithFormat:@"%f", -1.0]];
                pausePlayPoints = 0;
                NSLog(@"audio Play Point added - %f", -1.0);
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
            
            if(!multipleVideos)
            {
                musicTimeLine = 0;
            }
        }

        
        [camera.videoOutput startRecordingToOutputFileURL:[camera->connect setNewFile:@"video" fileFormat:@".mov"] recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)self];
        
        //UI setup
        [self uiControl:@"record"];
    }
    else if([camera.overlayType isEqualToString:@"music existing"])
    {
        
        //Start Timer
        [camera->recordFlashTimer invalidate];
        [clockTimer invalidate];
        
        //
        camera->recordFlashTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:camera selector:@selector(flash) userInfo:self repeats:YES];
        clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(clockTimer) userInfo:self repeats:YES];
        
        
        //Stop and play
        [camera.musicPlayer stop];
        
        if(!existingVideoPaused)
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
            [existingVideoPlayer setMuted:YES];
            
            if(!existingVideoPaused)
            {
                musicTimeLine = 0;
            }
        }
        
        
        //Start existing video music video recording
        [existingVideoPlayer play];
        isRecording = YES;
        
        //UI setup
        [self uiControl:@"record"];
    }
}


-(void)stop
{
    /******  STOP RECORDING ******/
    NSLog(@"stop");
    
    if([camera.overlayType isEqualToString:@"music recording"])
    {
        //Set recording to finish
        if(multipleVideos == YES)
        {
            //There has to be mutiple videos in que... run finished recording method to merge and export
            finishedVideo = YES;
        }
        else
        {
            multipleVideos = NO;
        }
        
        //Stop timer
        [camera->recordFlashTimer invalidate];
        [clockTimer invalidate];
        
        //Stop recording
        [camera.videoOutput stopRecording];
        [camera.musicPlayer stop];
            
        //Unselect track
        camera->trackSelected = NO;
        
        //audio indicator
        [camera recordingIndicator:NO];
    }
    else if([camera.overlayType isEqualToString:@"music existing"])
    {
        //Stop players
        [camera.musicPlayer stop];
        [existingVideoPlayer pause];
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
}


-(void)pause
{
    /******  PAUSE RECORDING ******/
    NSLog(@"pause");
    
    if([camera.overlayType isEqualToString:@"music recording"])
    {
        multipleVideos = YES;
        
        //Stop timer
        [camera->recordFlashTimer invalidate];
        [clockTimer invalidate];
        countdown = 0;
        
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
        
        //Pause music...
        [camera.musicPlayer pause];
        [camera.videoOutput stopRecording];
        
        
        //UI setup on paused recording
        [self uiControl:@"pause"];
    }
    else if([camera.overlayType isEqualToString:@"music existing"])
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
        [existingVideoPlayer pause];
        
        //Turn on audio
        [existingVideoPlayer setMuted:NO];
        isRecording = NO;
        existingVideoPaused = YES;
        
        //UI setup on paused recording
        [self uiControl:@"pause"];
    }
}


-(void)recordHold
{
    if([camera.overlayType isEqualToString:@"music recording"])
    {
        //Dont play if button is stop button
        if(camera.recordPauseButton.layer.cornerRadius != 0)
        {
            //Start count down till recording
            countdown = 3;
            clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdownToRecord) userInfo:self repeats:YES];
        }
    }
    else if([camera.overlayType isEqualToString:@"music existing"])
    {
        
    }
}


#pragma mark - Merging


-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if([camera.overlayType isEqualToString:@"music recording"])
    {
        if(!multipleVideos)
        {
            //UI setup while merging video
            [self uiControl:@"merge"];
            
            NSURL *outputLink = outputFileURL;
            if(musicAsset != nil)
            {
                NSLog(@"merging...");
                
                //Load video assest
                videoAsset = [AVAsset assetWithURL:outputFileURL];
                path = outputFileURL.path;
                
                //Merge assets
                AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
                
                //Set video track
                AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds((int)CMTimeGetSeconds(videoAsset.duration), NSEC_PER_SEC)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                
                
                //Set music track
                AVMutableCompositionTrack *musicTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                
                //Set audio track
                AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                
                
                /*
                 //Edit volume levels
                 NSMutableArray *trackMixArray = [NSMutableArray array];
                 
                 //Audio level
                 AVMutableAudioMixInputParameters *audioVol = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
                 */
                
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
                
                //music CMtimes
                Float64 trackLengthSum = 0.0;
                CMTime startTime;
                CMTime endTime;
                CMTime atTime;
                
                //audio CMtimes
                CMTime startTimeAudio;
                CMTime endTimeAudio;
                CMTime atTimeAudio;
                
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
                        
                        //Audio
                        //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                        //[audioVol setVolume:0.5 atTime:atTime]; //Volume
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
                    [musicTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                    
                    //Audio
                    //[audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil]; //Audio
                    //[audioVol setVolume:0.5 atTime:kCMTimeZero]; //Volume
                }
                //TTF
                //TF
                else if(trackDelay && trackSegmented && musicPausePlayCount == 0)
                {
                    //There is no music in this option
                    //Add audio
                    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
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
                        
                        //Audio
                        //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                        //[audioVol setVolume:0.5 atTime:atTime]; //Volume
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
                //TFT
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
                        
                        //Audio
                        //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                        //[audioVol setVolume:0.5 atTime:atTime]; //Volume
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
                //FTF
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
                        endTime = videoAsset.duration;
                    }
                    
                    [musicTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil];
                    
                    //Audio
                    //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                    //[audioVol setVolume:0.5 atTime:atTime]; //Volume
                }
                //FFT
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
                        
                        //Audio
                        //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                        //[audioVol setVolume:0.5 atTime:atTime]; //Volume
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
                    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                }
                
                /*
                 [trackMixArray addObject:audioVol];
                 
                 AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
                 audioMix.inputParameters = trackMixArray;
                 */
                
                //Export
                outputLink = [camera->connect setNewFile:@"mix" fileFormat:@".mov"];
                
                AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
                exporter.outputURL = outputLink;
                exporter.outputFileType = AVFileTypeQuickTimeMovie;
                exporter.shouldOptimizeForNetworkUse = YES;
                //exporter.audioMix = audioMix;
                [exporter exportAsynchronouslyWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self exportDidFinish:exporter sender:@"mix"];
                    });
                }];
                
            }
            
            //Set time format
            NSString *min = [NSString stringWithFormat:@"%i", ((int)CMTimeGetSeconds(videoAsset.duration))/60];
            NSString *sec = [NSString stringWithFormat:@"%i", ((int)CMTimeGetSeconds(videoAsset.duration))%60];
            if([sec intValue] < 10)
            {
                sec = [NSString stringWithFormat:@"0%i", [sec intValue]];
            }
            if([min intValue] < 10)
            {
                min = [NSString stringWithFormat:@"0%i", [min intValue]];
            }
            
            //Log info to db
            [camera->connect addNewRowIn:@"Videos" setValue:[outputLink lastPathComponent] forKeyPath:@"videoUrl"];
            [camera->connect updateRowIn:@"Videos" setValue:[NSString stringWithFormat:@"%@:%@", min, sec] forKeyPath:@"duration" atIndex:([[camera->connect getContextArray:@"Videos"] count]-1)];
            
        }
        else if(multipleVideos)
        {
            //UI
            [self uiControl:@"pause"];
            
            //Load extra videos into array
            [extraVideos addObject:outputFileURL];
            [pathArray addObject:outputFileURL.path];
            [videoPlayPoints addObject:[NSString stringWithFormat:@"%f", videoTimeLine]];
            
            if(finishedVideo == YES)
            {
                NSLog(@"merging...");
                
                //UI setup when merging videos
                [self uiControl:@"merge"];
                
                //Merge assets
                AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
                
                AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                
                
                //Merge audio tracks into a single audio track
                AVMutableComposition *multipleAudioMixComposition = [[AVMutableComposition alloc] init];
                AVMutableCompositionTrack *multipleAudioTracks = [multipleAudioMixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                
                
                //Input the extra assets
                for(int i=0; i<[extraVideos count]; i++)
                {
                    
                    //Load video assest
                    videoAsset = [AVAsset assetWithURL:[extraVideos objectAtIndex:i]];
                    
                    //Set video track
                    if(i == 0)
                    {
                        //Video
                        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds((int)CMTimeGetSeconds(videoAsset.duration), NSEC_PER_SEC)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                        
                        //Audio
                        [multipleAudioTracks insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds((int)CMTimeGetSeconds(videoAsset.duration), NSEC_PER_SEC)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                    }
                    else
                    {
                        //Video
                        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds((int)CMTimeGetSeconds(videoAsset.duration), NSEC_PER_SEC)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:CMTimeMakeWithSeconds([[videoPlayPoints objectAtIndex:i-1] floatValue], NSEC_PER_SEC) error:nil];
                        
                        //Audio
                        [multipleAudioTracks insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds((int)CMTimeGetSeconds(videoAsset.duration), NSEC_PER_SEC)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:CMTimeMakeWithSeconds([[videoPlayPoints objectAtIndex:i-1] floatValue], NSEC_PER_SEC) error:nil];
                    }
                }
                
                
                
                //Merge multiple audio tracks
                NSURL *multipleAudioOutput = [camera->connect setNewFile:@"multipleAudio" fileFormat:@".m4a"];
                
                AVAssetExportSession *multipleAudioExporter = [AVAssetExportSession exportSessionWithAsset:multipleAudioMixComposition presetName:AVAssetExportPresetAppleM4A];
                multipleAudioExporter.outputURL = multipleAudioOutput;
                multipleAudioExporter.outputFileType = AVFileTypeAppleM4A;
                [multipleAudioExporter exportAsynchronouslyWithCompletionHandler:
                 ^{
                     dispatch_async(dispatch_get_main_queue(),
                                    ^{
                                        
                                        //Add path to path array to be deleted
                                        [pathArray addObject:multipleAudioOutput.path];
                                        
                                        //Set audio asset to single audio file
                                        audioAsset = [AVAsset assetWithURL:multipleAudioOutput];
                                        
                                        
                                        //Set music track
                                        AVMutableCompositionTrack *musicTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                                        
                                        //Set audio track
                                        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                                        
                                        
                                        /*
                                         //Edit volume levels
                                         NSMutableArray *trackMixArray = [NSMutableArray array];
                                         
                                         //Audio levels
                                         AVMutableAudioMixInputParameters *audioVol = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
                                         */
                                        
                                        //Last music pause point
                                        if([musicPlayPoints count] > [musicPausePoints count])
                                        {
                                            [musicPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
                                            
                                            NSLog(@"music Pause Point added - %f", pausePlayPoints);
                                        }
                                        
                                        //Last audio pause point
                                        if([audioPlayPoints count] > [audioPausePoints count])
                                        {
                                            [audioPausePoints addObject:[NSString stringWithFormat:@"%f", pausePlayPoints]];
                                            
                                            NSLog(@"audio Pause Point added - %f", pausePlayPoints);
                                        }
                                        
                                        NSLog(@"%i - %i - %i", trackDelay, trackSegmented, musicPausePlayCount);
                                        NSLog(@"music play count - %lu", (unsigned long)[musicPlayPoints count]);
                                        NSLog(@"music pause count - %lu", (unsigned long)[musicPausePoints count]);
                                        NSLog(@"audio play count - %lu", (unsigned long)[audioPlayPoints count]);
                                        NSLog(@"audio pause count - %lu", (unsigned long)[audioPausePoints count]);
                                        
                                        //music CMTimes
                                        Float64 trackLengthSum = 0.0;
                                        CMTime startTime;
                                        CMTime endTime;
                                        CMTime atTime;
                                        
                                        //audio CMTimes
                                        CMTime startTimeAudio;
                                        CMTime endTimeAudio;
                                        CMTime atTimeAudio;
                                        
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
                                                
                                                //Audio
                                                //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                                                //[audioVol setVolume:0.5 atTime:atTime]; //Volume
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
                                                
                                                [audioTrack insertTimeRange:CMTimeRangeMake(startTimeAudio, endTimeAudio) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTimeAudio error:nil]; //Audio
                                            }
                                        }
                                        //FFF
                                        //FF
                                        else if(!trackDelay && !trackSegmented && musicPausePlayCount == 0)
                                        {
                                            //Music
                                            [musicTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(pausePlayPoints, NSEC_PER_SEC)) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                                            
                                            //Audio
                                            //[audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(pausePlayPoints, NSEC_PER_SEC)) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil]; //Audio
                                            //[audioVol setVolume:0.5 atTime:kCMTimeZero]; //Volume
                                        }
                                        //TTF
                                        //TF
                                        else if(trackDelay && trackSegmented && musicPausePlayCount == 0)
                                        {
                                            //There is no music in this option
                                            //Add audio
                                            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(pausePlayPoints, NSEC_PER_SEC)) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
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
                                                
                                                //Audio
                                                //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                                                //[audioVol setVolume:0.5 atTime:atTime]; //Volume
                                            }
                                            
                                            //Audio
                                            for(int i=0; i<[audioPlayPoints count]; i++)
                                            {
                                                //Audio
                                                startTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                                                endTimeAudio = CMTimeMakeWithSeconds([[audioPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                                                atTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                                                
                                                [audioTrack insertTimeRange:CMTimeRangeMake(startTimeAudio, endTimeAudio) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTimeAudio error:nil]; //Audio
                                            }
                                        }
                                        //TFT
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
                                                
                                                //Audio
                                                //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                                                //[audioVol setVolume:0.5 atTime:atTime]; //Volume
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
                                                
                                                [audioTrack insertTimeRange:CMTimeRangeMake(startTimeAudio, endTimeAudio) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTimeAudio error:nil]; //Audio
                                            }
                                        }
                                        //FTF
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
                                                endTime = CMTimeMakeWithSeconds(pausePlayPoints, NSEC_PER_SEC);
                                            }
                                            
                                            [musicTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil];
                                            
                                            //Audio
                                            //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                                            //[audioVol setVolume:0.5 atTime:atTime]; //Volume
                                        }
                                        //FFT
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
                                                
                                                //Audio
                                                //[audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTime error:nil]; //Audio
                                                //[audioVol setVolume:0.5 atTime:atTime]; //Volume
                                            }
                                            
                                            //Audio
                                            for(int i=0; i<[audioPlayPoints count]; i++)
                                            {
                                                //Audio
                                                startTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                                                endTimeAudio = CMTimeMakeWithSeconds([[audioPausePoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                                                atTimeAudio = CMTimeMakeWithSeconds([[audioPlayPoints objectAtIndex:i] floatValue], NSEC_PER_SEC);
                                                
                                                [audioTrack insertTimeRange:CMTimeRangeMake(startTimeAudio, endTimeAudio) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:atTimeAudio error:nil]; //Audio
                                            }
                                        }
                                        //TFF
                                        else if(trackDelay && !trackSegmented && musicPausePlayCount == 0)
                                        {
                                            //There is no music for this option
                                            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(pausePlayPoints, NSEC_PER_SEC)) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                                        }
                                        
                                        
                                        
                                        
                                        //Export
                                        NSURL *outputLink = [camera->connect setNewFile:@"mix" fileFormat:@".mov"];
                                        
                                        AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
                                        exporter.outputURL = outputLink;
                                        exporter.outputFileType = AVFileTypeQuickTimeMovie;
                                        exporter.shouldOptimizeForNetworkUse = YES;
                                        [exporter exportAsynchronouslyWithCompletionHandler:^{
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self exportDidFinish:exporter sender:@"multipleVideoMix"];
                                            });
                                        }];
                                        
                                        
                                        //Set time format
                                        NSString *min = [NSString stringWithFormat:@"%i", ((int)videoTimeLine)/60];
                                        NSString *sec = [NSString stringWithFormat:@"%i", ((int)videoTimeLine)%60];
                                        if([sec intValue] < 10)
                                        {
                                            sec = [NSString stringWithFormat:@"0%i", [sec intValue]];
                                        }
                                        if([min intValue] < 10)
                                        {
                                            min = [NSString stringWithFormat:@"0%i", [min intValue]];
                                        }
                                        
                                        //Log info to db
                                        [camera->connect addNewRowIn:@"Videos" setValue:[outputLink lastPathComponent] forKeyPath:@"videoUrl"];
                                        [camera->connect updateRowIn:@"Videos" setValue:[NSString stringWithFormat:@"%@:%@", min, sec] forKeyPath:@"duration" atIndex:([[camera->connect getContextArray:@"Videos"] count]-1)];
                                    });
                 }];
            }
        }
    }
    else if([camera.overlayType isEqualToString:@"music existing"])
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
            
            /*
            //ORIENTATION
            AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(videoTimeLine, NSEC_PER_SEC));
            
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
            [FirstlayerInstruction setOpacity:0.0 atTime:CMTimeMakeWithSeconds(videoTimeLine, NSEC_PER_SEC)];
            
            MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,nil];;
            
            AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
            MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
            MainCompositionInst.frameDuration = CMTimeMake(1, 30);
            MainCompositionInst.renderSize = CGSizeMake(320.0, 480.0);
            */
            
            //Export
            NSURL *outputLink = [camera->connect setNewFile:@"mix" fileFormat:@".mov"];
            
            AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
            exporter.outputURL = outputLink;
            exporter.outputFileType = AVFileTypeQuickTimeMovie;
            exporter.shouldOptimizeForNetworkUse = YES;
            //exporter.videoComposition = MainCompositionInst;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self exportDidFinish:exporter sender:@"existingVideoMix"];
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
}



#pragma mark - Exporting


-(void)exportDidFinish:(AVAssetExportSession*)exportSession sender:(NSString *)type
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success;
    if([type isEqualToString:@"mix"])
    {
        NSLog(@"exporting...");
        //Delete plain video file
        success = [fileManager removeItemAtPath:path error:&error];
        if (!success)
        {
            NSLog(@"Could not delete recorded file -: %@ ",[error localizedDescription]);
        }
    }
    else if([type isEqualToString:@"multipleVideoMix"])
    {
        NSLog(@"exporting...");
        for(int i=0; i<[pathArray count]; i++)
        {
            //Delete plain video file
            success = [fileManager removeItemAtPath:[pathArray objectAtIndex:i] error:&error];
            if (!success)
            {
                NSLog(@"Could not delete recorded file -: %@ ",[error localizedDescription]);
            }
        }
    }
    else if([type isEqualToString:@"existingVideoMix"])
    {
        NSLog(@"exporting...");
    }
    
    
    //UI setup when saving finished
    [camera viewSetup];
    
    
    musicAsset = nil;
    videoAsset = nil;
    extraVideos = nil;
    pathArray = nil;
    musicPausePoints = nil;
    musicPlayPoints = nil;
    audioPausePoints = nil;
    audioPlayPoints = nil;
    finishedVideo = NO;
    multipleVideos = NO;
    
    //Set values
    timerCountdown = 0;
    videoTimeLine = 0;
    musicTimeLine = 0;
    musicPausePlayCount = 0;
    pausePlayPoints = 0;
    countdown = 0;
    
    [camera performSegueWithIdentifier:@"cameraViewToVideosView" sender:camera];
}



#pragma mark - View

-(void)uiControl:(NSString *)type
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
    
    if([camera.overlayType isEqualToString:@"music recording"])
    {
        if([type isEqualToString:@"pause"])
        {
            if(finishedVideo == NO)
            {
                camera.frontBackButton.hidden = NO;
            }
        }
        else if([type isEqualToString:@"merge"] || [type isEqualToString:@"stop"])
        {
            [camera.indicator startAnimating];
            camera.indicatorView.hidden = NO;
            camera.recordPauseButton.hidden = YES;
            camera.pauseButton.hidden = YES;
            camera.recIndicator.hidden = YES;
            camera.recIndicator2.hidden = YES;
            camera.flashlightButton.hidden = YES;
            camera.toolsButton.hidden = YES;
            camera.toolsBoxView.hidden = YES;
            camera.hub1.hidden = YES;
            camera.hub2.hidden = YES;
        }
    }
    else if([camera.overlayType isEqualToString:@"music existing"])
    {
        
        if([type isEqualToString:@"merge"] || [type isEqualToString:@"stop"])
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
            existingVideoPlayer = [[AVPlayer alloc] initWithPlayerItem:item];
            
            layer = [AVPlayerLayer playerLayerWithPlayer:existingVideoPlayer];
            [layer setFrame: camera.view.frame];
            [camera.view.layer insertSublayer:layer atIndex:1];
            [layer setBackgroundColor:[[UIColor blackColor] CGColor]];
        }
    }
}


-(void)hub:(NSString *)type
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


-(void)tools
{
    //Setup activate tools for music video
    camera.toolsButton.hidden = NO;
    
    [self setTrackSegment];
}

-(void)existingVideoViewExit
{
    //Return back to camera view
    [camera viewSetup];
    musicAsset = nil;
    videoAsset = nil;
    camera.overlayType = nil;
    
    [layer removeFromSuperlayer];
}


#pragma mark - Timer



-(void)clockTimer
{
    //Stop player if track segmented
    if([camera.videoOutput isRecording] || isRecording)
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
                [existingVideoPlayer setMuted:NO]; //Existing
                
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

    if([camera.overlayType isEqualToString:@"music recording"])
    {
        //Set time format
        NSString *min = [NSString stringWithFormat:@"%i", (int)videoTimeLine/60];
        NSString *sec = [NSString stringWithFormat:@"%i", (int)videoTimeLine%60];
        
        if(((int)videoTimeLine%60) < 10)
        {
            sec = [NSString stringWithFormat:@"0%i", (int)videoTimeLine%60];
        }
        if(((int)videoTimeLine/60) < 10)
        {
            min = [NSString stringWithFormat:@"0%i", (int)videoTimeLine/60];
        }
        
        camera.timeLabel.text = [NSString stringWithFormat:@"%@:%@", min, sec];
    }
    else if([camera.overlayType isEqualToString:@"music existing"])
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




//Count down before recording
-(void)countdownToRecord
{
    //Set label
    [camera.countdownLabel setText:[NSString stringWithFormat:@"%i", countdown]];
    camera.countdownLabel.hidden = NO;
    
    //Countdown is completed
    if(countdown <= 0)
    {
        //Stop timer reset values...
        [camera->recordFlashTimer invalidate];
        [clockTimer invalidate];
        countdown = 0;
        
        camera.countdownLabel.hidden = YES;
        
        //Run recorder
        [self audioIndicatorPlay];
        return;
    }
    countdown--;
}

@end
