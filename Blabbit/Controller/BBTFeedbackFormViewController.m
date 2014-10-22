//
//  BBTFeedbackFormViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/4/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTFeedbackFormViewController.h"
#import "BBTHTTPManager.h"

// maximum number of characters in feedback message
static const NSUInteger kMaxFeedbackBodyLength = 1000;

@interface BBTFeedbackFormViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation BBTFeedbackFormViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - Target/Action
- (IBAction)submitFeedback:(UIBarButtonItem *)sender
{
    [self.spinner startAnimating];
    NSDictionary *parameters = @{kBBTRESTFeedbackBodyKey: self.textView.text};
    [[BBTHTTPManager sharedManager] request:BBTHTTPMethodPOST
                                     forURL:kBBTRESTFeedbacks
                                 parameters:parameters
                                    success:^(NSURLSessionDataTask *task, id responseObject) {
                                        [self.spinner stopAnimating];
                                        [self.navigationController popViewControllerAnimated:YES];
                                    }
                                    failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                                        [self.spinner stopAnimating];
                                        [self.navigationController popViewControllerAnimated:YES];
                                    }];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    [super textViewDidChange:textView];
    // can only send feedback if you indeed have content
    self.sendButton.enabled = ([textView.text length] > 0);
}

// enforce a maxlength
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if([newText length] <= kMaxFeedbackBodyLength) {
        return YES;
        
    } else {
        // text is too long so truncate
        textView.text = [newText substringToIndex:kMaxFeedbackBodyLength];
        return NO;
    }
}

@end
