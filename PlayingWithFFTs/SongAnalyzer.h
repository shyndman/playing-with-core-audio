//
//  SongAnalyzer.h
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-05.
//

#import <Foundation/Foundation.h>
#import "SongModel.h"

@interface SongAnalyzer : NSObject

- (id)initWithSong:(SongModel *)songModel
           fftBits:(short)numberOfBits;

- (void)analyze;

@end
