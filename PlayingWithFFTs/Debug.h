//
//  Debug.h
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-06.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Debug : NSObject
+ (void) printFloatArray:(float *)arr withLength:(size_t)length andName:(NSString *)name;
@end
