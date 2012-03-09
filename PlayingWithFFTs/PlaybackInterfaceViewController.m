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
#import "Debug.h"
#import "FrameData.h"

@interface PlaybackInterfaceViewController()
@property (nonatomic, strong) FrameData *frameData;
@end

@implementation PlaybackInterfaceViewController
{
    SongModel *song;

    FrameData *frameData;
    
    //! temp
    float fov;
}

@synthesize frameData = _frameData;

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    song         = [[SongModel alloc] init];
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
    frameData = [song nextSamplesWithLength:1024];
    
    // TODO Add null handling
    
#ifdef LOG_UPDATE
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"Update finished, duration=%lf", executionTime);
#endif
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    size_t len = frameData->numSamples / 4;
    float vertices[3 * len];
    
    for (int i = 0; i < len; i++) {
        vertices[(i * 3) + 0] = i * 4 - 512; // x
        vertices[(i * 3) + 1] = ((frameData->samples[i] + 0.5) / 32767.5) * 400 - 100;
        vertices[(i * 3) + 2] = 0;
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
    glLineWidth(1.5 + 3 * frameData->levelState.mAveragePower);
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
