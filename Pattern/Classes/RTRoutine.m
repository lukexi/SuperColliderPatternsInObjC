//
//  RTRoutine.m
//  Routine
//
//  Created by Luke Iannini on 5/30/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import "RTRoutine.h"
#import "MFMountainLionGCDARCWorkaround.h"

#define USE_DISPATCH_SEMAPHORES 1

@interface RTRoutine ()

@property (nonatomic, strong) id yieldedValue;
@property (nonatomic, strong) id inValue;

#if !USE_DISPATCH_SEMAPHORES
@property (nonatomic, strong) NSConditionLock *condition;
#endif

@end

/*
 dispatch_semaphore_t routineShouldContinue = dispatch_semaphore_create(0);
 dispatch_semaphore_t routineHasYielded = dispatch_semaphore_create(0);
 
 // Main thread telling routine to do work and waiting for signal that routine has yielded
 dispatch_semaphore_signal(routineShouldContinue);
 dispatch_semaphore_wait(routineHasYielded, DISPATCH_TIME_FOREVER);
 
 // Routine telling main thread it's done and waiting for next signal to yield
 dispatch_semaphore_signal(routineHasYielded);
 dispatch_semaphore_wait(routineShouldContinue, DISPATCH_TIME_FOREVER);
 
 // Don't forget to release in dealloc
 dispatch_release(routineHasYielded);
 dispatch_release(routineShouldContinue);
 */

@implementation RTRoutine
{
#if USE_DISPATCH_SEMAPHORES
    dispatch_semaphore_t _routineShouldContinue;
    dispatch_semaphore_t _routineHasYielded;
    dispatch_semaphore_t _routineHasEnded;
#endif
    
    dispatch_queue_t _routineQueue;
    BOOL done;
}
#if !USE_DISPATCH_SEMAPHORES
@synthesize condition = _condition;
#endif

#if !USE_DISPATCH_SEMAPHORES
#define HAS_YIELDED 0
#define SHOULD_YIELD 1
#endif

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

    // We set the routineQueue to nil to signal the routineBlock that it should stop executing
    dispatch_queue_set_specific(_routineQueue, &kRoutineSelfKey, NULL, NULL);
    // We signal the routineBlock so it can unblock and exit now that routineQueue is nil
#if USE_DISPATCH_SEMAPHORES
    dispatch_semaphore_signal(_routineShouldContinue);

    // dealloc happens on the main thread, so we need to wait for the routine to complete on it's thread before releasing all the semaphores & and the queue.
    dispatch_semaphore_wait(_routineHasEnded, DISPATCH_TIME_FOREVER);
    
    dispatch_release(_routineShouldContinue);
    dispatch_release(_routineHasYielded);
    dispatch_release(_routineHasEnded);
#else
    [_condition lock];
    [_condition unlockWithCondition:SHOULD_YIELD];
#endif
    
    dispatch_release(_routineQueue);
    //NSLog(@"Deallocated routine! %@", self);
}

static char kRoutineSelfKey;
- (id)initWithBlock:(RTRoutineBlock)routineBlock
{
    self = [super init];
    if (self) {
        // Each routine gets its own queue, but since queues aren't threads (and are more like 'green threads' from haskell), GCD makes this pretty efficient.
        dispatch_queue_t routineQueue = dispatch_queue_create("RTRoutine routineQueue", 0);
        _routineQueue = routineQueue;
        
        // The condition lock switches us between waiting in the main thread for a routine to produce data (which should be a very tiny wait lest we block the main thread), and waiting in the routine for the main thread to request a yield (which could be a long wait).
#if USE_DISPATCH_SEMAPHORES
        dispatch_semaphore_t routineHasYielded = dispatch_semaphore_create(0);
        dispatch_semaphore_t routineShouldContinue = dispatch_semaphore_create(0);
        dispatch_semaphore_t routineHasEnded = dispatch_semaphore_create(0);
        _routineHasYielded = routineHasYielded;
        _routineShouldContinue = routineShouldContinue;
        _routineHasEnded = routineHasEnded;
#else
        NSConditionLock *condition = [[NSConditionLock alloc] initWithCondition:HAS_YIELDED];
        _condition = condition;
#endif
        
        dispatch_queue_set_specific(routineQueue, &kRoutineSelfKey, (__bridge void *)(self), NULL);
        //NSLog(@"Setting routine context to %@", self);
        RTYieldBlock yieldBlock = ^id(id returnValue) {
            // See note above for why we're obtaining the routine reference this way.
            __unsafe_unretained RTRoutine *routine = (__bridge RTRoutine *)(dispatch_get_specific(&kRoutineSelfKey));
            //NSLog(@"Running yield block with routine! %@", routine);
            if (!routine)
            {
                //NSLog(@"Ending thread!");
                // Infinite routines should check for this to see if they should
                // break and allow the thread to end.
                return RTStopToken;
            }
            // We'll access this in rt_next once the HAS_YIELDED lock is obtained by the main thread
            routine.yieldedValue = returnValue;

            //NSLog(@"Yielding %@ and awaiting SHOULD_YIELD/routineShouldContinue", returnValue);
            
#if USE_DISPATCH_SEMAPHORES
            dispatch_semaphore_signal(routineHasYielded);
            dispatch_semaphore_wait(routineShouldContinue, DISPATCH_TIME_FOREVER);
#else
            [condition unlockWithCondition:HAS_YIELDED];
            // Now we wait (possibly a while) until the main thread sets our condition back to SHOULD_YIELD
            [condition lockWhenCondition:SHOULD_YIELD];
#endif
            //NSLog(@"Returning inValue and calculating next yield!");
            routine = (__bridge RTRoutine *)(dispatch_get_specific(&kRoutineSelfKey));
            
            // If rt_next: was used to set a new inValue, we return it so the RTRoutineBlock can use it in its next computation.
            return routine.inValue;
        };
        
        dispatch_async(routineQueue, ^{
            // We wait to run any of the routineBlock until the first rt_next call happens (which sets our condition to SHOULD_YIELD)
#if USE_DISPATCH_SEMAPHORES
            dispatch_semaphore_wait(routineShouldContinue, DISPATCH_TIME_FOREVER);
            //NSLog(@"Finished waiting for routineShouldContinue in routineQueue block");
#else
            [condition lockWhenCondition:SHOULD_YIELD];
#endif
            
            // We check if the routine was deallocated before SHOULD_YIELD was called (i.e. in our dealloc function), meaning we should skip computing anything
            __unsafe_unretained RTRoutine *routine = (__bridge RTRoutine *)(dispatch_get_specific(&kRoutineSelfKey));
            //NSLog(@"Running routine block with routine! %@", routine);
            if (routine)
            {
                routineBlock(yieldBlock, routine.inValue);
                //NSLog(@"Routine block finished!");
                __unsafe_unretained RTRoutine *routine = (__bridge RTRoutine *)(dispatch_get_specific(&kRoutineSelfKey));
                routine.yieldedValue = nil;
            }
            
            // Unlock the lock one last time, from the lock acquired at the end of the last call to yield (or from the initial lock taken above, if we skipped computation)
#if USE_DISPATCH_SEMAPHORES
            dispatch_semaphore_signal(routineHasYielded);
#else
            [condition unlockWithCondition:HAS_YIELDED];
#endif

            //NSLog(@"Routine thread task ended!");
#if USE_DISPATCH_SEMAPHORES
            dispatch_semaphore_signal(routineHasEnded);
#endif
        });
    }
    return self;
}

- (id)rt_next:(id)inValue
{
    // This will be accessed in our yieldBlock so it can be returned to the caller of the yieldBlock (i.e. the routine block)
    self.inValue = inValue;
    return [self rt_next];
}

- (id)rt_next
{
    if (done)
    {
        return nil;
    }
    
#if USE_DISPATCH_SEMAPHORES
    dispatch_semaphore_signal(_routineShouldContinue);
    dispatch_semaphore_wait(_routineHasYielded, DISPATCH_TIME_FOREVER);
#else
    // We lock/unlock with condition SHOULD_YIELD to signal the routine block that it should continue executing
    [self.condition lock];
    [self.condition unlockWithCondition:SHOULD_YIELD];
    
    // We await the HAS_YIELDED condition to signal that the block has finished its computation and assigned the result to yieldedValue
    [self.condition lockWhenCondition:HAS_YIELDED];
    [self.condition unlockWithCondition:HAS_YIELDED];
#endif
    
    // Yielding nil signals the end of the routine
    if (!self.yieldedValue)
    {
        done = YES;
    }
    return self.yieldedValue;
}



@end
