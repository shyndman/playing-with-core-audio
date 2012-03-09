//
//  FrequencyData.h
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-07.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * The frequency data class contains the input and output of a fast fourier transform.
 */
@interface FrequencyData : NSObject
{
    @public
    
    /** 
     * Contains source signal information, in linear PCM at a sample rate of 44100. Each element
     * is a value between -1.0 and 1.0.
     */ 
    float *sourceSignal;
    size_t sourceSignalLength;

    /**
     * Magnitudes grouped into "bins", which are ranges of frequencies. This range is determined 
     * by the number of elements in the array.
     *
     * The middle of frequency f = i * Fs / N
     */
    float *frequencyMagnitudes;
    size_t frequencyMagnitudesLength;
}

/**
 * Initializes the frequency data instance with signal and frequency magnitude information. 
 *
 * This method will copy the provided array arguments.
 */
- (id)initWithSignal:(float *)sourceSignal
        signalLength:(size_t)signalLength
 frequencyMagnitudes:(float *)mags
     magnitudeLength:(size_t)magnitudeLength;

/**
 * Calculates the average frequency magnitude.
 */
- (float)calculateAverageMagnitude;
@end
