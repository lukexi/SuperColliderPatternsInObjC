//
//  PDViewController.m
//  PatternDemo
//
//  Created by Luke Iannini on 6/3/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import "PDViewController.h"

@interface PDViewController ()

@end

@implementation PDViewController
{
    RTRoutine *routine;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    routine = [RTRoutine routineWithBlock:^(RTYieldBlock yield, id inValue) {
        inValue = yield(@"fried");
        if (inValue == RTStopToken)
        {
            NSLog(@"Broke early!!");
            return;
        }
        inValue = yield(@"egg");
        inValue = yield(@"casserole");
        NSLog(@"END OF THE LINE");
    }];
    
    NSLog(@"Yield1 is %@", [routine rt_next]);
//    NSLog(@"Yield1 is %@", [routine rt_next]);
//    NSLog(@"Yield1 is %@", [routine rt_next]);
//    NSLog(@"Yield1 is %@", [routine rt_next]);
    routine = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
