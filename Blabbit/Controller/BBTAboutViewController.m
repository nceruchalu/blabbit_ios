//
//  BBTAboutViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/4/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTAboutViewController.h"

@interface BBTAboutViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation BBTAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    self.versionLabel.text = [NSString stringWithFormat:@"VERSION: %@", version];
}

@end
