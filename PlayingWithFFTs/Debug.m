//
//  Debug.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-06.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import "Debug.h"

@implementation Debug

+ (void) printFloatArray:(float *)arr withLength:(size_t)length andName:(NSString *)name {
    for (int i = 0; i < length; i++) 
        NSLog(@"%@[%d] = %f", name, i, arr[i]);
}

@end
