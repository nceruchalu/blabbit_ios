//
//  BBTFixedOrientationNVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/18/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTFixedOrientationNVC.h"

@interface BBTFixedOrientationNVC ()

@end

@implementation BBTFixedOrientationNVC

#pragma mark - Orientation
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
