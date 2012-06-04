//
//  PatternTests.m
//  PatternTests
//
//  Created by Luke Iannini on 6/2/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import "PatternTests.h"
#import "Pattern.h"

@implementation PatternTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testRoutine
{
    RTRoutine *routine = [RTRoutine routineWithBlock:^(RTYieldBlock yield, id inValue) {
        inValue = yield(@"a");
        inValue = yield(@"b");
        yield(inValue);
    }];
    
    NSNumber *yield1 = [routine rt_next];
    STAssertEqualObjects(yield1, @"a", @"Yield1 should yield the NSString 'a'");
    NSNumber *yield2 = [routine rt_next:@"Cheese"];
    STAssertEqualObjects(yield2, @"b", @"Yield1 should yield the NSString 'b'");
    NSString *yield3 = [routine rt_next];
    STAssertEqualObjects(yield3, @"Cheese", @"Yield3 should be the passed in value");
    
    STAssertNil([routine rt_next], @"Routine should yield nil after all yields have been processed");
    STAssertNil([routine rt_next], @"Routine should keep yielding nil after all yields have been processed");
    STAssertNil([routine rt_next], @"Routine should keep yielding nil after all yields have been processed");
    STAssertNil([routine rt_next], @"Routine should keep yielding nil after all yields have been processed");
    routine = nil;
    
    NSLog(@"Hi");
}

- (void)testEmbedRoutine
{
    __weak RTRoutine *weakRoutine1;
    __weak RTRoutine *weakRoutine2;
    // We use an autorelease pool around the meat of this test to make sure that weakRoutine1 and weakRoutine2 will be deallocated at the end.
    @autoreleasepool
    {
        RTRoutine *routine1 = [RTRoutine routineWithBlock:^(RTYieldBlock yield, id inValue) {
            inValue = yield(@"c");
            inValue = yield(@"d");
        }];
        RTRoutine *routine2 = [RTRoutine routineWithBlock:^(RTYieldBlock yield, id inValue) {
            inValue = yield(@"a");
            inValue = yield(@"b");
            [routine1 embedInStream:yield inValue:inValue];
            inValue = yield(@"e");
        }];
        
        weakRoutine1 = routine1;
        weakRoutine2 = routine2;
        
        STAssertEqualObjects([routine2 rt_next], @"a", @"routine2 should yield a 1st");
        STAssertEqualObjects([routine2 rt_next], @"b", @"routine2 should yield b 2nd");
        STAssertEqualObjects([routine2 rt_next], @"c", @"Embedded routine1 should yield c 3rd");
        STAssertEqualObjects([routine2 rt_next], @"d", @"Embedded routine1 should yield d 4th");
        STAssertEqualObjects([routine2 rt_next], @"e", @"routine2 should yield d 5th after having control returned to it by routine1");
        
        NSLog(@"Routine 1 : %@", routine1);
        NSLog(@"Routine 2 : %@", routine2);
        
        // Release our strong references to the routine so the weak references disappear too.
        routine1 = nil;
        routine2 = nil;
    }
    
    STAssertNil(weakRoutine1, @"routine1 should be deallocated after usage");
    STAssertNil(weakRoutine2, @"routine2 should be deallocated after usage");
}

- (void)testEarlyStop
{
    // Since this pattern should be deallocated before it completes its 'count to 1000' loop,
    // we should see inValue become RTStopToken (which is what yield returns when its containing
    // pattern has been deallocated)
    RTRoutine *routine = [RTRoutine routineWithBlock:^(RTYieldBlock yield, id inValue) {
        
        for (NSUInteger i = 0; i < 1000; i++)
        {
            inValue = yield([NSNumber numberWithUnsignedInt:i]);
            if (inValue == RTStopToken)
            {
                NSLog(@"Breaking early in routine!");
                break;
            }
        }
        STAssertEquals(inValue, RTStopToken, @"Routine should stop early with RTStopToken");
    }];
    
    [routine rt_next];
    
    routine = nil;
}

// We run tons of these to make sure Routine memory management is sound
- (void)testHundredsOfPSeqs
{
    for (NSUInteger i = 0; i < 100; i++)
    {
        RTPSeq *PSeq = [RTPSeq PSeqWithList:@[ @1, @2, @3, @4 ] repeats:@3];
        
        RTRoutine *routine = [PSeq rt_asStream];
        
        for (NSUInteger i = 0; i < 2; i++)
        {
            NSNumber *yield1 = [routine rt_next];
            STAssertEquals(yield1, @1, @"Yield1 should yield the NSNumber 1");
            NSNumber *yield2 = [routine rt_next];
            STAssertEquals(yield2, @2, @"Yield2 should yield the NSNumber 2");
            NSNumber *yield3 = [routine rt_next];
            STAssertEquals(yield3, @3, @"Yield3 should yield the NSNumber 3");
            NSNumber *yield4 = [routine rt_next];
            STAssertEquals(yield4, @4, @"Yield4 should yield the NSNumber 4");
        }
    }
}

- (void)testEventStreamPlayer
{
    __weak RTEventStreamPlayer *weakEventStreamPlayer;
    @autoreleasepool {
        RTPBind *bind = [RTPBind PBindWithPairs:@[
                         @"dur", [RTPSeq PSeqWithList:@[@0.1, @0.1, @0.1] repeats:@3]
                         ]];
        RTEventStreamPlayer *eventStreamPlayer = [bind playBlock:^(NSDictionary *event) {
            STAssertEqualObjects(@{@"dur":@0.1}, event, @"Event should look like @{@\"dur\":@0.1}");
            NSLog(@"Event! %@", event);
        }];
        weakEventStreamPlayer = eventStreamPlayer;
        
        STAssertNotNil(eventStreamPlayer, @"RTPBind -playBlock: must return an RTEventStreamPlayer");
        
        // Make sure the events have time to complete
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    
    STAssertNil(weakEventStreamPlayer, @"Event stream player should be released after playing all its events");
}

@end
