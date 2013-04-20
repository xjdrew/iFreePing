//
//  IGViewController.m
//  Ping
//
//  Created by Zhu Xiaojing on 13-4-19.
//  Copyright (c) 2013年 Igniter. All rights reserved.
//

#import "IGViewController.h"

@interface IGViewController ()
@property (strong, nonatomic) IGPingOperation* pingOperation;
@end

@implementation IGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.pingButton setTitle:@"Ping" forState:UIControlStateNormal];
    [self.pingButton setTitle:@"Stop" forState:UIControlStateHighlighted];
    
    self.resutField.text = @"";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)log:(NSString*)str {
	self.resutField.text = [NSString stringWithFormat:@"%@%@\n", self.resutField.text, str];
	NSLog(@"%@", str);
}

- (IBAction)pingPressed:(id)sender {
    [self.hostField resignFirstResponder];
    if (self.pingOperation) {
        [self.pingOperation stop];
    } else {
        self.pingOperation = [IGPingOperation makePingOperation:self.hostField.text delegate:self];
        [self.pingOperation start];
    }
}

#pragma IGOperationDelegate protocal
-(void) operation:(IGPingOperation *)operation start:(IGPingStartResult *) result {
    if (result.error) {
        NSLog(@"startup error: %@", result.error);
        self.pingOperation = nil;
    } else {
        [self.pingButton setHighlighted:YES];
    }
    [self log:[result description]];
}

-(void) operation:(IGPingOperation *)operation pingResult:(IGPingResult *)result {
    [self log:[result description]];
}

-(void) operation:(IGPingOperation *)operation stop:(IGPingStopResult *)result {
    [self log:@"-------- ping statistics --------"];
    [self log:[result description]];
    [self log:@"-------------- end --------------"];
    [self.pingButton setHighlighted:NO];
    self.pingOperation = nil;
}
@end
