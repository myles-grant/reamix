//
//  SwipeRight.m
//  Reamix
//
//  Created by myles grant on 2014-11-05.
//  Copyright (c) 2014 Pinecone. All rights reserved.
//

#import "SwipeRight.h"

@implementation SwipeRight


- (void)perform
{
    
    
    UIViewController *srcViewController = (UIViewController *) self.sourceViewController;
    UIViewController *destViewController = (UIViewController *) self.destinationViewController;
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    
    [srcViewController presentViewController:destViewController animated:NO completion:nil];
    [srcViewController.view.window.layer addAnimation:transition forKey:nil];
}

@end
