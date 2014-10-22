//
//  BBTSignInViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/18/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTSignInViewController.h"
#import "KeychainItemWrapper.h"
#import "BBTHTTPManager.h"
#import "BBTAppDelegate.h"

@interface BBTSignInViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *skipAheadButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@end

@implementation BBTSignInViewController


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // populate username/password fields if these are saved. The reason for this
    // is the sign in VC could be showing because there was a server connection
    // issue during authentication. Not a good user experience to have to re-enter
    // all info because of this. What this means is we clear out the cached
    // username and password on signout/signup/new credential entry.
    self.usernameTextField.text = [BBTHTTPManager sharedManager].username;
    self.passwordTextField.text = [BBTHTTPManager sharedManager].password;
    
    
}

/** Hide the navigationController on only the root view controller.
 *  This combination of viewWillAppear: and viewWillDisappear will cause the
 *  navigation bar to animate in from the left (together with the next view)
 *  when you push the next UIViewController on the stack, and animate away to the 
 *  left (together with the old view), when you press the back button on the
 *  UINavigationBar.
 */
- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // silently attempt signing user in if possible
    [self startPerformMainAction];
    [[BBTHTTPManager sharedManager] authenticateWithSuccess:^{
        // close this modal
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        [self endPeformMainAction];
    } failure:^{
        [self endPeformMainAction];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewWillDisappear:animated];
}


#pragma mark - Instance methods
#pragma mark Private
/**
 * Authenticate user with server
 */
- (void)authenticateUser
{
    // both fields are required so check that and warn user
    if (([self.usernameTextField.text length] == 0) ||
        ([self.passwordTextField.text length] == 0)) {
        
        [self alertWithTitle:@"Enter valid credentials"
                     message:@"Both fields are mandatory."];
        [self endPeformMainAction];
        
    } else {
        BBTHTTPManager *manager = [BBTHTTPManager sharedManager];
        [manager authenticateUsername:self.usernameTextField.text
                             password:self.passwordTextField.text
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
}

/**
 * Have the app start off in a "reset" state by popping all Navigation View 
 * Controllers to root view controller
 */
- (void)resetApplication
{
    BBTAppDelegate *appDelegate = (BBTAppDelegate *)[UIApplication sharedApplication].delegate;
    UITabBarController *tabBarController = (UITabBarController *)(appDelegate.window.rootViewController);
    for (UIViewController *vc in tabBarController.viewControllers) {
        if ([vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nvc = (UINavigationController *)vc;
            [nvc popToRootViewControllerAnimated:NO];
        }
    }
}


#pragma mark Public (Concrete)
- (void)performMainAction
{
    // authenticate user
    [self authenticateUser];
    
    // Since we are (re)authenticating now is a good time to reset the application.
    [self resetApplication];
}

#pragma mark overrides
- (void)startPerformMainAction
{
    [super startPerformMainAction];
    self.signUpButton.enabled = NO;
    self.skipAheadButton.enabled = NO;
    self.forgotPasswordButton.enabled = NO;
}

- (void)endPeformMainAction
{
    [super endPeformMainAction];
    self.signUpButton.enabled = YES;
    self.skipAheadButton.enabled = YES;
    self.forgotPasswordButton.enabled = YES;
}


#pragma mark - Target/Action methods

/**
 * Proceed to use the app without authenticating
 */
- (IBAction)skipAuthentication:(UIButton *)sender
{
    // operate anonymously
    [[BBTHTTPManager sharedManager] operateAnonymously];
    // reset application
    [self resetApplication];
    // and close this modal
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
