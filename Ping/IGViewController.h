//
//  IGViewController.h
//  Ping
//
//  Created by Zhu Xiaojing on 13-4-19.
//  Copyright (c) 2013年 Igniter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IGPingOperation.h"

@interface IGViewController : UIViewController <IGPingOperationDelegate>

- (IBAction)pingPressed:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *pingButton;

@property (strong, nonatomic) IBOutlet UITextField *hostField;
@property (strong, nonatomic) IBOutlet UITextView *resutField;
@end
