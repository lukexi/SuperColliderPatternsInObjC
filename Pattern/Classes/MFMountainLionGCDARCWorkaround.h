//
//  MFMountainLionGCDARCWorkaround.h
//  MagicFile
//
//  Created by Luke Iannini on 5/11/12.
//  Copyright (c) 2012 Eeoo. All rights reserved.
//

// Works around an issue wherein dispatch_release casts its object as an NSObject and calls release on it on Mountain Lion.

#ifndef MagicFile_MFMountainLionGCDARCWorkaround_h
#define MagicFile_MFMountainLionGCDARCWorkaround_h

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#else
#undef dispatch_release
#define dispatch_release(object) {}
#undef dispatch_retain
#define dispatch_retain(object) {}
#endif

#endif
