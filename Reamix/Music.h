//
//  Music.h
//  Reamix
//
//  Created by myles grant on 2014-12-30.
//  Copyright (c) 2014 Pinecone . All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Camera.h"

@class Camera;

@interface Music : NSObject <MPMediaPickerControllerDelegate, AVCaptureFileOutputRecordingDelegate>
{
    @public
    BOOL isRecording;
}


//Class properties
@property (strong, nonatomic) Camera *camera;

//
@property (strong, nonatomic) NSMutableArray *extraVideos;
@property (strong, nonatomic) NSMutableArray *pathArray;
@property (strong, nonatomic) NSMutableArray *videoPlayPoints;

//
-(void)musicSelected:(UIViewController *)view;


//
-(void)audioIndicatorPlay;
-(void)record;
-(void)stop;
-(void)pause;
-(void)recordHold;

-(void)previewTrackSegment;
-(void)optionViewExit:(NSString *)type;

//
-(void)slideValueChanged:(id)control;
-(void)createNewAudioAssetFromTrackSegment;
-(void)musicVolume:(NSString *)type trackDelay:(BOOL)delay;
-(void)existingVideoViewExit;
-(void)autoPause;
-(void)autoPauseAccepted;


@end
