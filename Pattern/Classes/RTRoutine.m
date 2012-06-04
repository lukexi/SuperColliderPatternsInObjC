//
//  RTRoutine.m
//  Routine
//
//  Created by Luke Iannini on 5/30/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import "RTRoutine.h"
#import "MFMountainLionGCDARCWorkaround.h"

@interface RTRoutine ()

@property (nonatomic, strong) id yieldedValue;
@property (nonatomic, strong) id inValue;
@property (nonatomic, strong) NSConditionLock *condition;

@end

@implementation RTRoutine
{
    dispatch_queue_t _routineQueue;
    BOOL done;
}
#define HAS_YIELDED 0
#define SHOULD_YIELD 1

+ (RTRoutine *)routineWithBlock:(RTRoutineBlock)block
{
    return [[self alloc] initWithBlock:block];
}

/*
 We're using dispatch_queue_set_specific/dispatch_get_specific as a way to weakly retrieve
 a reference to the RTRoutine object itself inside the routineBlock, and invalidate it when the RTRoutine is deallocated.
 Using ARC weak references, ARC tries to retain/autorelease the weak reference when it's accessed, but since the
 lock is hit, the autorelease never drains, meaning we have a retain cycle.
 */

- (void)dealloc
{
    //NSLog(@"Deallocating and setting context to null for routine %@", self);
    dispatch_queue_set_specific(_routineQueue, &kRoutineSelfKey, NULL, NULL);
    [_condition lock];
    [_condition unlockWithCondition:SHOULD_YIELD];
    dispatch_release(_routineQueue);
    NSLog(@"Deallocated routine! %@", self);
}

static char kRoutineSelfKey;
- (id)initWithBlock:(RTRoutineBlock)routineBlock
{
    self = [super init];
    if (self) {
        dispatch_queue_t routineQueue = dispatch_queue_create("RTRoutine routineQueue", 0);
        _routineQueue = routineQueue;
        NSConditionLock *condition = [[NSConditionLock alloc] initWithCondition:HAS_YIELDED];
        _condition = condition;
        
        dispatch_queue_set_specific(routineQueue, &kRoutineSelfKey, (__bridge void *)(self), NULL);
        //NSLog(@"Setting routine context to %@", self);
        RTYieldBlock yieldBlock = ^id(id returnValue) {
            __unsafe_unretained RTRoutine *routine = (__bridge RTRoutine *)(dispatch_get_specific(&kRoutineSelfKey));
            //NSLog(@"Running yield block with routine! %@", routine);
            if (!routine)
            {
                //NSLog(@"Ending thread!");
                // Infinite routines can check for this to see if they should
                // break and allow the thread to end.
                return RTStopToken;
            }
            routine.yieldedValue = returnValue;
            [condition unlockWithCondition:HAS_YIELDED];
            //NSLog(@"Yielding %@ and awaiting SHOULD_YIELD", returnValue);
            [condition lockWhenCondition:SHOULD_YIELD];
            //NSLog(@"Returning inValue and calculating next yield!");
            routine = (__bridge RTRoutine *)(dispatch_get_specific(&kRoutineSelfKey));
            return routine.inValue;
        };
        
        dispatch_async(routineQueue, ^{
            [condition lockWhenCondition:SHOULD_YIELD];
            __unsafe_unretained RTRoutine *routine = (__bridge RTRoutine *)(dispatch_get_specific(&kRoutineSelfKey));
            //NSLog(@"Running routine block with routine! %@", routine);
            if (routine)
            {
                routineBlock(yieldBlock, routine.inValue);
                //NSLog(@"Routine block finished!");
                __unsafe_unretained RTRoutine *routine = (__bridge RTRoutine *)(dispatch_get_specific(&kRoutineSelfKey));
                routine.yieldedValue = nil;
            }
            [condition unlockWithCondition:HAS_YIELDED];
            //NSLog(@"Routine thread task ended!");
        });
    }
    return self;
}

- (id)rt_next:(id)inValue
{
    self.inValue = inValue;
    return [self rt_next];
}

- (id)rt_next
{
    if (done)
    {
        return nil;
    }
    [self.condition lock];
    [self.condition unlockWithCondition:SHOULD_YIELD];
    [self.condition lockWhenCondition:HAS_YIELDED];
    [self.condition unlockWithCondition:HAS_YIELDED];
    if (!self.yieldedValue)
    {
        done = YES;
    }
    return self.yieldedValue;
}



@end
