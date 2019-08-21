//
//  Camera.m
//  Reamix
//
//  Created by myles grant on 2014-11-04.
//  Copyright (c) 2014 Pinecone. All rights reserved.
//

#import "Camera.h"
#import "AppDelegate.h"
#import "Music.h"
#import "Voiceover.h"
#import "Web.h"

@interface Camera() {
    
    Music *music;
    Voiceover *voiceover;
    Web *web;
    
    UIActionSheet *popUnderOptions;
    
    //Capture session
    AVCaptureSession *session;
    AVCaptureDevice *device;
    AVCaptureDeviceInput *inputDevice;

    //Audio Indicator BEEP
    AVAudioPlayer *indicate;
    NSTimer *levelTimer;
    
    //Permissions
    BOOL micAccess;
}

//
@property (weak, nonatomic) IBOutlet UIScrollView *mediaTypeScrollView;

//Methods
- (IBAction)record:(id)sender;
- (IBAction)selectAudio:(id)sender;
- (IBAction)switchCameras:(id)sender;
- (IBAction)flashlight:(id)sender;


@end

@implementation Camera
@synthesize overlayType, videoOutput, musicPlayer, recorder, mediaTypeScrollView;
@synthesize recordPauseButton, frontBackButton, flashlightButton, videosButton, toolsButton, musicButton,  webButton, indicator, indicatorView, pauseButton, timeLabel, overlayTypeView, voiceOver, overlayTypeButton, voiceoverExitView, countdownLabel, recIndicator, recIndicator2, audioVisual, redRow, orangeRow, yellowRow, greenRow, optionView, optionTitle, toolsBoxView, hub1, hub2, hub3, hub4, tool1, tool2, tool3;



-(BOOL)prefersStatusBarHidden { return YES; }

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    /*******************************************************************
     ************************** PERMISSIONS ****************************
     *******************************************************************/
    
    //Get Camera Access Permission
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized)
    {
        NSLog(@"Camera Access Granted");
        [self cameraSetup];
    }
    else if (authStatus == AVAuthorizationStatusDenied)
    {
        NSLog(@"Camera Access Denied");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Denied" message:@"This app does not have access to your camera. You can enable access in Privacy Settings" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    else if(authStatus == AVAuthorizationStatusNotDetermined)
    {
        //UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"Camera and Microphone Access" message:@"To use Reamix access to your camera and microphone is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        //[alert1 show];
        
        //Ask camera permission
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
        {
            if(granted)
            {
                NSLog(@"Granted access");
                [self cameraSetup];
            }
            else
            {
                NSLog(@"Not granted access");
                //Let user know how to get access
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Denied" message:@"This app does not have access to your camera. You can enable access in Privacy Settings" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            }
        }];
    }
    
    
    //Get Microphone Access Permission
    //Setup audio session
    if([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)])
    {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (!granted)
            {
                NSLog(@"Microphone Access Denied");
                micAccess = NO;
            }
            else
            {
                micAccess = YES;
            }
        }];
    }
    
    //Check if device supports functions
    if(![device hasTorch])
    {
        flashlightButton.hidden = YES;
    }
    
    
    //Setup the view before appear
    [self viewSetup];
    
    //alloc init
    connect = [[Connect alloc] init];
    
    music = [[Music alloc] init];
    [music setCamera:self];
    [music setExtraVideos:[[NSMutableArray alloc] init]];
    [music setPathArray:[[NSMutableArray alloc] init]];
    [music setVideoPlayPoints:[[NSMutableArray alloc] init]];
    
    voiceover = [[Voiceover alloc] init];
    [voiceover setCamera:self];
    
    web = [[Web alloc] init];
    [web setCamera:self];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.camera = self;
    
    
    //Check for internet connection
    [connect testInternetConnection];
    
    //Long press gesture to record button... count down
    UILongPressGestureRecognizer *countdown = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressHold:)];
    countdown.minimumPressDuration = 0.5; //seconds
    countdown.delegate = self;
    countdown.delaysTouchesBegan = YES;
    [recordPauseButton addGestureRecognizer:countdown];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Status bar
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}


#pragma mark - View


/*******************************************************************
 ***************************** MUSIC *******************************
 *******************************************************************/

-(void)viewSetup
{
    //UI setup onload
    indicatorView.hidden = YES;
    [indicator stopAnimating];
        
    //Set record button to a circle
    recordPauseButton.layer.cornerRadius = recordPauseButton.bounds.size.width/2;
    [recordPauseButton setImage:nil forState:UIControlStateNormal];
    [recordPauseButton setBackgroundColor:[UIColor redColor]];
    recordPauseButton.hidden = NO;
    
    timeLabel.text = @"00:00";
    timeLabel.hidden = NO;
    countdownLabel.hidden = YES;
    countdownLabel.layer.cornerRadius = countdownLabel.bounds.size.width/2;
    indicatorView.hidden = YES;
    
    toolsBoxView.hidden = YES;
    toolsButton.hidden = YES;
    tool3.hidden = YES;
    
    audioVisual.hidden = YES;
    greenRow.hidden = YES;
    yellowRow.hidden = YES;
    orangeRow.hidden = YES;
    redRow.hidden = YES;
    recIndicator.hidden = YES;
    recIndicator2.hidden = YES;
    hub1.hidden = YES;
    hub2.hidden = YES;
    hub3.hidden = YES;
    hub4.hidden = YES;
    
    pauseButton.hidden = YES;
    [pauseButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    [pauseButton setBackgroundColor:[UIColor clearColor]];
    [pauseButton setTintColor:[UIColor whiteColor]];
    
    flashlightButton.hidden = NO;
    frontBackButton.hidden = NO;
    videosButton.hidden = NO;
    
    [mediaTypeScrollView setScrollEnabled:YES];
    [mediaTypeScrollView setContentSize:CGSizeMake(320, 135)];
    
    overlayTypeView.hidden = YES;
    overlayTypeButton.hidden = NO;
    //musicButton.hidden = NO;
    //webButton.hidden = NO;
    
    voiceoverExitView.hidden = YES;
    
    optionTitle.hidden = YES;
    optionView.hidden = YES;
}


-(void)nullViewSetup
{
    //Hide and disable view for view transition
    //UI.. buttons
    timeLabel.hidden = YES;
    recordPauseButton.hidden = YES;
    flashlightButton.hidden = YES;
    frontBackButton.hidden = YES;
    videosButton.hidden = YES;
    overlayTypeButton.hidden = YES;
    
    if(toolsButton.hidden == NO)
    {
        toolsButton.hidden = YES;
    }
}


-(void)trackSegmentSetup
{
    //Add labels
    [trackStart removeFromSuperview];
    [trackTime removeFromSuperview];
    [trackEnd removeFromSuperview];
    
    trackStart = [[UILabel alloc] initWithFrame:CGRectMake(20, ((optionView.frame.size.height/2)-30)-25, 100, 50)];
    trackStart.textColor = [UIColor whiteColor];
    trackStart.text = @"00:00";
    
    trackTime = [[UILabel alloc] initWithFrame:CGRectMake((optionView.frame.size.width/2)-50, ((optionView.frame.size.height/2)-30)-25, 100, 50)];
    trackTime.textColor = [UIColor whiteColor];
    [trackTime setTextAlignment:NSTextAlignmentCenter];
    
    trackEnd = [[UILabel alloc] initWithFrame:CGRectMake((optionView.frame.size.width-100)-20, ((optionView.frame.size.height/2)-30)-25, 100, 50)];
    trackEnd.textColor = [UIColor whiteColor];
    [trackEnd setTextAlignment:NSTextAlignmentRight];
    
    [optionView addSubview:trackStart];
    [optionView addSubview:trackTime];
    [optionView addSubview:trackEnd];
    
    //Add range slider to view
    [rangeSlider removeFromSuperview];
    
    CGRect sliderFrame = CGRectMake(20, (optionView.frame.size.height/2)-15, optionView.frame.size.width - 20 * 2, 30);
    rangeSlider = [[RangeSlider alloc] initWithFrame:sliderFrame];
    
    [optionView addSubview:rangeSlider];
    
    
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
    {
        [rangeSlider addTarget:music action:@selector(slideValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        [rangeSlider addTarget:web action:@selector(slideValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    
    //Add preview play button
    [previewPlay removeFromSuperview];
    
    previewPlay = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [previewPlay setImage:[UIImage imageNamed:@"preview_play"] forState:UIControlStateNormal];
    previewPlay.tintColor = [UIColor whiteColor];
    previewPlay.frame = CGRectMake((optionView.frame.size.width/2)-50, (optionView.frame.size.height/2)+30, 100, 40);
    
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
    {
        [previewPlay addTarget:music action:@selector(previewTrackSegment) forControlEvents:UIControlEventTouchUpInside];
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        [previewPlay addTarget:web action:@selector(previewTrackSegment) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [optionView addSubview:previewPlay];
    
    //Add auto pause
    [autoPause removeFromSuperview];
    
    autoPause = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [autoPause setImage:[UIImage imageNamed:@"auto_pause"] forState:UIControlStateNormal];
    autoPause.tintColor = [UIColor whiteColor];
    autoPause.frame = CGRectMake((optionView.frame.size.width/2)-90, (optionView.frame.size.height/2)+30, 100, 40);
    
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
    {
        [autoPause addTarget:music action:@selector(autoPause) forControlEvents:UIControlEventTouchUpInside];
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        [autoPause addTarget:web action:@selector(autoPause) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [optionView addSubview:autoPause];
    autoPause.hidden = YES;
}


-(void)cameraSetup
{
    /* ****** SETUP Recorder/Camera ****** */
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetMedium]; //Quality
    
    //Hide camera switch if no front facing camera
    if(![session canAddInput:[AVCaptureDeviceInput deviceInputWithDevice:[self toggleCamera:@"front"] error:nil]])
    {
        frontBackButton.hidden = YES;
    }
    
    //Add visual camera input
    NSError *error;
    
    //Back Camera by default
    device = [self toggleCamera:@"back"];
    inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if([session canAddInput:inputDevice])
    {
        [session addInput:inputDevice];
    }
    else
    {
        //Users device cannot input back camera.. try front camera
        //Handle error
        device = [self toggleCamera:@"front"];
        inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        
        if([session canAddInput:inputDevice])
        {
            [session addInput:inputDevice];
        }
        else
        {
            //Users device cannot input front camera
            //Handle error
            frontBackButton.hidden = YES;
        }
    }
    
    //Add audio input
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput * audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    if([session canAddInput:audioInput])
    {
        [session addInput:audioInput];
    }

    
    //Add outputs
    videoOutput = [[AVCaptureMovieFileOutput alloc] init];
    [session addOutput:videoOutput];
    
    
    //Set Preview View output
    AVCaptureVideoPreviewLayer *prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    [prevLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CALayer *mainLayer = [[self view] layer];
    [mainLayer setMasksToBounds:YES];
    
    CGRect frame = self.view.frame;
    [prevLayer setFrame:frame];
    [mainLayer insertSublayer:prevLayer atIndex:0];
    
    
    [session startRunning];
    /* ****** END ****** */
}


-(void)webURLViewSetup
{
    //Hide properties
    overlayTypeButton.hidden = YES;
    overlayTypeView.hidden = YES;
    frontBackButton.hidden = YES;
    flashlightButton.hidden = YES;
    recordPauseButton.hidden = YES;
    videosButton.hidden = YES;
    toolsButton.hidden = YES;
    toolsBoxView.hidden = YES;
    
    //Set label
    [timeLabel setText:@"Enter URL Of Video File"];
    
    //Add web url input fields
    urlBackground = [[UIView alloc] initWithFrame:CGRectMake(0, timeLabel.frame.size.height, self.view.frame.size.width, 50)];
    urlBackground.backgroundColor = [UIColor blackColor];
    urlBackground.alpha = 0.4;
    
    urlInput = [[UITextField alloc] initWithFrame:CGRectMake(15, 0, urlBackground.frame.size.width-15, urlBackground.frame.size.height)];
    urlInput.delegate = (id<UITextFieldDelegate>)web;
    urlInput.placeholder = @"Video File URL:";
    urlInput.textColor = [UIColor lightGrayColor];
    urlInput.keyboardType = UIKeyboardTypeURL;
    urlInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
    urlInput.autocorrectionType = UITextAutocorrectionTypeNo;
    [urlInput setReturnKeyType:UIReturnKeySearch];
    [urlInput becomeFirstResponder];
    
    exitURLInput = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [exitURLInput addTarget:self action:@selector(webURLExit) forControlEvents:UIControlEventTouchUpInside];
    [exitURLInput setTitle:@"x" forState:UIControlStateNormal];
    exitURLInput.tintColor = [UIColor whiteColor];
    exitURLInput.backgroundColor = [UIColor redColor];
    exitURLInput.alpha = 0.4;
    exitURLInput.frame = CGRectMake(self.view.frame.size.width-25, timeLabel.frame.size.height+urlBackground.frame.size.height, 25, 25);

    
    [urlBackground addSubview:urlInput];
    [self.view addSubview:urlBackground];
    [self.view addSubview:exitURLInput];
}


//Switch camera views.. front back
- (AVCaptureDevice *)toggleCamera:(NSString *)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *deviceTemp in devices)
    {
        if ([deviceTemp position] == AVCaptureDevicePositionFront && [position isEqualToString:@"front"])
        {
            return deviceTemp;
        }
        else if ([deviceTemp position] == AVCaptureDevicePositionBack && [position isEqualToString:@"back"])
        {
            return deviceTemp;
        }
    }
    return nil;
}



- (void)levelTimerCallback:(NSTimer *)timer
{
    [recorder updateMeters];
    
    float volume = [recorder averagePowerForChannel:0] + 120.0;
    
    if(volume >= 65 && volume <= 85)
    {
        greenRow.hidden = NO;
        yellowRow.hidden = YES;
        orangeRow.hidden = YES;
        redRow.hidden = YES;
    }
    else if(volume >= 86 && volume <= 95)
    {
        greenRow.hidden = NO;
        yellowRow.hidden = NO;
        orangeRow.hidden = YES;
        redRow.hidden = YES;
    }
    else if(volume >= 96 && volume <= 105)
    {
        greenRow.hidden = NO;
        yellowRow.hidden = NO;
        orangeRow.hidden = NO;
        redRow.hidden = YES;
    }
    else if(volume >= 106)
    {
        greenRow.hidden = NO;
        yellowRow.hidden = NO;
        orangeRow.hidden = NO;
        redRow.hidden = NO;
    }
    else
    {
        greenRow.hidden = YES;
        yellowRow.hidden = YES;
        orangeRow.hidden = YES;
        redRow.hidden = YES;
    }
}

-(void)flash
{
    if(recIndicator2.hidden == NO)
    {
        recIndicator.hidden = YES;
        recIndicator2.hidden = YES;
    }
    else
    {
        recIndicator.hidden = NO;
        recIndicator2.hidden = NO;
    }
}



#pragma mark - Tool Box UI Controls ... Buttons


//Option View exit

- (IBAction)optionViewExit:(id)sender
{
    //Exit option view
    [self tool2:self];
    
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
    {
        //if preview is playing
        if([musicPlayer isPlaying])
        {
            [music previewTrackSegment];
        }
        
        //auto pause exit
        [music optionViewExit:@"autoPauseExit"];
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        //if preview is playing
        if([musicPlayer isPlaying])
        {
            [web previewTrackSegment];
        }
        
        //auto pause exit
        [web optionViewExit:@"autoPauseExit"];
    }
}


//option for Option View Accepted

- (IBAction)optionViewAccept:(id)sender
{
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
    {
        //if preview is playing
        if([musicPlayer isPlaying])
        {
            [music previewTrackSegment];
        }
        
        //For track segment send to music to create a copy asset
        [music createNewAudioAssetFromTrackSegment];
        
        //Confirm pause time
        [music autoPauseAccepted];
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        //if preview is playing
        if([musicPlayer isPlaying])
        {
            [web previewTrackSegment];
        }
        
        //For track segment send to music to create a copy asset
        [web createNewAudioAssetFromTrackSegment];
        
        //Confirm pause time
        [web autoPauseAccepted];
    }
}




- (IBAction)toolSelection:(id)sender
{
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"] || [overlayType isEqualToString:@"voiceover existing"])
    {
        //Show hide tool box
        if (toolsBoxView.hidden == YES)
        {
            toolsBoxView.hidden = NO;
        }
        else
        {
            toolsBoxView.hidden = YES;
            
            if(optionTitle.hidden == NO)
            {
                optionTitle.hidden = YES;
                optionView.hidden = YES;
                
                //if preview is playing
                if([musicPlayer isPlaying])
                {
                    [music previewTrackSegment];
                }
            }
        }
    }
    else if([overlayType isEqualToString:@"web musicVideo"] || [overlayType isEqualToString:@"web voiceover"])
    {
        //Show hide tool box
        if (toolsBoxView.hidden == YES)
        {
            toolsBoxView.hidden = NO;
        }
        else
        {
            toolsBoxView.hidden = YES;
            
            if(optionTitle.hidden == NO)
            {
                optionTitle.hidden = YES;
                optionView.hidden = YES;
                
                //if preview is playing
                if([musicPlayer isPlaying])
                {
                    [web previewTrackSegment];
                }
            }
        }
    }
}


- (IBAction)tool1:(id)sender
{
    //
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
    {
        //Set hub for either track delay on or off
        if(hub1.hidden == YES)
        {
            hub1.hidden = NO;
            
            //Set track delay
            [music musicVolume:@"trackDelay" trackDelay:YES];
            
        }
        else
        {
            hub1.hidden = YES;
            
            [music musicVolume:@"trackDelay" trackDelay:NO];
        }
    }
    else if([overlayType isEqualToString:@"voiceover existing"])
    {
        //setup tool1 for voiceover
        //turn audio on or off
        [voiceover audioVolumeControl];
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        //Set hub for either track delay on or off
        if(hub1.hidden == YES)
        {
            hub1.hidden = NO;
            
            //Set track delay
            [web musicVolume:@"trackDelay" trackDelay:YES];
            
        }
        else
        {
            hub1.hidden = YES;
            
            [web musicVolume:@"trackDelay" trackDelay:NO];
        }
    }
    else if([overlayType isEqualToString:@"web voiceover"])
    {
        //setup tool1 for voiceover
        //turn audio on or off
        [web audioVolumeControl];
    }
}



- (IBAction)tool2:(id)sender
{
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
    {
        //Show Hide music track segment
        if(optionTitle.hidden == YES)
        {
            optionTitle.hidden = NO;
            optionView.hidden = NO;
            
            toolsBoxView.hidden = YES;
            
            if(overlayTypeView.hidden == NO)
            {
                overlayTypeView.hidden = YES;
            }
        }
        else
        {
            optionTitle.hidden = YES;
            optionView.hidden = YES;
            
            //if preview is playing
            if([musicPlayer isPlaying])
            {
                [music previewTrackSegment];
            }
        }
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        //Show Hide music track segment
        if(optionTitle.hidden == YES)
        {
            optionTitle.hidden = NO;
            optionView.hidden = NO;
            
            toolsBoxView.hidden = YES;
            
            if(overlayTypeView.hidden == NO)
            {
                overlayTypeView.hidden = YES;
            }
        }
        else
        {
            optionTitle.hidden = YES;
            optionView.hidden = YES;
            
            //if preview is playing
            if([musicPlayer isPlaying])
            {
                [web previewTrackSegment];
            }
        }
    }
}



#pragma mark - MediaType/OverlayType UI Controls ... Buttons

- (IBAction)SelectOverlayType:(id)sender
{
    if (overlayTypeView.hidden == YES)
    {
        overlayTypeView.hidden = NO;
        
        //Hide option view if shown
        if(optionTitle.hidden == NO)
        {
            optionTitle.hidden = YES;
            optionView.hidden = YES;
            
            
            //if preview is playing
            if([musicPlayer isPlaying])
            {
                if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
                {
                    [music previewTrackSegment];
                }
                else if ([overlayType isEqualToString:@"web musicVideo"])
                {
                    [web previewTrackSegment];
                }
            }
        }
    }
    else
    {
        overlayTypeView.hidden = YES;
    }
}


-(IBAction)selectAudio:(id)sender
{
    //User selected music video
    //
    popUnderOptions = [[UIActionSheet alloc] initWithTitle:@"Music Video" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                       @"Record",
                       @"Use an Existing Video",
                       nil];
    popUnderOptions.tag = 1;
    [popUnderOptions showInView:self.view];
}


- (IBAction)selectVideo:(id)sender
{
    //User selected voicever
    //
    [voiceover videoSelected];
}


- (IBAction)selectWeb:(id)sender
{
    if(connect->internetConnection)
    {
        if([overlayType isEqualToString:@"web"])
        {
            //User selected to source from web
            //
            popUnderOptions = [[UIActionSheet alloc] initWithTitle:@"Video From The Web" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
                               @"Music Video",
                               @"Voiceover",
                               nil];
            popUnderOptions.tag = 2;
            [popUnderOptions showInView:self.view];
        }
        else
        {
            //Setup UI to recieve URL input
            [self webURLViewSetup];
        }
    }
    else
    {
        //NO internet connection
        [timeLabel setText:@"No Internet Connection"];
        timeLabel.backgroundColor = [UIColor redColor];
        timeLabel.alpha = 1.0;
        
        //Start timer to return label back to normal
        [levelTimer invalidate];
        levelTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(noConnectionTimer) userInfo:self repeats:YES];
    }
}

int count = 0;
-(void)noConnectionTimer
{
    if(count == 1)
    {
        [levelTimer invalidate];
        
        [timeLabel setText:@"00:00"];
        timeLabel.backgroundColor = [UIColor blackColor];
        timeLabel.alpha = 0.4;
        count = 0;
        return;
    }
    count++;
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(popUnderOptions.tag == 1)
    {
        switch (buttonIndex)
        {
            case 0:
            {
                //Record Regular music video
                overlayType = @"music recording";
                [music musicSelected:self];
            }
            break;

            case 1:
            {
                //Record music video using existing video
                overlayType = @"music existing";
                [music musicSelected:self];
            }
            break;
        }
    }
    else if (popUnderOptions.tag == 2)
    {
        switch (buttonIndex)
        {
            case 0:
            {
                //Record web music video
                overlayType = @"web musicVideo";
                [web musicSelected:self];
            }
            break;
                
            case 1:
            {
                //Record web voiceover
                overlayType = @"web voiceover";
                [web webVoiceoverSetup];
            }
            break;
                
            case 2:
            {
                //Cancel
                overlayType = nil;
            }
            break;
        }
    }
}




#pragma mark - On Screen UI Controls ... Buttons

- (IBAction)switchCameras:(id)sender
{
    //Find current device.. and set camera to opposite position
    NSError *error;
    NSString *position;
    if([device position] == AVCaptureDevicePositionFront)
    {
        flashlightButton.hidden = NO;
        position = @"back";
    }
    else if([device position] == AVCaptureDevicePositionBack)
    {
        flashlightButton.hidden = YES;
        position = @"front";
    }
    
    
    AVCaptureDeviceInput *newDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[self toggleCamera:position] error:&error];
    
    [session beginConfiguration];
    [session removeInput:inputDevice];
    
    if ([session canAddInput:newDeviceInput])
    {
        [session addInput:newDeviceInput];
        
        //Set device to new device
        inputDevice = newDeviceInput;
        device = [self toggleCamera:position];
        //frontBackButton.hidden = NO;
    }
    else
    {
        //User most likely can't input the front camera
        //Handle error
        [session addInput:inputDevice];
        //frontBackButton.hidden = YES;
    }
    
    [session commitConfiguration];
}



- (IBAction)flashlight:(id)sender
{
    //Turn on or off flash light
    if([device hasTorch])
    {
        if([device isTorchModeSupported:AVCaptureTorchModeOn])
        {
            if(![device isTorchActive])
            {
                //turn torch on
                [device lockForConfiguration:nil];
                [device setTorchMode:AVCaptureTorchModeOn];
                [device unlockForConfiguration];
            }
            else
            {
                //turn torch off
                [device lockForConfiguration:nil];
                [device setTorchMode:AVCaptureTorchModeOff];
                [device unlockForConfiguration];
            }
        }
        else
        {
            //Device does not support torch
            //Handle error
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Torch Not Supported" message:@"This device does not support torch" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
    }
    else
    {
        //Users device does not support torch
        //Handle error
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Torch Not Supported" message:@"This device does not support torch" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}


- (IBAction)voiceoverExit:(id)sender
{
    if([overlayType isEqualToString:@"voiceover existing"])
    {
        //
        [voiceover viewExit];
    }
    else if([overlayType isEqualToString:@"music existing"])
    {
        //
        [music existingVideoViewExit];
    }
    else if([overlayType isEqualToString:@"web musicVideo"] || [overlayType isEqualToString:@"web voiceover"])
    {
        //
        [web webVideoViewExit];
    }
}


-(void)webURLExit
{
    //show properties
    overlayTypeButton.hidden = NO;
    overlayTypeView.hidden = NO;
    frontBackButton.hidden = NO;
    recordPauseButton.hidden = NO;
    videosButton.hidden = NO;
    
    if(overlayType != nil && ![overlayType isEqualToString:@"web"])
    {
        toolsButton.hidden = NO;
    }
    
    timeLabel.text = @"00:00";
    
    if([device position] == AVCaptureDevicePositionFront)
    {
        flashlightButton.hidden = YES;
    }
    else if([device position] == AVCaptureDevicePositionBack)
    {
        flashlightButton.hidden = NO;
    }
    
    //Remove from view
    [urlInput removeFromSuperview];
    [urlBackground removeFromSuperview];
    [exitURLInput removeFromSuperview];
}



#pragma mark - Callbacks

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        //After User recieves permission denied alert box
        if([alertView.title isEqualToString:@"Access Denied"])
        {
            //Check if device can open app in settings
            if(![[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]])
            {
                //Segue Back to videos view
                [self performSegueWithIdentifier:@"cameraViewToVideosView" sender:self];
            }
            else
            {
                //Segue Back to videos view
                [self performSegueWithIdentifier:@"cameraViewToVideosView" sender:self];
            }
        }
    }
}



#pragma mark - Interruption Prep


-(void)null:(NSString *)type
{
    if([type isEqualToString:@"pause"])
    {
        //pause recording when app enters background
        //Music video
        if(videoOutput.recording)
        {
            NSLog(@"music recorder recording");
            [self pauseRecording:self];
        }
        
        //voiceover
        if(recorder.recording)
        {
            NSLog(@"voice recorder recording");
            [self record:self];
        }
    }
    else if([type isEqualToString:@"stop"])
    {
        //try to save any recored data when app is terminated
        //Music video
        if(videoOutput.recording)
        {
            NSLog(@"music recorder recording");
            //[self record:self];
            [musicPlayer stop];
        }
        
        //voiceover
        if(recorder.recording)
        {
            NSLog(@"voice recorder recording");
            [self pauseRecording:self];
        }
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Recording Setup


//Record button
- (IBAction)record:(id)sender
{
    if([overlayType isEqualToString:@"music recording"])
    {
        if(trackSelected == YES) //Only record if track is selected for now
        {
            if(!videoOutput.recording)
            {
                /******  START RECORDING ******/
                //
                [music audioIndicatorPlay];
            }
            else
            {
                /******  STOP RECORDING ******/
                //
                [music stop];
            }
        }
    }
    else if([overlayType isEqualToString:@"music existing"])
    {
        if(trackSelected == YES) //Only record if track is selected for now
        {
            if(!music->isRecording)
            {
                /******  START RECORDING ******/
                //
                [music audioIndicatorPlay];
            }
            else
            {
                /******  STOP RECORDING ******/
                //
                [music stop];
            }
        }
    }
    else if([overlayType isEqualToString:@"voiceover existing"])
    {
        if(micAccess != NO)
        {
            if (!recorder.recording)
            {
                /******  START RECORDING AUDIO ******/
                //
                [voiceover audioIndicatorPlay];
            }
            else
            {
                
                /******  PAUSE RECORDING AUDIO ******/
                //
                [voiceover pause];
            }
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Denied" message:@"You cannot record a voiceover because access to your microphone was denied. You can allow access within your settings app" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
    }
    else if([overlayType isEqualToString:@"web voiceover"])
    {
        if(micAccess != NO)
        {
            if (!recorder.recording)
            {
                /******  START RECORDING AUDIO ******/
                //
                [web audioIndicatorPlay];
            }
            else
            {
                
                /******  PAUSE RECORDING AUDIO ******/
                //
                [web pause];
            }
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Denied" message:@"You cannot record a voiceover because access to your microphone was denied. You can allow access within your settings app" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        if(trackSelected == YES) //Only record if track is selected for now
        {
            if(!web->isRecording)
            {
                /******  START RECORDING ******/
                //
                [web audioIndicatorPlay];
            }
            else
            {
                /******  STOP RECORDING ******/
                //
                [web stop];
            }
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Select A Media Type" message:@"You must either select a music type or voiceover type before recording" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}



//Press and hold for counter
- (void)pressHold:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
        {
            //
            [music recordHold];
        }
        else if([overlayType isEqualToString:@"voiceover existing"])
        {
            //
            //[voiceover pause];
        }
        else if([overlayType isEqualToString:@"web voiceover"] || [overlayType isEqualToString:@"web musicVideo"])
        {
            //
            
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Select A Media Type" message:@"You must either select a music type or voiceover type before recording" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
    }
}



-(IBAction)pauseRecording:(id)sender
{
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
    {
        //Pause Music video
        [music pause];
    }
    else if([overlayType isEqualToString:@"voiceover existing"])
    {
        /******  STOP AUDIO RECORDING ******/
        //Stop voiceover
        [voiceover stop];
    }
    else if([overlayType isEqualToString:@"web voiceover"])
    {
        //Stop voiceover
        [web stop];
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        //Pasue web
        [web pause];
    }
}


#pragma mark - Audio Indicator "Beep"

-(void)recordingIndicator:(BOOL)start
{
    //
    //AVAudioPlayer *indicate;
    if(start == YES)
    {
        NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"recordIndicatorStart"
                                                  withExtension:@"mp3"];
        indicate = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
        
        if(![indicate  isPlaying])
        {
            [indicate setDelegate:self];
            [indicate play];
        }
    }
    else
    {
        NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"beep7"
                                                  withExtension:@"mp3"];
        indicate = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
        
        if(![indicate  isPlaying])
        {
            //[indicate setDelegate:self];
            [indicate play];
        }
    }
}


- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if([overlayType isEqualToString:@"music recording"] || [overlayType isEqualToString:@"music existing"])
    {
        if(trackSelected == YES) //Only record if track is selected for now
        {
            if(!videoOutput.recording)
            {
                /******  START RECORDING ******/
                [music record];
            }
        }
    }
    else if([overlayType isEqualToString:@"voiceover existing"])
    {
        if(micAccess != NO)
        {
            if (!recorder.recording)
            {
                /******  START RECORDING AUDIO ******/
                [voiceover record];
            }
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Denied" message:@"You cannot record a voiceover because access to your microphone was denied. You can allow access within your settings app" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
    }
    else if([overlayType isEqualToString:@"web voiceover"])
    {
        if(micAccess != NO)
        {
            if (!recorder.recording)
            {
                /******  START RECORDING AUDIO ******/
                [web record];
            }
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Denied" message:@"You cannot record a voiceover because access to your microphone was denied. You can allow access within your settings app" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
    }
    else if([overlayType isEqualToString:@"web musicVideo"])
    {
        if(trackSelected == YES) //Only record if track is selected for now
        {
            if(!web->isRecording)
            {
                /******  START RECORDING ******/
                [web record];
            }
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Select A Media Type" message:@"You must either select a music type or voiceover type before recording" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}



#pragma mark - Navigation


- (IBAction)cameraToVideos:(id)sender
{
    /*
    //Segue Back to videos view
    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    //[self performSegueWithIdentifier:@"cameraToVideos" sender:self];
    */
}

@end
