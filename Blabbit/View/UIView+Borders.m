//
//  UIView+Borders.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "UIView+Borders.h"

@implementation UIView (Borders)

#pragma mark - Private methods
/**
 * add a border to one side of a UIView using a given frame
 * 
 * @param frame     border frame
 * @param color     border color
 */
- (void)addOneSidedBorderWithFrame:(CGRect)frame andColor:(UIColor *)color
{
    CALayer *border = [CALayer layer];
    border.frame = frame;
    border.backgroundColor = color.CGColor;
    [self.layer addSublayer:border];
}

#pragma mark - Public methods
- (void)addTopBorderWithHeight:(CGFloat)height andColor:(UIColor *)color
{
    [self addOneSidedBorderWithFrame:CGRectMake(0, 0, self.frame.size.width, height)
                            andColor:color];
}

- (void)addBottomBorderWithHeight:(CGFloat)height andColor:(UIColor *)color
{
    [self addOneSidedBorderWithFrame:CGRectMake(0, self.frame.size.height-height, self.frame.size.width, height)
                            andColor:color];
}

- (void)addLeftBorderWithWidth:(CGFloat)width andColor:(UIColor *)color
{
    [self addOneSidedBorderWithFrame:CGRectMake(0, 0, width, self.frame.size.height)
                            andColor:color];
}

- (void)addRightBorderWithWidth:(CGFloat)width andColor:(UIColor *)color
{
    [self addOneSidedBorderWithFrame:CGRectMake(self.frame.size.width-width, 0, width, self.frame.size.height)
                            andColor:color];
}

@end
