//
//  RTClock.h
//  PSPattern
//
//  Created by Luke Iannini on 3/25/12.
//  Copyright (c) 2012 Eeoo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RTClockEvent)(void);

@interface RTClock : NSDictionary

+ (RTClock *)defaultClock;

@property (nonatomic) float tempoBPM;
@property (nonatomic) float tempoBPS;
@property (nonatomic) NSUInteger beatsPerBar;

- (void)scheduleEventAtNextBeat:(RTClockEvent)event;

@end
