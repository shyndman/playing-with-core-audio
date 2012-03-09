//
//  FrameData.h
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-08.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface FrameData : NSObject
{
    @public
    AudioSampleType *samples;
    size_t numSamples;
    AudioQueueLevelMeterState levelState;
}

- (id)initWithSamples:(AudioSampleType *)samples
               length:(size_t)length
           levelState:(AudioQueueLevelMeterState)state;
@end
