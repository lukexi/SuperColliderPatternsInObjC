//
//  RTRoutine.h
//  Routine
//
//  Created by Luke Iannini on 5/30/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTStream.h"
#import "NSNumber+RTDo.h"

/*
 RTRoutineBlocks provide a yield block and an initial inValue.
 The inValue should be assigned to each time yield is called, in order to update it.
 The initial inValue from the RTYieldBlock will only be non-nil if the first rt_next: call
 to the routine contained something to pass in.
 
 E.g.
 
 id outValue;
 RTRoutine *routine = [RTRoutine routineWithBlock:^(RTYieldBlock yield, id inValue) {
     inValue = yield(@5);
     inValue = yield(@6);
     inValue = yield(@7);
 }];
 outValue = [routine rt_next:@"a"];
 // Out value is now 5, initial inValue will be 'a' (before the call to inValue = yield(@5);)
 outValue = [routine rt_next:@"b"];
 // Out value is now 6, newly assigned inValue will be 'b'
 outValue = [routine rt_next:@"c"];
 // Out value is now 7, newly assigned inValue will be 'c'
 outValue = [routine rt_next];
 // Out value is now nil.
 */

@interface RTRoutine : RTStream

+ (RTRoutine *)routineWithBlock:(RTRoutineBlock)block;

@end
