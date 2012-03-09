//
//  FrequencyData.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-07.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import "FrequencyData.h"
#import "Debug.h"

@implementation FrequencyData

- (id)initWithSignal:(float *)signal 
        signalLength:(size_t)sLength 
 frequencyMagnitudes:(float *)magnitudes 
     magnitudeLength:(size_t)mLength {
    
    self = [super init];
    
    if (self) {
        // Copy the provided arrays into our fields
        self->sourceSignal = malloc(sLength * sizeof(float));
        memcpy(self->sourceSignal, signal, sLength * sizeof(float));
        self->frequencyMagnitudes = malloc(mLength * sizeof(float));
        memcpy(self->frequencyMagnitudes, magnitudes, mLength * sizeof(float));        
        
        sourceSignalLength = sLength;
        frequencyMagnitudesLength = mLength;
    }
    
    return self;
}

- (float)calculateAverageMagnitude {
    float sum = 0;
    
    for (int i = 0; i < frequencyMagnitudesLength; i++) 
        sum += frequencyMagnitudes[i];
    
    return sum / frequencyMagnitudesLength;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"FrequencyData(samples=%ld, magnitudes=%ld)", 
            sourceSignalLength,
            frequencyMagnitudesLength];
}

@end
