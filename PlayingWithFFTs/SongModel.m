//
//  SoundModel.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-04.
//

#import <AudioToolbox/AudioToolbox.h>

#import "SongModel.h"
#import "Debug.h"

#define NUM_BUFFERS         3
#define SAMPLES_PER_FRAME   1
#define FRAMES_PER_BUFFER   4096
#define BYTES_PER_BUFFER    FRAMES_PER_BUFFER * SAMPLES_PER_FRAME * sizeof(AudioSampleType)

/********************
 * Private interface
 *******************/

@interface SongModel() 
- (void)openFile;
- (void)initAudioQueue;
- (void)closeFile;
- (void)fillAndEnqueueBuffer:(AudioQueueBufferRef)ref;
- (void)play;
@end


/**************
 * C Callbacks
 *************/

/**
 * Called when the audio queue requires that a queue be filled with new data.
 */
static void audioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    SongModel *model = (__bridge SongModel *)inUserData;
    [model fillAndEnqueueBuffer:inBuffer];
}
     

/*****************
 * Implementation
 ****************/

@implementation SongModel
{
    /** The source audio file */
    ExtAudioFileRef _sourceFile;
    
    /** Total number of frames in the song */
    SInt64 _numberOfAudioFrames;
    
    /** The audio format read from the file, as well as what the queue plays */
    AudioStreamBasicDescription _sourceStreamFormat;
    
    /** Responsible for playback */
    AudioQueueRef _audioQueue;
    
    /** An array of queue buffers */
    AudioQueueBufferRef _buffers[NUM_BUFFERS];
    
    /** The index of the buffer currently being played by the queue */
    int _bufferBeingPlayed;
    
    /** Number of buffers filled */
    int _bufferFillCount;
    
    /** 
     * The reference point used to calculate which buffer to draw from when calculating 
     * the next samples to be played.
     */
    Float64 _startSampleTime;
}

@synthesize isPlaying = _isPlaying;

- (id)init {
    self = [super init];
    
    if (self) {
        _bufferBeingPlayed = 0;
        
        [self openFile];
        [self initAudioQueue];
        [self play];
    }
    
    return self;
}

- (void)openFile {
    OSStatus error = noErr;
   
    // Construct a URL, and open the audio file at that URL

    //!!! BEGIN DEBUG CODE
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Sample" withExtension:@"mp3"];
    error = ExtAudioFileOpenURL((__bridge CFURLRef)url, &_sourceFile);
    //!!! END DEBUG CODE
    
    if (error) {
        NSLog(@"Error opening URL, url=%@ code=%ld", url, error);
        [self closeFile];
        return;
    }
    
    // Get the number of frames contained in the file
    
    _numberOfAudioFrames = 0;
    UInt32 propSize = sizeof(SInt64);
    error = ExtAudioFileGetProperty(_sourceFile, 
                                    kExtAudioFileProperty_FileLengthFrames, 
                                    &propSize, 
                                    &_numberOfAudioFrames);
    
    if(error){
        NSLog(@"AudioClip: Error retreiving number of frames: %ld", error);
        [self closeFile];
        return;
    }
    
    // Create the format used by Extended Audio File Services to decode into
 
    _sourceStreamFormat.mFormatID            = kAudioFormatLinearPCM;
    _sourceStreamFormat.mSampleRate          = 44100;
    _sourceStreamFormat.mFormatFlags         = kAudioFormatFlagsCanonical;
    _sourceStreamFormat.mChannelsPerFrame    = 1;
    _sourceStreamFormat.mBitsPerChannel      = 8 * sizeof(AudioSampleType);
    _sourceStreamFormat.mFramesPerPacket     = 1;
    _sourceStreamFormat.mBytesPerFrame       = sizeof(AudioSampleType);
    _sourceStreamFormat.mBytesPerPacket      = sizeof(AudioSampleType);
    _sourceStreamFormat.mReserved            = 0;

    // Set the format on extended audio file
    
    propSize = sizeof(_sourceStreamFormat);
    error = ExtAudioFileSetProperty(_sourceFile, 
                                    kExtAudioFileProperty_ClientDataFormat, 
                                    propSize, 
                                    &_sourceStreamFormat);
    if (error) {
        NSLog(@"Error setting client data format, code=%ld", error);
        [self closeFile];
        return;
    }
    
}

- (void)closeFile {
    OSStatus error = ExtAudioFileDispose(_sourceFile);
    if (error) {
        NSLog(@"Error closing file, error=%ld", error);
    }
}

- (void)initAudioQueue {

    AudioStreamBasicDescription streamFormat = _sourceStreamFormat;
    OSStatus error = AudioQueueNewOutput(&streamFormat, 
                                         audioQueueOutputCallback, 
                                         (__bridge void *)self, 
                                         nil,
                                         nil,
                                         0,
                                         &_audioQueue);
    if (error) {
        NSLog(@"Error creating new audio queue, error=%ld", error);
        return;
    }
    
    UInt32 enable = 1;
    AudioQueueSetProperty(_audioQueue, kAudioQueueProperty_EnableLevelMetering, &enable, sizeof(enable));
    
    if (error) {
        NSLog(@"Error enabling metering on audio queue, error=%ld", error);
        return;
    }
    
    //!!! Debug code
    AudioQueueSetParameter(_audioQueue, kAudioQueueParam_Volume, 10.0);
    //!!! End debug code
    
    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueBufferRef buffer;
        error = AudioQueueAllocateBuffer(_audioQueue, BYTES_PER_BUFFER, &buffer); 
        
        if (error) {
            NSLog(@"Error allocating queue buffer, error=%ld", error);
            return; // Should be more than just a return
        }
        
        [self fillAndEnqueueBuffer:buffer];
        _buffers[i] = buffer;
    }
}

- (FrameData *)nextSamplesWithLength:(int)length {
    
    // Arg check
    
    assert(length <= FRAMES_PER_BUFFER);

    // Get the current sample time in the audio queue
    
    AudioTimeStamp timestamp;
    Boolean timelineDiscontinuity;
    OSStatus error = AudioQueueGetCurrentTime(_audioQueue, nil, &timestamp, &timelineDiscontinuity);
    
    if (error) {
        NSLog(@"Error getting current time from queue, error=%ld", error);
        return nil;
    }
    
    // Get the metering levels
    
    AudioQueueLevelMeterState levels;
    UInt32 dataSize = sizeof(levels);
    error = AudioQueueGetProperty(_audioQueue, kAudioQueueProperty_CurrentLevelMeter, &levels, &dataSize);
    
    if (error) {
        NSLog(@"Error getting current time from queue, error=%ld", error);
        return nil;
    }
    
    // Calculate how many samples we are into the current buffer
    
    Float64 timePlayedSinceReference = (timestamp.mSampleTime - 2048) - _startSampleTime;
    UInt32 samplesIntoCurrentBuffer = (UInt32) fmod(timePlayedSinceReference, FRAMES_PER_BUFFER);
    UInt32 samplesAvailableFromCurrentBuffer = FRAMES_PER_BUFFER - samplesIntoCurrentBuffer;
        
    // Allocate an appropriately sized buffer for the samples
    
    AudioSampleType *samples = malloc(sizeof(AudioSampleType) * length);
    AudioQueueBufferRef currentBuffer = _buffers[_bufferBeingPlayed];
    
//    [Debug printSInt16Array:currentBuffer->mAudioData
//                 withLength:FRAMES_PER_BUFFER
//                       name:@"buffer"];
    
    // Copy samples into the sample buffer

    if (length > samplesAvailableFromCurrentBuffer) {
        memcpy(samples, 
               ((SInt16 *)currentBuffer->mAudioData) + samplesIntoCurrentBuffer,
               samplesAvailableFromCurrentBuffer * sizeof(AudioSampleType));
        
        UInt32 sampleCountFromNextBuffer = length - samplesAvailableFromCurrentBuffer;
        AudioQueueBufferRef nextBuffer = _buffers[(_bufferBeingPlayed + 1) % 3];
        
        memcpy(samples + samplesAvailableFromCurrentBuffer, 
               nextBuffer->mAudioData, 
               sampleCountFromNextBuffer * sizeof(AudioSampleType));
    } else {
        memcpy(samples, 
               ((SInt16 *)currentBuffer->mAudioData) + samplesIntoCurrentBuffer, 
               length * sizeof(AudioSampleType));
    }
    
    return [[FrameData alloc] initWithSamples:samples 
                                       length:length 
                                   levelState:levels];
}

- (void)fillAndEnqueueBuffer:(AudioQueueBufferRef)buffer {

    UInt32 loadedFrames = buffer->mAudioDataBytesCapacity / sizeof(AudioSampleType);
    
    // Allocate an audio buffer list, and populate it
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = _sourceStreamFormat.mChannelsPerFrame;
    bufferList.mBuffers[0].mData = buffer->mAudioData; // Data is shared with the buffer
    bufferList.mBuffers[0].mDataByteSize = buffer->mAudioDataBytesCapacity;
    
    // Read from the file
    OSStatus error;
    @synchronized(self) {
    error = ExtAudioFileRead(_sourceFile, &loadedFrames, &bufferList);
    }

    if (error) {
        NSLog(@"Error reading audio file, error=%ld", error);
        return;
    }
    
    // TODO If we're finished reading, stop    
    
    // Set the length of the buffer to loaded bytes
    
    buffer->mAudioDataByteSize = loadedFrames * sizeof(AudioSampleType);
    
//    [Debug printSInt16Array:buffer->mAudioData
//                 withLength:loadedFrames
//                       name:@"loaded"];
    
    // Enqueue the buffer
    
    error = AudioQueueEnqueueBuffer(_audioQueue, buffer, 0, nil);
    
    if (error) {
        NSLog(@"Error enqueuing audio buffer, error=%ld", error);
        return;
    }
    
    // Since an enqueue indicates that a buffer has been drained completely,
    // we know that we've progressed to the next buffer.
    
    _bufferBeingPlayed = (_bufferBeingPlayed + 1) % NUM_BUFFERS;
    
    // Increment the total number of buffers we have filled
    
    _bufferFillCount++;
}

- (void)play {
    OSStatus error = AudioQueueStart(_audioQueue, nil);
    _startSampleTime = 0.0;
    _isPlaying = YES;
    
    if (error) {
        NSLog(@"Error starting audio queue, error=%ld", error);
        return;
    }
}

@end
