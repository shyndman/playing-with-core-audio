//
//  SongAnalyzer.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-05.
//

#import <Accelerate/Accelerate.h>

#import "SongAnalyzer.h"
#import "Debug.h"

@interface SongAnalyzer()
- (void)initializeFFT;
@end

@implementation SongAnalyzer
{
    SongModel *_songModel;
    short _fftLog2n;
    int _fftN;
    int _fftHalfN;
    COMPLEX_SPLIT _fourierOutput;
    FFTSetup _fftSetup;
    float *_inputReal;
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
        
        [self initializeFFT];
    }
    
    return self;
}

- (void)initializeFFT {
    _fftN = 1 << _fftLog2n;
    _fftHalfN = _fftN / 2;
    _stride = 1;
    
    _fourierOutput.realp = (float *) malloc(_fftHalfN * sizeof(float));
    _fourierOutput.imagp = (float *) malloc(_fftHalfN * sizeof(float));
    
    _hanningWindow = (float *) malloc(_fftN * sizeof(float));    
    vDSP_hann_window(_hanningWindow, _fftN, 0);
    
    _inputReal = (float *) malloc(_fftN * sizeof(float));
    _windowedReal = (float *) malloc(_fftN * sizeof(float));
    _fftSetup = vDSP_create_fftsetup(_fftLog2n, FFT_RADIX2);
}

- (FrequencyData *)analyze {
    

    if (!_songModel.isPlaying) // TODO Change this to hasData. A stopped song should be analyzable.
        return nil;
    
    // Get the samples
    
    AudioSampleType *samples = [_songModel nextSamplesWithLength: _fftN];
        
#ifdef DEBUG
//    [Debug printSInt16Array:samples
//                withLength:_fftN 
//                      name:@"input"];
#endif
    
    if (samples == nil)
        return nil;
    
    // Convert AudioSampleTypes (SInt16s) into floats between -1.0 and 1.0 (required by
    // the DSP library).
    
    // TODO Figure out how to vectorize this

    for (int i = 0; i < _fftN; i++)
        _inputReal[i] = (samples[i] + 0.5) / 32767.5;

#ifdef DEBUG
//    [Debug printFloatArray:_inputReal
//                      withLength:_fftN 
//                            name:@"input"];
#endif
    
    // Window the input (improves the ability to distinguish between waves of different
    // frequencies)
    
//    vDSP_vmul(_inputReal, 1, _hanningWindow, 1, _windowedReal, 1, _fftN);

#ifdef DEBUG
//    [Debug printFloatArray:_windowedReal withLength:_fftN name:@"windowed"];
#endif
    
    // Convert our real input (_windowedReal) into even-odd form
    
//    vDSP_ctoz((COMPLEX *)_windowedReal, 2, &_fourierOutput, 1, _fftHalfN);
    
    // Perform the fast fourier transform

//    vDSP_fft_zrip(_fftSetup, &_fourierOutput, 1, _fftLog2n, FFT_FORWARD);
    
    // Calculate magnitudes (will output to the real part of the COMPLEX_SPLIT)
    
//    vDSP_zvmags(&_fourierOutput, 1, _fourierOutput.realp, 1, _fftHalfN);
    
#ifdef DEBUG
//    [Debug printBinnedFloatArray:_fourierOutput.realp 
//                      withLength:_fftHalfN 
//                          perBin:32
//                            name:@"mags"];
#endif
    
    // Build and return the input and output of the analysis
    
    return [[FrequencyData alloc] initWithSignal:_inputReal 
                                    signalLength:_fftN  
                             frequencyMagnitudes:_fourierOutput.realp
                                 magnitudeLength:_fftHalfN];
}

@end
