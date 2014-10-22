//
//  BBTSignUpViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/19/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTSignUpViewController.h"
#import "BBTHTTPManager.h"
#import "BBTUtilities.h"
#import "TTTAttributedLabel.h"


@interface BBTSignUpViewController () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *termsAndPrivacyLabel;

@end

@implementation BBTSignUpViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup hyperlinks in terms and privacy label
    self.termsAndPrivacyLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.termsAndPrivacyLabel.delegate = self;
    
    NSRange termsRange = [self.termsAndPrivacyLabel.text rangeOfString:@"Terms of Service"];
    [self.termsAndPrivacyLabel addLinkToURL:[NSURL URLWithString:@"http://blabb.it/terms/"] withRange:termsRange];
    
    NSRange privacyRange = [self.termsAndPrivacyLabel.text rangeOfString:@"Privacy Policy"];
    [self.termsAndPrivacyLabel addLinkToURL:[NSURL URLWithString:@"http://blabb.it/privacy/"] withRange:privacyRange];
}

#pragma mark - Instance methods
#pragma mark Private
/**
 * Register user with server
 */
- (void)registerUser
{
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    NSString *email = self.emailTextField.text;
    
    if ([self validateUsername:username password:password email:email]) {
        
        BBTHTTPManager *manager = [BBTHTTPManager sharedManager];
        NSDictionary *parameters = @{kBBTRESTUserUsernameKey : username,
                                     kBBTRESTUserPasswordKey : password,
                                     kBBTRESTUserEmailKey    : email};
        
        [manager request:BBTHTTPMethodPOST
               forURL:kBBTRESTUsers
           parameters:parameters
              success:^(NSURLSessionDataTask *task, id responseObject) {
                  [self handleRegistrationSuccessOfUser:username withPassword:password];
              }
              failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                  [self handleRegistrationFailure:responseObject];
              }
         ];
        
    }
}

#pragma mark Private Helpers (of registerUser)
/**
 * Validate sign up form fields. If there is any error inform user immediately
 *
 * @param username  user's username
 * @param password  user's password
 * @param email     user's email address
 *
 * @return BOOL indicating if all fields are valid. YES means all good!
 */
- (BOOL)validateUsername:(NSString *)username
                password:(NSString *)password
                   email:(NSString *)email
{
    BOOL allFieldsValid = NO;
    
    if ([username length] < kBBTMinUsernameLength) {
        // username is a required field with minimum length
        [self alertWithTitle:@"Username too short"
                     message:[NSString stringWithFormat:@"%lu characters or more please.", (unsigned long)kBBTMinUsernameLength]];
        
    } else if ([password length] < kBBTMinPasswordLength) {
        // password is a required field with minimum length
        [self alertWithTitle:@"Password too short"
                     message:[NSString stringWithFormat:@"%lu characters or more please.", (unsigned long)kBBTMinPasswordLength]];
        
    } else if ([email length] && ![BBTUtilities validateEmail:email]){
        // if the optional email is present, ensure it's valid.
        [self alertWithTitle:@"Email is invalid"
                     message:@"That email didn't seem to work."];
        
    } else {
        // if we got here then there are no client-side issues.
        allFieldsValid = YES;
    }
    
    // if there's an error then the sign up action is done
    if (!allFieldsValid) [self endPeformMainAction];
    
    return allFieldsValid;
}

/**
 * Handle successful registration
 *
 * @param username  user's username
 * @param password  user's password
 */
- (void)handleRegistrationSuccessOfUser:(NSString *)username
                           withPassword:(NSString *)password
{
    // successfully registered, now authenticate the user
    BBTHTTPManager *manager = [BBTHTTPManager sharedManager];
    [manager authenticateUsername:username
                         password:password
                          success:^{
                              // close this modal
                              [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                              [self endPeformMainAction];
                          }
                          failure:^{
                              // alert user of the error
                              [self alertWithTitle:@"Couldn't sign in"
                                           message:@"That username and password didn't seem to work."];
                              [self endPeformMainAction];
                          }
     ];
}

/**
 * Handle failed registration
 *
 * @param responseObject    HTTP response object from failed response
 */
- (void)handleRegistrationFailure:(id)responseObject
{
    // alert user of any error and include any responseObject data
    [BBTHTTPManager alertWithFailedResponse:responseObject withAlternateTitle:@"Couldn't sign up" andMessage:@"That username and password didn't seem to work."];
    
    [self endPeformMainAction];
}

#pragma mark Public (Concrete)
- (void)performMainAction
{
    [self registerUser];
}

#pragma mark - TTTAttributedLabelDelegate
/**
 Tells the delegate that the user did select a link to a URL.
 
 @param label The label whose link was selected.
 @param url The URL for the selected link.
 */
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}


@end
