//
//  TBSViewController.m
//  TwitterBostonShower
//
//  Created by Vishnu Prem on 7/9/14.
//  Copyright (c) 2014 Twitter. All rights reserved.
//

#import "TBSViewController.h"
#import "MZFayeClient.h"

@interface TBSViewController ()

@end

@implementation TBSViewController {
    MZFayeClient *client;
    __weak IBOutlet UIView *statusView;
    __weak IBOutlet UISegmentedControl *segmentControl;
    
    NSDictionary *messageDict;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    client = [[MZFayeClient alloc] initWithURL:[NSURL URLWithString:@"http://yo.vishnuprem.com/faye"]];
    
    [client connect];
    
    [client subscribeToChannel:@"/showers" usingBlock:^(NSDictionary *message) {
        if ([message isKindOfClass:[NSDictionary class]]) {
            messageDict = message;
            [self updateViews:nil];
        }
    }];
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
