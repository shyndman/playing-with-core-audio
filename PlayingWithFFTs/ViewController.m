//
//  ViewController.m
//  PlayingWithFFTs
//
//  Created by Scott Hyndman on 12-03-04.
//

#import "ViewController.h"
#import "SongModel.h"
#import "SongAnalyzer.h"

@implementation ViewController
{
    SongModel *song;
    SongAnalyzer *analyzer;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    song     = [[SongModel alloc] init];
    analyzer = [[SongAnalyzer alloc] initWithSong:song 
                                           fftBits:10];
}

- (IBAction)analyze:(id)sender {
    [analyzer analyze];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
