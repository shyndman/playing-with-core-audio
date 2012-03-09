//
//  FrameData.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-08.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import "FrameData.h"

@implementation FrameData

- (id)initWithSamples:(AudioSampleType *)samples
               length:(size_t)length
           levelState:(AudioQueueLevelMeterState)state {
    
    self = [super init];
    
    if (self) {
        self->samples = samples;
        self->numSamples = length;
        self->levelState = state;
    }
    
    return self;
}

- (void)dealloc {
    free(samples);
}

@end
