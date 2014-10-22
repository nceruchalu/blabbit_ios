//
//  BBTScrollViewContainer.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTScrollViewContainer.h"

@interface BBTScrollViewContainer ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

// property tracks currently active text field
@property (strong, nonatomic) UITextField *activeTextField;

// cached scrollView contentInset (prior to keyboard being shown)
@property (nonatomic) UIEdgeInsets cachedContentInset;

@end

@implementation BBTScrollViewContainer

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // set additional constraints for scroll view's content view that aren't
    // possible via Interface Builder/Storyboards. These are currently placeholders
    // in the storyboard
    // ref: http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:0
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0
                                                                       constant:0];
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:0
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1.0
                                                                        constant:0];
    [self.view addConstraint:rightConstraint];
    
    
    // set input field borders and set VC as its delegate
    for (UITextField *textField in self.inputTextFieldsCollection) {
        textField.delegate = self;
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


#pragma mark - Keyboard Notification handlers
/**
 * Called when the UIKeyboardDidShowNotification is sent.
 *
 * Apple's implementation has a bug such that when you rotate the device to landscape
 * it reports the keyboard as the wrong size as if it was still in portrait mode.
 *
 * This version gets around that by getting the rectangle from the NSNotification object,
 * and transforming the coordinates into the view's coordinate system.
 */
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect fromView:nil];
    CGSize kbSize = kbRect.size;
    
    self.cachedContentInset = self.scrollView.contentInset;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeTextField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeTextField.frame animated:YES];
    }
}

/**
 * Called when the UIKeyboardWillHideNotification is sent
 */
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = self.cachedContentInset; //UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}


#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeTextField = nil;
}


#pragma mark - Target/Action methods
- (IBAction)backgroundTapped:(id)sender {
    // force view to resignFirstResponder status
    [self.view endEditing:YES];
}


@end
