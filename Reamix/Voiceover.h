//
//  Voiceover.h
//  Reamix
//
//  Created by myles grant on 2015-01-03.
//  Copyright (c) 2015 Pinecone . All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Camera.h"

@class Camera;

@interface Voiceover : NSObject <AVAudioRecorderDelegate>

//Class property
@property (strong, nonatomic) Camera *camera;


//
-(void)viewExit;

-(void)videoSelected;
-(void)audioVolumeControl;

-(void)audioIndicatorPlay;
-(void)record;
-(void)pause;
-(void)stop;

@end
