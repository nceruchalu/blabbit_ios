//
//  UIView+Borders.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * The Borders category makes it possible to add single-sided borders to any
 * UIView instance.
 */
@interface UIView (Borders)

/**
 * add a top border of given height and color to a UIView instance
 * 
 * @param height    border height
 * @param color     border color
 */
- (void)addTopBorderWithHeight:(CGFloat)height andColor:(UIColor *)color;

/**
 * add a bottom border of given height and color to a UIView instance
 *
 * @param height    border height
 * @param color     border color
 */
- (void)addBottomBorderWithHeight:(CGFloat)height andColor:(UIColor *)color;

/**
 * add a left border of given width and color to a UIView instance
 *
 * @param width     border width
 * @param color     border color
 */
- (void)addLeftBorderWithWidth:(CGFloat)width andColor:(UIColor *)color;

/**
 * add a right border of given width and color to a UIView instance
 *
 * @param width     border width
 * @param color     border color
 */
- (void)addRightBorderWithWidth:(CGFloat)width andColor:(UIColor *)color;

@end
