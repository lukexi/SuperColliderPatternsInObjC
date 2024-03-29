//
//  RTStream.h
//  Routine
//
//  Created by Luke Iannini on 5/31/12.
//  Copyright (c) 2012 Tree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSNumber+RTDo.h"
#import "NSObject+RTEmbedInStream.h"

static NSString *RTStopToken = @"RTStopToken";

#define RTStopAndReturnIfStopToken(inValueToCheck) \
if (inValueToCheck == RTStopToken)\
{\
    *stop = YES;\
    return;\
}

@interface RTStream : NSObject <RTEmbedInStream, RTDo>

- (NSArray *)nextN:(NSUInteger)nextN;

@end
