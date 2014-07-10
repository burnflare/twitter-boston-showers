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
    __weak IBOutlet UIView *lockStatusView;
    __weak IBOutlet UISegmentedControl *segmentControl;
    __weak IBOutlet UILabel *countdownTimerLabel;
    
    CMMotionManager* motionManager;
    NSTimer *yRotationTimer;
    BOOL yRotationFlag;
    
    int secondsToWait;
    
    int countdownTimerValue;
    NSTimer *countdownTimer;
    
    NSDictionary *messageDict;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    client = [[MZFayeClient alloc] initWithURL:[NSURL URLWithString:@"http://yo.vishnuprem.com/faye"]];
    [client subscribeToChannel:@"/showers" usingBlock:^(NSDictionary *message) {
        if ([message isKindOfClass:[NSDictionary class]]) {
            messageDict = message;
            
            
            [self updateFromServer];
        }
    }];
    [client connect];
    
    yRotationFlag = YES;
    secondsToWait = 10;
    
    // This count is used to make sure that we get 5 continious readings > 0.5 before triggering an action
    __block int yRotationCount = 0;
    motionManager = [[CMMotionManager alloc] init];
    [motionManager startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        // If RR.y is > 0.5, we'll detect that as a door open/close
        if (yRotationFlag && fabsf(motion.rotationRate.y) > 0.5) {
            if (yRotationCount <= 5) {
                yRotationCount++;
                return;
            }
            yRotationCount = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self toggleLock];
            });
        } else {
            yRotationCount = 0;
        }
    }];
}

- (void)resetDisabledYRotation {
    [yRotationTimer invalidate];
    yRotationFlag = YES;
}

-(void)decrementCountdown {
    countdownTimerValue--;
    if (countdownTimerValue == 0) {
        [countdownTimer invalidate];
        countdownTimerLabel.text = @"";
    } else {
        countdownTimerLabel.text = [NSString stringWithFormat:@"%d",countdownTimerValue];
    }
}

- (IBAction)segmentValueChanged:(id)sender {
    [countdownTimer invalidate];
    countdownTimerLabel.text = @"";
    
    [self updateLockStatusView];
}

- (void)updateFromServer {
    countdownTimerValue = secondsToWait;
    countdownTimerLabel.text = [NSString stringWithFormat:@"%d",countdownTimerValue];
    
    [countdownTimer invalidate];
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(decrementCountdown) userInfo:nil repeats:YES];
    
    [self updateLockStatusView];
}

- (void)updateLockStatusView {
    NSArray* arr;
    if (segmentControl.selectedSegmentIndex == 0) {
        arr = messageDict[@"left"];
    } else {
        arr = messageDict[@"right"];
    }
    
    if ([arr.lastObject[@"status"] isEqualToString:@"lock"]) {
        lockStatusView.backgroundColor = [UIColor redColor];
    } else if ([arr.lastObject[@"status"] isEqualToString:@"unlock"]) {
        lockStatusView.backgroundColor = [UIColor greenColor];
    }
}

- (void)toggleLock {
    // When we toggle, we want to disable another lock for 10 seconds
    yRotationFlag = NO;
    [yRotationTimer invalidate];
    yRotationTimer = [NSTimer scheduledTimerWithTimeInterval:secondsToWait target:self selector:@selector(resetDisabledYRotation) userInfo:nil repeats:NO];
    
    NSString* door;
    NSString* status;
    if (segmentControl.selectedSegmentIndex == 0) {
        door = @"left";
    } else {
        door = @"right";
    }
    if (lockStatusView.backgroundColor == [UIColor redColor]) {
        status = @"unlock";
    } else if(lockStatusView.backgroundColor == [UIColor greenColor]) {
        status = @"lock";
    }
    [client sendMessage:@{@"door": door, @"status": status} toChannel:@"/updates"];
}

- (IBAction)viewTapped:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Override!"
                                                        message:@"This means that I am out of sync and you're trying to fix me. Is that correct?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Yes", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self toggleLock];
    }
}

@end
