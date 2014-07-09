//
//  TBSViewController.m
//  TwitterBostonShower
//
//  Created by Vishnu Prem on 7/9/14.
//  Copyright (c) 2014 Twitter. All rights reserved.
//

#import "TBSViewController.h"
#import "MZFayeClient.h"
#import "TheAmazingAudioEngine.h"

#define kBufferLength 2048

@interface TBSViewController ()

@end

@implementation TBSViewController {
    MZFayeClient *client;
    __weak IBOutlet UIView *statusView;
    __weak IBOutlet UISegmentedControl *segmentControl;
    
    NSDictionary *messageDict;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    client = [[MZFayeClient alloc] initWithURL:[NSURL URLWithString:@"http://yo.vishnuprem.com/faye"]];
    
    [client connect];
    
    [client subscribeToChannel:@"/showers" usingBlock:^(NSDictionary *message) {
        if ([message isKindOfClass:[NSDictionary class]]) {
            messageDict = message;
            [self updateViews:nil];
        }
    }];
    
    AEAudioController *controller = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription] inputEnabled:YES];
                                    
     AEFloatConverter *floatConverter = [[AEFloatConverter alloc] initWithSourceFormat:[AEAudioController nonInterleaved16BitStereoAudioDescription]];
    
    AudioBufferList *conversionBuffer = AEAllocateAndInitAudioBufferList(floatConverter.floatingPointAudioDescription, 4096);
                                     
    id<AEAudioReceiver> receiver = [AEBlockAudioReceiver audioReceiverWithBlock:
                                    ^(void                     *source,
                                      const AudioTimeStamp     *time,
                                      UInt32                    frames,
                                      AudioBufferList          *audio) {
                                        // Convert audio
                                        AEFloatConverterToFloatBufferList(floatConverter, audio, conversionBuffer, frames);
                                        
                                        // Get a pointer to the audio buffer that we can advance
                                        float *audioPtr = conversionBuffer->mBuffers[0].mData;
                                        
                                        // Copy in contiguous segments, wrapping around if necessary
                                        int remainingFrames = frames;
                                        while ( remainingFrames > 0 ) {
//                                            int framesToCopy = MIN(remainingFrames, kBufferLength - THIS->_buffer_head);
//                                            
//                                            vDSP_vspdp(audioPtr, 1, THIS->_buffer + THIS->_buffer_head, 1, framesToCopy);
//                                            audioPtr += framesToCopy;
//                                            
//                                            int buffer_head = THIS->_buffer_head + framesToCopy;
//                                            if ( buffer_head == kBufferLength ) buffer_head = 0;
//                                            OSMemoryBarrier();
//                                            THIS->_buffer_head = buffer_head;
//                                            remainingFrames -= framesToCopy;
                                        }
                                    }];
    
    [controller addInputReceiver:receiver];
    
    NSError *error = NULL;
    BOOL result = [controller start:&error];
    if ( !result ) {
        // Report error
    }
}

- (IBAction)updateViews:(id)sender {
    NSArray* left = messageDict[@"left"];
    NSArray* right = messageDict[@"right"];
    
    if (segmentControl.selectedSegmentIndex == 0) {
        [self colorViewWithStatus:left.lastObject[@"status"]];
    } else {
        [self colorViewWithStatus:right.lastObject[@"status"]];
    }
}

- (void)colorViewWithStatus:(NSString*)status {
    if ([status isEqualToString:@"lock"]) {
        statusView.backgroundColor = [UIColor redColor];
    } else if ([status isEqualToString:@"unlock"]) {
        statusView.backgroundColor = [UIColor greenColor];
    }
}

- (IBAction)viewTapped:(id)sender {
    NSString* door;
    NSString* status;
    if (segmentControl.selectedSegmentIndex == 0) {
        door = @"left";
    } else {
        door = @"right";
    }
    if (statusView.backgroundColor == [UIColor redColor]) {
        status = @"unlock";
    } else if(statusView.backgroundColor == [UIColor greenColor]) {
        status = @"lock";
    }
    [client sendMessage:@{@"door": door, @"status": status} toChannel:@"/updates"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
