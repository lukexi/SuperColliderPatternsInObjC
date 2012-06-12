//
//  RTPattern+More.h
//  Routine
//
//  Created by Luke Iannini on 5/31/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import "RTPattern.h"
#import "RTListPattern.h"

typedef NSArray *(^RTPSequenceGenerator)(void);

@interface RTPSin : RTPattern

// Phase is 0.0-1.0
+ (RTPSin *)steps:(NSNumber *)steps phase:(NSNumber *)phase from0To:(float)value;
+ (RTPSin *)steps:(NSNumber *)steps phase:(NSNumber *)phase mul:(float)mul add:(float)add;

@end

@interface RTPnLazy : RTPattern

+ (RTPnLazy *)func:(RTFuncStreamFunc)patternFunc;
+ (RTPnLazy *)sequenceWithGenerator:(RTPSequenceGenerator)generatorFunc repeats:(id)repeats;

@end
