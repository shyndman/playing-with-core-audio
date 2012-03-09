//
//  Debug.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-06.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import "Debug.h"

@implementation Debug

+ (void) printSInt16Array:(SInt16 *)arr withLength:(size_t)length name:(NSString *)name {
    for (int i = 0; i < length; i++) 
        NSLog(@"%@[%d] = %d", name, i, arr[i]);
}

+ (void) printFloatArray:(float *)arr withLength:(size_t)length name:(NSString *)name {
    for (int i = 0; i < length; i++) 
        NSLog(@"%@[%d] = %f", name, i, arr[i]);
}

+ (void) printBinnedFloatArray:(float *)arr 
                    withLength:(size_t)length 
                        perBin:(int)perBin 
                          name:(NSString *)name {
    
    for (int i = 0; i < length / perBin; i++) {
        float sum = 0;
        for (int j = 0; j < perBin; j++) 
            sum += arr[i*4+j];
        
        NSLog(@"%@[%d] = %f", name, i, sum);
    }
}

@end
