//
//  SongAnalyzer.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-05.
//

#import <Accelerate/Accelerate.h>
#import "SongAnalyzer.h"

@interface SongAnalyzer()
- (void)initializeFFT;
@end

#ifdef DEBUG
static void printFloatArray(NSString *name, float *arr, size_t length) {
    for (int i = 0; i < length; i++) 
        NSLog(@"%@[%d] = %f", name, i, arr[i]);
}
#endif

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

- (void)analyze {
    
    if (!_songModel.isPlaying) // We don't analyze stopped songs
        return;
    
    // Get the samples
    
    AudioSampleType *samples = [_songModel nextSamplesWithLength: _fftN];
    if (samples == nil)
        return;
    
    // Convert AudioSampleTypes (SInt16s) into floats between -1.0 and 1.0 (required by
    // the DSP library).

    for (int i = 0; i < _fftN; i++)
        _inputReal[i] = (samples[i] + 0.5) / 32767.5;

#ifdef DEBUG
    printFloatArray(@"input", _inputReal, _fftN);
#endif
    
    // Window the input (improves the ability to distinguish between waves of different
    // frequencies)
    
    vDSP_vmul(_inputReal, 1, _hanningWindow, 1, _windowedReal, 1, _fftN);

#ifdef DEBUG
    printFloatArray(@"windowed", _windowedReal, _fftN);
#endif
    
    // Convert our real input (_windowedReal) into even-odd form
    
    vDSP_ctoz((COMPLEX *)_windowedReal, 2, &_fourierOutput, 1, _fftHalfN);
    
    // Perform the fast fourier transform

    vDSP_fft_zrip(_fftSetup, &_fourierOutput, 1, _fftLog2n, FFT_FORWARD);
    
    // Calculate magnitudes (will output to the real part of the COMPLEX_SPLIT)
    
    vDSP_zvmags(&_fourierOutput, 1, _fourierOutput.realp, 1, _fftHalfN);
    
#ifdef DEBUG
    printFloatArray(@"frequency", _fourierOutput.realp, _fftHalfN);
#endif
}

@end
