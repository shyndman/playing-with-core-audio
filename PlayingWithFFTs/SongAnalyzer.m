//
//  SongAnalyzer.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-05.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import "SongAnalyzer.h"

@interface SongAnalyzer()
- (void)initializeInternal;
@end

@implementation SongAnalyzer
{
    SongModel *_songModel;
    short _fftLog2n;
    int _fftN;
    int _fftHalfN;
    COMPLEX_SPLIT A;
    FFTSetup _fftSetup;
    float *_originalReal;
    float *_obtainedReal;
    float *_hanningWindow;
    float *_windowedReal;
    int _stride;
}

- (id)initWithSong:(SongModel *)songModel 
           fftBits:(short)numberOfBits {
    
    self = [super init];
    
    if (self) {
        _songModel = songModel;
        _fftLog2n = numberOfBits;
        
        [self initializeInternal];
    }
    
    return self;
}

- (void)initializeInternal {
    _fftN = 1 << _fftLog2n;
    _fftHalfN = _fftN / 2;
    _stride = 1;
    
    A.realp = (float *) malloc(_fftHalfN * sizeof(float));
    A.imagp = (float *) malloc(_fftHalfN * sizeof(float));
    
    _hanningWindow = (float *) malloc(_fftN * sizeof(float));    
    vDSP_hann_window(_hanningWindow, _fftN, 0);
    
    _originalReal = (float *) malloc(_fftN * sizeof(float));
    _windowedReal = (float *) malloc(_fftN * sizeof(float));
    _obtainedReal = (float *) malloc(_fftN * sizeof(float));
    _fftSetup = vDSP_create_fftsetup(_fftLog2n, FFT_RADIX2);
}

- (void)analyze {
    
    if (!_songModel.isPlaying) // We don't analyze stopped songs
        return;
    
    // Get the samples
    
    AudioSampleType *samples = [_songModel nextSamplesWithLength: _fftN];
    if (samples == nil)
        return;
    
    // Convert AudioSampleType (SInt16) into floats between -1.0 and 1.0

    for (int i = 0; i < _fftN; i++)
        _originalReal[i] = (samples[i] + 0.5) / 32767.5;

    // Window the input
    
    vDSP_vmul(_originalReal, 1, _hanningWindow, 1, _windowedReal, 1, _fftN);
    
    // Convert our real input (_windowedReal) into even-odd form
    
    vDSP_ctoz((COMPLEX *)_windowedReal, 2, &A, 1, _fftHalfN);
    
    // Perform the fast fourier transform

    vDSP_fft_zrip(_fftSetup, &A, 1, _fftLog2n, FFT_FORWARD);
    
    
}

@end
