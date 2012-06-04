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
    STAssertEquals(yield1, @"a", @"Yield1 should yield the NSString 'a'");
    NSNumber *yield2 = [routine rt_next:@"Cheese"];
    STAssertEquals(yield2, @"b", @"Yield1 should yield the NSString 'b'");
    NSString *yield3 = [routine rt_next];
    STAssertEquals(yield3, @"Cheese", @"Yield3 should be the passed in value");
    
    STAssertNil([routine rt_next], @"Routine should yield nil after all yields have been processed");
    STAssertNil([routine rt_next], @"Routine should keep yielding nil after all yields have been processed");
    STAssertNil([routine rt_next], @"Routine should keep yielding nil after all yields have been processed");
    STAssertNil([routine rt_next], @"Routine should keep yielding nil after all yields have been processed");
    routine = nil;
    
    NSLog(@"Hi");
}

- (void)testEarlyStop
{
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
- (void)NOPEtestHundredsOfPSeqs
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
    RTPBind *bind = [RTPBind PBindWithPairs:@[
                     @"dur", [RTPSeq PSeqWithList:@[@1, @2, @0.5] repeats:@5]
                     ]];
    RTEventStreamPlayer *player = [bind playBlock:^(NSDictionary *event) {
        NSLog(@"Event! %@", event);
    }];
    
    STAssertNotNil(player, @"RTPBind -playBlock: must return an RTEventStreamPlayer");
    
    NSLog(@"Player: %@", player);
}

@end
