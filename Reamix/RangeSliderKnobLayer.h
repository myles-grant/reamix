//
//  RangeSliderKnobLayer.h
//  Reamix
//
//  Created by myles grant on 2015-01-04.
//  Copyright (c) 2015 Pinecone . All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class RangeSlider;

@interface RangeSliderKnobLayer : CALayer

//
@property BOOL highlighted;
@property (weak) RangeSlider *slider;

@end
