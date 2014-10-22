//
//  BBTCredentialsViewController.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTScrollViewContainer.h"

/**
 * BBTCredentialsViewController is the root class for the SignIn, SignUp and
 * ForgotPassword ViewControllers. It ensures they have the same functionality
 * and theme.
 *
 * @warning: This class is not very useful if not subclassed
 */
@interface BBTCredentialsViewController : BBTScrollViewContainer

#pragma mark - Instance methods
/**
 * Called to setup view with default configurations like background color.
 * Override as desired
 */
- (void)setupViewConfigurations;

/**
 * Show an alert with given title and message.
 * The alert has only a cancel button with fixed text "OK".
 *
 * @param title     alert view title
 * @param message   alert view message
 */
- (void)alertWithTitle:(NSString *)title message:(NSString *)message;

/**
 * Setup to be done at the beginning of the Target-Action method for the mainButton.
 */
- (void)startPerformMainAction;

/**
 * Method should be called after main action is performed.
 *
 * @see performMainAction
 */
- (void)endPeformMainAction;

#pragma mark Abstract
/**
 * method is called when main action button is tapped.
 * When your main action is done be sure to call `endPerformMainAction`
 *
 * @see endPerformMainAction
 */
- (void)performMainAction;

@end
