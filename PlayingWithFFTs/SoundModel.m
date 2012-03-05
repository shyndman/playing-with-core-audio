//
//  SoundModel.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-04.
//

#import <AudioToolbox/AudioToolbox.h>
#import "SoundModel.h"


#define NUM_BUFFERS         3
#define FRAMES_PER_BUFFER   4096
#define BYTES_PER_BUFFER    FRAMES_PER_BUFFER * sizeof(AudioSampleType)

/********************
 * Private interface
 *******************/

@interface SoundModel() 
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
    SoundModel *model = (__bridge SoundModel *)inUserData;
    [model fillAndEnqueueBuffer:inBuffer];
}
     

/*****************
 * Implementation
 ****************/

@implementation SoundModel
{
    ExtAudioFileRef sourceFile;
    SInt64 numberOfAudioFrames;
    AudioStreamBasicDescription sourceStreamFormat;
    
    /** Responsible for playback */
    AudioQueueRef audioQueue;
    
    /** An array of queue buffers */
    AudioQueueBufferRef buffers[NUM_BUFFERS];
}

- (id)init {
    self = [super init];
    
    if (self) {
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
    error = ExtAudioFileOpenURL((__bridge CFURLRef)url, &sourceFile);
    //!!! END DEBUG CODE
    
    if (error) {
        NSLog(@"Error opening URL, url=%@ code=%ld", url, error);
        [self closeFile];
        return;
    }
    
    // Get the number of frames contained in the file
    
    numberOfAudioFrames = 0;
    UInt32 propSize = sizeof(SInt64);
    error = ExtAudioFileGetProperty(sourceFile, 
                                    kExtAudioFileProperty_FileLengthFrames, 
                                    &propSize, 
                                    &numberOfAudioFrames);
    
    if(error){
        NSLog(@"AudioClip: Error retreiving number of frames: %ld", error);
        [self closeFile];
        return;
    }
    
    // Create the format used by Extended Audio File Services to decode into

    memset(&sourceStreamFormat, 0, sizeof(sourceStreamFormat)); // Zero it

    sourceStreamFormat.mFormatID            = kAudioFormatLinearPCM;
    sourceStreamFormat.mSampleRate          = 44100;
    sourceStreamFormat.mFormatFlags         = kAudioFormatFlagsCanonical;
    sourceStreamFormat.mChannelsPerFrame    = 1;
    sourceStreamFormat.mBitsPerChannel      = 8 * sizeof(AudioSampleType);
    sourceStreamFormat.mFramesPerPacket     = 1;
    sourceStreamFormat.mBytesPerFrame       = sizeof(AudioSampleType);
    sourceStreamFormat.mBytesPerPacket      = sizeof(AudioSampleType);
    sourceStreamFormat.mReserved            = 0;

    // Set the format on extended audio file
    
    propSize = sizeof(sourceStreamFormat);
    error = ExtAudioFileSetProperty(sourceFile, 
                                    kExtAudioFileProperty_ClientDataFormat, 
                                    propSize, 
                                    &sourceStreamFormat);
    if (error) {
        NSLog(@"Error setting client data format, code=%ld", error);
        [self closeFile];
        return;
    }
    
}

- (void)closeFile {
    OSStatus error = ExtAudioFileDispose(sourceFile);
    if (error) {
        NSLog(@"Error closing file, error=%ld", error);
    }
}

- (void)initAudioQueue {

    AudioStreamBasicDescription streamFormat = sourceStreamFormat;
    OSStatus error = AudioQueueNewOutput(&streamFormat, 
                                         audioQueueOutputCallback, 
                                         (__bridge void *)self, 
                                         nil,
                                         nil,
                                         0,
                                         &audioQueue);
    if (error) {
        NSLog(@"Error creating new audio queue, error=%ld", error);
        return;
    }
    
    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueBufferRef buffer;
        error = AudioQueueAllocateBuffer(audioQueue, BYTES_PER_BUFFER, &buffer); 
        
        if (error) {
            NSLog(@"Error allocating queue buffer, error=%ld", error);
            return; // Should be more than just a return
        }
        
        [self fillAndEnqueueBuffer:buffer];
        buffers[i] = buffer;
    }
}

- (void)fillAndEnqueueBuffer:(AudioQueueBufferRef)buffer {

    UInt32 loadedFrames = buffer->mAudioDataBytesCapacity / sizeof(AudioSampleType);
    
    // Allocate an audio buffer list, and populate it
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = sourceStreamFormat.mChannelsPerFrame;
    bufferList.mBuffers[0].mData = buffer->mAudioData; // Data is shared with the buffer
    bufferList.mBuffers[0].mDataByteSize = buffer->mAudioDataBytesCapacity;
    
    // Read from the file
    
    OSStatus error = ExtAudioFileRead(sourceFile, &loadedFrames, &bufferList);
    
    if (error) {
        NSLog(@"Error reading audio file, error=%ld", error);
        return;
    }
    
    // Set the length of the buffer to loadedBytes
    
    buffer->mAudioDataByteSize = loadedFrames * sizeof(AudioSampleType);
    
    // Enqueue the buffer
    
    error = AudioQueueEnqueueBuffer(audioQueue, buffer, 0, nil);
    
    if (error) {
        NSLog(@"Error enqueuing audio buffer, error=%ld", error);
        return;
    }
}

- (void)play {
    OSStatus error = AudioQueueStart(audioQueue, nil);
    
    if (error) {
        NSLog(@"Error starting audio queue, error=%ld", error);
        return;
    }
}



@end
