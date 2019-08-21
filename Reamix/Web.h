//
//  Web.h
//  Reamix
//
//  Created by myles grant on 2015-01-06.
//  Copyright (c) 2015 Pinecone . All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Camera.h"

@class Camera;

@interface Web : NSObject <MPMediaPickerControllerDelegate, AVAudioRecorderDelegate, UITextFieldDelegate, UIAlertViewDelegate>
{
    @public
    BOOL isRecording;
}



//Class properties
@property (strong, nonatomic) Camera *camera;


/* music Video methods */
//
-(void)musicSelected:(UIViewController *)view;


//
-(void)audioIndicatorPlay;
-(void)record;
-(void)stop;
-(void)pause;
//-(void)recordHold;

-(void)previewTrackSegment;
-(void)optionViewExit:(NSString *)type;

//
-(void)slideValueChanged:(id)control;
-(void)createNewAudioAssetFromTrackSegment;
-(void)musicVolume:(NSString *)type trackDelay:(BOOL)delay;
-(void)webVideoViewExit;
-(void)autoPause;
-(void)autoPauseAccepted;


/* voiceover methods */
-(void)webVoiceoverSetup;
-(void)audioVolumeControl;

@end
