//
//  SoundModel.h
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-04.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "FrameData.h"

@interface SongModel : NSObject

/** 
 * YES is the song is playing, or NO otherwise.
 */
@property (nonatomic) BOOL isPlaying;

/** 
 * Initializes the SongModel.
 */
- (id)init;

/** 
 * Returns an array of samples about to be played, based on the current playback time. The
 * samples returned are in linear PCM format, 44.1kHz, 16 bit depth.
 *
 * @param length The number of desired audio samples to read.
 */
- (FrameData *)nextSamplesWithLength:(int)length;

@end
