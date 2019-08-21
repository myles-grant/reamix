//
//  Camera.h
//  Reamix
//
//  Created by myles grant on 2014-11-04.
//  Copyright (c) 2014 Pinecone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "Connect.h"
#import "RangeSlider.h"

@interface Camera : UIViewController <AVAudioPlayerDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
    
    @public
    Connect *connect;
    RangeSlider *rangeSlider;
    NSTimer *recordFlashTimer;
    BOOL trackSelected;
    
    //Web 
    UITextField *urlInput;
    UIButton *exitURLInput;
    UIView *urlBackground;
    
    //Music Option View properties
    UILabel *trackStart;
    UILabel *trackTime;
    UILabel *trackEnd;
    UIButton *previewPlay;
    UIButton *autoPause;
}


//
@property (strong, nonatomic) NSString *overlayType;


//
@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) AVAudioPlayer *musicPlayer;
@property (strong, nonatomic) AVCaptureMovieFileOutput *videoOutput;


//UI properties
@property (weak, nonatomic) IBOutlet UIView *optionView;
@property (weak, nonatomic) IBOutlet UILabel *optionTitle;

@property (weak, nonatomic) IBOutlet UIButton *overlayTypeButton;
@property (weak, nonatomic) IBOutlet UIView *overlayTypeView;
@property (weak, nonatomic) IBOutlet UIButton *musicButton;
@property (weak, nonatomic) IBOutlet UIButton *voiceOver;
@property (weak, nonatomic) IBOutlet UIButton *webButton;

@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;
@property (weak, nonatomic) IBOutlet UIButton *recordPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *frontBackButton;
@property (weak, nonatomic) IBOutlet UIButton *flashlightButton;
@property (weak, nonatomic) IBOutlet UIButton *videosButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;

@property (weak, nonatomic) IBOutlet UIButton *voiceoverExitView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UILabel *indicatorLabel;
@property (weak, nonatomic) IBOutlet UIView *indicatorView;

@property (weak, nonatomic) IBOutlet UIButton *toolsButton;
@property (weak, nonatomic) IBOutlet UIView *toolsBoxView;
@property (weak, nonatomic) IBOutlet UIButton *tool1;
@property (weak, nonatomic) IBOutlet UIButton *tool2;
@property (weak, nonatomic) IBOutlet UIButton *tool3;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *recIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *recIndicator2;
@property (weak, nonatomic) IBOutlet UIView *audioVisual;
@property (weak, nonatomic) IBOutlet UIImageView *redRow;
@property (weak, nonatomic) IBOutlet UIImageView *orangeRow;
@property (weak, nonatomic) IBOutlet UIImageView *yellowRow;
@property (weak, nonatomic) IBOutlet UIImageView *greenRow;

@property (weak, nonatomic) IBOutlet UIImageView *hub1;
@property (weak, nonatomic) IBOutlet UIImageView *hub2;
@property (weak, nonatomic) IBOutlet UIImageView *hub3;
@property (weak, nonatomic) IBOutlet UIImageView *hub4;



//
-(void)viewSetup;
-(void)nullViewSetup;
-(void)webURLExit;
-(void)flash;
-(void)recordingIndicator:(BOOL)start;
-(void)trackSegmentSetup;
-(IBAction)tool2:(id)sender;
-(void)levelTimerCallback:(NSTimer *)timer;

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
-(void)null:(NSString *)type;
- (IBAction)selectWeb:(id)sender;



@end
