//
//  BBTResetPasswordViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/19/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTResetPasswordViewController.h"
#import "BBTHTTPManager.h"
#import "BBTUtilities.h"

@interface BBTResetPasswordViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@end

@implementation BBTResetPasswordViewController

#pragma mark - Instance methods
#pragma mark Private
/**
 * Start password recovery process
 */
- (void)recoverPassword
{
    NSString *email = self.emailTextField.text;
    
    if (![BBTUtilities validateEmail:email]){
        // validate the email .
        [self alertWithTitle:@"Email is invalid"
                     message:@"That email didn't seem to work."];
        
        [self endPeformMainAction];
        
    } else {
        BBTHTTPManager *manager = [BBTHTTPManager sharedManager];
        NSDictionary *parameters = @{kBBTRESTUserEmailKey : email};
        
        [manager request:BBTHTTPMethodPOST
                  forURL:kBBTRESTPasswordReset
              parameters:parameters
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     [self handleRecoverPasswordResponse];
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     [self handleRecoverPasswordResponse];
                 }
         ];
    }
}

#pragma mark Private Helpers (of recoverPassword)
/**
 * Handle server response for a password recovery. Use the same response for
 * both a successful or failed request. It could be a security hole if you reveal
 * an email doesn't exist on the server.
 */
- (void)handleRecoverPasswordResponse
{
    // alert user of the error
    [self alertWithTitle:@"Reset instructions sent"
                 message:@"Check your email for more."];
    [self endPeformMainAction];
}

#pragma mark Public (Concrete)
- (void)performMainAction
{
    [self recoverPassword];
}


@end
