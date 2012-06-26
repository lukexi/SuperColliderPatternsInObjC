//
//  NSArray+Flop.m
//  Agent
//
//  Created by Luke Iannini on 6/22/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import "NSArray+Flop.h"

@implementation NSArray (Flop)

- (NSArray *)fl_arrayByFlopping
{
    NSUInteger slots = 0;
    for (id object in self)
    {
        if ([object isKindOfClass:[NSArray class]])
        {
            NSArray *array = object;
            slots = MAX(slots, [array count]);
        }
    }
    
    NSMutableArray *floppedArray = [NSMutableArray arrayWithCapacity:slots];
    for (NSUInteger i = 0; i < slots; i++)
    {
        NSMutableArray *arrayEntry = [NSMutableArray arrayWithCapacity:slots];
        for (id object in self)
        {
            if ([object isKindOfClass:[NSArray class]])
            {
                NSArray *array = object;
                [arrayEntry addObject:[array objectAtIndex:i % [array count]]];
            }
            else
            {
                [arrayEntry addObject:object];
            }
        }
        [floppedArray addObject:arrayEntry];
    }
    return floppedArray;
}

@end
