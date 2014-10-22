//
//  BBTChangePasswordViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/6/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTChangePasswordViewController.h"
#import "BBTHTTPManager.h"

@interface BBTChangePasswordViewController ()

@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *changedPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;

@end

@implementation BBTChangePasswordViewController

#pragma mark - Instance methods
#pragma mark Private
/**
 * Start password recovery process
 */
- (void)changePassword
{
    NSString *oldPassword = self.oldPasswordTextField.text;
    NSString *newPassword = self.changedPasswordTextField.text;
    NSString *confirmPassword = self.confirmPasswordTextField.text;

    if (1){//[self validateOldPassword:oldPassword newPassword:newPassword confirmPassword:confirmPassword]) {
        
        BBTHTTPManager *manager = [BBTHTTPManager sharedManager];
        NSDictionary *parameters = @{kBBTRESTPasswordChangeOldKey     : oldPassword,
                                     kBBTRESTPasswordChangeNewKey     : newPassword,
                                     kBBTRESTPasswordChangeConfirmKey : confirmPassword};
        
        [manager request:BBTHTTPMethodPOST
                  forURL:kBBTRESTPasswordChange
              parameters:parameters
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     // update saved user password
                     [BBTHTTPManager sharedManager].password = newPassword;
                     
                     [self endPeformMainAction];
                     
                     // close this page
                     [self.navigationController popViewControllerAnimated:YES];
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     [BBTHTTPManager alertWithFailedResponse:responseObject withAlternateTitle:@"Couldn't update password" andMessage:@"Those passwords didn't seem to work."];
                     [self endPeformMainAction];
                     
                 }
         ];
        
    }
}

#pragma mark Private Helpers (of changePassword)
/**
 * Validate password change form fields. If there is any error inform user immediately
 *
 * @param oldPassword       old password
 * @param newPassword       new password
 * @param confirmPassword   confirmation of new password
 *
 * @return BOOL indicating if all fields are valid. YES means all good!
 */
- (BOOL)validateOldPassword:(NSString *)oldPassword
                newPassword:(NSString *)newPassword
            confirmPassword:(NSString *)confirmPassword
{
    BOOL allFieldsValid = NO;
    
    if ([oldPassword length] < kBBTMinPasswordLength) {
        // old password is a required field with minimum length
        [self alertWithTitle:@"Old Password too short"
                     message:[NSString stringWithFormat:@"%lu characters or more please.", (unsigned long)kBBTMinPasswordLength]];
        
    } else if ([newPassword length] < kBBTMinPasswordLength) {
        // new password is a required field with minimum length
        [self alertWithTitle:@"New Password too short"
                     message:[NSString stringWithFormat:@"%lu characters or more please.", (unsigned long)kBBTMinPasswordLength]];
        
    } else if (![confirmPassword isEqualToString:newPassword]) {
        // new password is a required field with minimum length
        [self alertWithTitle:@"Password mismatch"
                     message:@"New passwords must match."];
        
    } else {
        // if we got here then there are no client-side issues.
        allFieldsValid = YES;
    }
    
    // if there's an error then the sign up action is done
    if (!allFieldsValid) [self endPeformMainAction];
    
    return allFieldsValid;
}

#pragma mark Public (Overrides)
- (void)setupViewConfigurations
{
    // don't need background and textfield setup by parent class
    return;
}

#pragma mark Public (Concrete)

- (void)performMainAction
{
    [self changePassword];
}

@end
