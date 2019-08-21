//
//  RangeSlider.h
//  Reamix
//
//  Created by myles grant on 2015-01-04.
//  Copyright (c) 2015 Pinecone . All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RangeSlider : UIControl

//
@property (nonatomic) float maximumValue;
@property (nonatomic) float minimumValue;
@property (nonatomic) float upperValue;
@property (nonatomic) float lowerValue;

@property (nonatomic) UIColor* trackColour;
@property (nonatomic) UIColor* trackHighlightColour;
@property (nonatomic) UIColor* knobColour;
@property (nonatomic) float curvaceousness;

//
- (float) positionForValue:(float)value;

@end
