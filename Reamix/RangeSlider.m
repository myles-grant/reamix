//
//  RangeSlider.m
//  Reamix
//
//  Created by myles grant on 2015-01-04.
//  Copyright (c) 2015 Pinecone . All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "RangeSlider.h"
#import "RangeSliderKnobLayer.h"
#import "RangeSliderTrackLayer.h"
#import "Music.h"
#import "Web.h"

@implementation RangeSlider
{
    RangeSliderKnobLayer *upperKnobLayer;
    RangeSliderKnobLayer *lowerKnobLayer;
    RangeSliderTrackLayer *trackLayer;
    
    float knobWidth;
    float useableTrackLength;
    
    CGPoint previousTouchPoint;
}

@synthesize maximumValue, minimumValue, upperValue, lowerValue;
@synthesize trackColour, trackHighlightColour, knobColour, curvaceousness;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        //Initialization code
        maximumValue = 10.0;
        minimumValue = 0.0;
        upperValue = 10.0;
        lowerValue = 0.0;
        
        trackHighlightColour = [UIColor colorWithRed:0.0 green:0.45 blue:0.94 alpha:1.0];
        trackColour = [UIColor colorWithWhite:0.9 alpha:1.0];
        knobColour = [UIColor whiteColor];
        curvaceousness = 1.0;
        
        trackLayer = [RangeSliderTrackLayer layer];
        trackLayer.slider = self;
        [self.layer addSublayer:trackLayer];
        
        upperKnobLayer = [RangeSliderKnobLayer layer];
        upperKnobLayer.slider = self;
        [self.layer addSublayer:upperKnobLayer];
        
        lowerKnobLayer = [RangeSliderKnobLayer layer];
        lowerKnobLayer.slider = self;
        
        [self.layer addSublayer:lowerKnobLayer];
        [self setLayerFrames];
    }
    return self;
}


- (void) setLayerFrames
{
    trackLayer.frame = CGRectInset(self.bounds, 0, self.bounds.size.height / 3.5);
    [trackLayer setNeedsDisplay];
    
    knobWidth = self.bounds.size.height;
    useableTrackLength = self.bounds.size.width - knobWidth;
    
    float upperKnobCentre = [self positionForValue:upperValue];
    upperKnobLayer.frame = CGRectMake(upperKnobCentre - knobWidth / 2, 0, knobWidth, knobWidth);
    
    float lowerKnobCentre = [self positionForValue:lowerValue];
    lowerKnobLayer.frame = CGRectMake(lowerKnobCentre - knobWidth / 2, 0, knobWidth, knobWidth);
    
    [upperKnobLayer setNeedsDisplay];
    [lowerKnobLayer setNeedsDisplay];
}

- (float)positionForValue:(float)value
{
    return useableTrackLength * (value - minimumValue) /
    (maximumValue - minimumValue) + (knobWidth / 2);
}



- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    previousTouchPoint = [touch locationInView:self];
    
    // hit test the knob layers
    if(CGRectContainsPoint(lowerKnobLayer.frame, previousTouchPoint))
    {
        lowerKnobLayer.highlighted = YES;
        [lowerKnobLayer setNeedsDisplay];
    }
    else if(CGRectContainsPoint(upperKnobLayer.frame, previousTouchPoint))
    {
        upperKnobLayer.highlighted = YES;
        [upperKnobLayer setNeedsDisplay];
    }
    return upperKnobLayer.highlighted || lowerKnobLayer.highlighted;
}


#define BOUND(VALUE, UPPER, LOWER)	MIN(MAX(VALUE, LOWER), UPPER)

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    
    // 1. determine by how much the user has dragged
    float delta = touchPoint.x - previousTouchPoint.x;
    float valueDelta = (maximumValue - minimumValue) * delta / useableTrackLength;
    
    previousTouchPoint = touchPoint;
    
    // 2. update the values
    if (lowerKnobLayer.highlighted)
    {
        lowerValue += valueDelta;
        lowerValue = BOUND(lowerValue, upperValue, minimumValue);
    }
    if (upperKnobLayer.highlighted)
    {
        upperValue += valueDelta;
        upperValue = BOUND(upperValue, maximumValue, lowerValue);
    }
    
    // 3. Update the UI state
    [CATransaction begin];
    [CATransaction setDisableActions:YES] ;
    
    [self setLayerFrames];
    
    [CATransaction commit];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    return YES;
}


- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    lowerKnobLayer.highlighted = upperKnobLayer.highlighted = NO;
    [lowerKnobLayer setNeedsDisplay];
    [upperKnobLayer setNeedsDisplay];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
