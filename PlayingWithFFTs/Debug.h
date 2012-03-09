//
//  Debug.h
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-06.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Debug : NSObject
+ (void) printSInt16Array:(SInt16 *)arr withLength:(size_t)length name:(NSString *)name;
+ (void) printFloatArray:(float *)arr withLength:(size_t)length name:(NSString *)name;
+ (void) printBinnedFloatArray:(float *)arr 
                    withLength:(size_t)length 
                        perBin:(int)perBin 
                       name:(NSString *)name;
@end
