//
//  PlaybackInterfaceViewController.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-06.
//  Copyright (c) 2012 Blu Trumpet. All rights reserved.
//

#import "PlaybackInterfaceViewController.h"
#import "SongModel.h"
#import "SongAnalyzer.h"

@implementation PlaybackInterfaceViewController
{
    SongModel *song;
    SongAnalyzer *analyzer;
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    song         = [[SongModel alloc] init];
    analyzer     = [[SongAnalyzer alloc] initWithSong:song fftBits:10];
    
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:context];
    
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
    NSDate *methodStart = [NSDate date];
    
    [analyzer analyze];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
//    NSLog(@"update finished, duration=%lf", executionTime);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0, 0, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);

}

#pragma mark - Device memory management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end
