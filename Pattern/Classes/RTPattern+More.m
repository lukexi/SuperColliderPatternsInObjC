//
//  RTPattern+More.m
//  Routine
//
//  Created by Luke Iannini on 5/31/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import "RTPattern+More.h"
#import "RTFilterPattern.h"
#import "RTListPattern.h"
#import "NSArray+RTAdditions.h"

@implementation RTPattern (More)

+ (RTPattern *)PnLazyWithFunc:(RTFuncStreamFunc)patternFunc
{
    return [RTPn PnWithPattern:[RTPLazy PLazyWithFunc:patternFunc] repeats:RTInf];
}

+ (RTPattern *)PnLazySequenceWithGenerator:(RTPSequenceGenerator)generatorFunc repeats:(id)repeats
{
    return [RTPattern PnLazyWithFunc:^id(id inValue) {
        return [RTPSeq PSeqWithList:generatorFunc() repeats:repeats offset:@0];
    }];
}

// Phase is 0.0-1.0
+ (RTPattern *)PSinWithSteps:(NSNumber *)steps phase:(NSNumber *)phase from0To:(float)value
{
    return [self PSinWithSteps:steps phase:phase mul:0.5 * value add:0.5 * value];
}

+ (RTPattern *)PSinWithSteps:(NSNumber *)steps phase:(NSNumber *)phase mul:(float)mul add:(float)add
{
    NSUInteger stepsValue = [steps unsignedIntegerValue];
    float phaseValue = [phase floatValue] * 2 * M_PI;
    NSMutableArray *sinValues = [NSMutableArray arrayWithCapacity:stepsValue];
    for (NSUInteger i = 0; i < stepsValue; i++)
    {
        float step = 2 * M_PI * ((float)i / (float)stepsValue);
        [sinValues addObject:[NSNumber numberWithFloat:sinf(step + phaseValue) * mul + add]];
    }
    return [RTPSeq PSeqWithList:sinValues repeats:RTInf offset:@0];
}

@end