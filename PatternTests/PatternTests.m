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
        inValue = yield(@4);
        inValue = yield(@5);
        yield(inValue);
    }];
    
    NSNumber *yield1 = [routine rt_next];
    STAssertEquals(yield1, @4, @"Yield1 should yield the NSNumber 4");
    NSNumber *yield2 = [routine rt_next:@"Cheese"];
    STAssertEquals(yield2, @5, @"Yield1 should yield the NSNumber 5");
    NSString *yield3 = [routine rt_next];
    STAssertEquals(yield3, @"Cheese", @"Yield3 should be the passed in value");
    
    STAssertNil([routine rt_next], @"Routine should yield nil after all yields have been processed");
    STAssertNil([routine rt_next], @"Routine should keep yielding nil after all yields have been processed");
    STAssertNil([routine rt_next], @"Routine should keep yielding nil after all yields have been processed");
    STAssertNil([routine rt_next], @"Routine should keep yielding nil after all yields have been processed");
    routine = nil;
    
    NSLog(@"Hi");
}

@end
