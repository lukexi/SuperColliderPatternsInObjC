//
//  SCPattern.h
//  Routine
//
//  Created by Luke Iannini on 5/31/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTRoutine.h"
#import "RTFuncStream.h"
#import "RTEventStreamPlayer.h"

#define RTInf [NSNumber numberWithInteger:INFINITY]

@interface RTPattern : NSObject <RTEmbedInStream>

@end

@interface RTPFunc : RTPattern

+ (RTPFunc *)func:(RTFuncStreamFunc)func;

@end

@interface RTPBrown : RTPattern

+ (RTPBrown *)low:(id)low high:(id)high step:(id)step length:(id)length;
@property (nonatomic, strong) id low;
@property (nonatomic, strong) id high;
@property (nonatomic, strong) id step;
@property (nonatomic, strong) id length;

@end

@interface RTPWhite : RTPattern

+ (RTPWhite *)low:(id)low high:(id)high length:(id)length;
@property (nonatomic, strong) id low;
@property (nonatomic, strong) id high;
@property (nonatomic, strong) id length;

@end

@interface RTPLazy : RTPattern

+ (RTPLazy *)func:(RTFuncStreamFunc)func;
@property (nonatomic, strong) RTFuncStreamFunc func;

@end

@interface RTPBind : RTPattern

+ (RTPBind *)pairs:(NSArray *)patternPairs;
// You must pass in a prototype dictionary when calling next: on RTPBind
@property (nonatomic, strong) NSArray *patternPairs;

- (RTEventStreamPlayer *)playBlocks:(NSArray *)eventBlocks;
- (RTEventStreamPlayer *)playBlocks:(NSArray *)eventBlocks withPrototypeEvent:(NSDictionary *)prototypeEvent;
- (RTEventStreamPlayer *)playBlock:(RTEventBlock)eventBlock;
- (RTEventStreamPlayer *)playBlock:(RTEventBlock)eventBlock withPrototypeEvent:(NSDictionary *)prototypeEvent;

@end