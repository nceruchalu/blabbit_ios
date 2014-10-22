//
//  BBTTextViewContainer.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/4/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTTextViewContainer.h"

@interface BBTTextViewContainer ()

@end

@implementation BBTTextViewContainer

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // want keyboard to show up immediately
    [self.textView becomeFirstResponder];
    self.textView.delegate = self;
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


#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    [self showTextViewCaretPosition:textView];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    [self showTextViewCaretPosition:textView];
}

#pragma mark Helper
- (void)showTextViewCaretPosition:(UITextView *)textView
{
    CGRect caretRect = [textView caretRectForPosition:textView.selectedTextRange.end];
    [textView scrollRectToVisible:caretRect animated:NO];
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
    
    UIEdgeInsets contentInsets = self.textView.contentInset;
    contentInsets.bottom = kbSize.height;
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
}

/**
 * Called when the UIKeyboardWillHideNotification is sent
 */
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = self.textView.contentInset;
    contentInsets.bottom = 0;
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
}

@end
