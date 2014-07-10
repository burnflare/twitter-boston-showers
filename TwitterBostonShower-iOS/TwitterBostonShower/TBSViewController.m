//
//  TBSViewController.m
//  TwitterBostonShower
//
//  Created by Vishnu Prem on 7/9/14.
//  Copyright (c) 2014 Twitter. All rights reserved.
//

#import "TBSViewController.h"
#import "MZFayeClient.h"
#import <CoreMotion/CoreMotion.h>

@interface TBSViewController ()

@end

@implementation TBSViewController {
    MZFayeClient *client;
    __weak IBOutlet UIView *statusView;
    __weak IBOutlet UISegmentedControl *segmentControl;
    __weak IBOutlet UILabel *numberLabel;
    
    CMMotionManager* mm;
    NSTimer *rotationTimer;
    BOOL yRotationFlag;
    
    int secondsToWait;
    int secondsTimerVal;
    NSTimer *secondsTimer;
    
    NSDictionary *messageDict;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    client = [[MZFayeClient alloc] initWithURL:[NSURL URLWithString:@"http://yo.vishnuprem.com/faye"]];
    [client subscribeToChannel:@"/showers" usingBlock:^(NSDictionary *message) {
        if ([message isKindOfClass:[NSDictionary class]]) {
            messageDict = message;
            [self lockStatusChanged];
        }
    }];
    [client connect];
    
    yRotationFlag = YES;
    secondsToWait = 10;
    
    mm = [[CMMotionManager alloc] init];
    
    [mm startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        if (yRotationFlag && fabsf(motion.rotationRate.y) > 0.5) {
            dispatch_async(dispatch_get_main_queue(), ^{
                yRotationFlag = NO;
                [rotationTimer invalidate];
                rotationTimer = [NSTimer scheduledTimerWithTimeInterval:secondsToWait target:self selector:@selector(resetRotation) userInfo:nil repeats:NO];
                
                [self toggleStatus];
            });
        }
    }];
}

- (void)resetRotation {
    [rotationTimer invalidate];
    yRotationFlag = YES;
}

-(void)updateSeconds {
    secondsTimerVal--;
    if (secondsTimerVal == 0) {
        [self resetSeconds];
    } else {
        numberLabel.text = [NSString stringWithFormat:@"%d",secondsTimerVal];
    }
}

- (void)resetSeconds {
    [secondsTimer invalidate];
    numberLabel.text = @"";
}

- (IBAction)segmentValueChanged:(id)sender {
    [secondsTimer invalidate];
    numberLabel.text = @"";
    
    [self updateBoxView];
}

- (void)lockStatusChanged {
    secondsTimerVal = secondsToWait;
    numberLabel.text = [NSString stringWithFormat:@"%d",secondsTimerVal];
    
    [secondsTimer invalidate];
    secondsTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateSeconds) userInfo:nil repeats:YES];
    
    [self updateBoxView];
}

- (void)updateBoxView {
    NSArray* arr;
    if (segmentControl.selectedSegmentIndex == 0) {
        arr = messageDict[@"left"];
    } else {
        arr = messageDict[@"right"];
    }
    
    if ([arr.lastObject[@"status"] isEqualToString:@"lock"]) {
        statusView.backgroundColor = [UIColor redColor];
    } else if ([arr.lastObject[@"status"] isEqualToString:@"unlock"]) {
        statusView.backgroundColor = [UIColor greenColor];
    }
}

- (void)toggleStatus {
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

- (IBAction)viewTapped:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Override!"
                                                        message:@"Are you sure I am out of sync and you want me to toggle this shower's status?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Yes", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self toggleStatus];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
