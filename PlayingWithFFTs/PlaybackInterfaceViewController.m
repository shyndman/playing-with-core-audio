//
//  PlaybackInterfaceViewController.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-06.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "PlaybackInterfaceViewController.h"
#import "SongModel.h"
#import "SongAnalyzer.h"
#import "Debug.h"

@implementation PlaybackInterfaceViewController
{
    SongModel *song;
    SongAnalyzer *analyzer;

    //! temp
    float fov;
    
    //! temp
    FrequencyData *freqData; 
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    song         = [[SongModel alloc] init];
    analyzer     = [[SongAnalyzer alloc] initWithSong:song fftBits:10];
    fov          = GLKMathDegreesToRadians(65);
    
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:context];
    self.preferredFramesPerSecond = 30;
    
    GLKView *glView = (GLKView *)self.view;
    glView.context = context; // Required to start the view drawing
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Updating and drawing the view

- (void)update {
#ifdef LOG_UPDATE
    NSDate *methodStart = [NSDate date];
#endif
    
    // FFT based on current time
    freqData = [analyzer analyze];
    
#ifdef LOG_UPDATE
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"Update finished, duration=%lf", executionTime);
#endif
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
//    size_t len = freqData->frequencyMagnitudesLength;
    size_t len = freqData->sourceSignalLength / 8;
    float vertices[3 * len];
    
//    for (int i = 1; i < len; i++) {
//        vertices[((i - 1) * 3) + 0] = i * 2 - 512; // x
//        vertices[((i - 1) * 3) + 1] = freqData->frequencyMagnitudes[i - 1] * 0.1 - 200;
//        vertices[((i - 1) * 3) + 2] = 0;
//         
////        NSLog(@"vertex[%d].z = %lf", i, freqData->frequencyMagnitudes[i] * 0.02);
//    }

    for (int i = 0; i < len; i++) {
        vertices[(i * 3) + 0] = i * 8 - 512; // x
        vertices[(i * 3) + 1] = freqData->sourceSignal[i] * 400 - 200;
        vertices[(i * 3) + 2] = 0;
        
//        NSLog(@"vertex[%d].z = %lf", i, freqData->sourceSignal[i]);
    }

    
    glClearColor(0.1, 0, 0.1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    GLKBaseEffect *effect = [[GLKBaseEffect alloc] init];
    
    // Move the perspective back 5 units
    GLKMatrix4 modelview = GLKMatrix4MakeTranslation(0, 0, -1500.0f);
    effect.transform.modelviewMatrix = modelview;
    
    // Set up a projection matrix
    GLfloat aspectRatio = self.view.bounds.size.width / self.view.bounds.size.height;
    effect.transform.projectionMatrix = GLKMatrix4MakePerspective(
        fov, aspectRatio, 0.1f, 10000.0f);
    [effect prepareToDraw];

    // Draw!
    glLineWidth(2);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 
                          3, // Number of components per vertex
                          GL_FLOAT, GL_FALSE, 0, &vertices);
    glDrawArrays(GL_LINE_STRIP, 0, 
                 len); // Number of indices to render
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
}

#pragma mark - Device memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
