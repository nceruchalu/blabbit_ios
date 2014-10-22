//
//  BBTCredentialsViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTCredentialsViewController.h"
#import "UIView+Borders.h"

@interface BBTCredentialsViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

/**
 * VC subclass' main action button. So Sign in/Sign up/Reset password
 */
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

// cached action button title since setting button's titleLabel to hidden doesn't work.
@property (strong, nonatomic) NSString *actionButtonTitle;

@end

@implementation BBTCredentialsViewController

#pragma mark - Private Class methods
/**
 * Generate a white gradient layer.
 */
+ (CAGradientLayer *)whiteGradientLayer
{
    // get background gradient
    UIColor *topColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.15];
    UIColor *bottomColor = [UIColor colorWithRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:0.15];
    
    NSArray *gradientColors = @[(id)topColor.CGColor, (id)bottomColor.CGColor];
    NSArray *gradientLocations = @[@(0.0), @(1.0)];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    
    return gradientLayer;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupViewConfigurations];
}

- (void)setupViewConfigurations
{
    // set input field borders
    for (UITextField *textField in self.inputTextFieldsCollection) {
        [textField addBottomBorderWithHeight:kInputBorderThickness
                                    andColor:kInputBorderColor];
    }
    
    // set background gradient color
    CAGradientLayer *backgroundLayer = [[self class] whiteGradientLayer];
    backgroundLayer.frame = self.view.frame;
    [self.contentView.layer insertSublayer:backgroundLayer atIndex:0];
}


#pragma mark - Instance methods
#pragma mark Public
/**
 * Show an alert with given title and message.
 * The alert has only a cancel button with fixed text "OK".
 *
 * @param title     alert view title
 * @param message   alert view message
 */
- (void)alertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

/**
 * Setup to be done at the beginning of the Target-Action method for the mainButton.
 */
- (void)startPerformMainAction
{
    [self.spinner startAnimating];
    // cache action button title label then hide it
    self.actionButtonTitle = self.actionButton.titleLabel.text;
    [self.actionButton setTitle:@"" forState:UIControlStateNormal];
    // disable button
    self.actionButton.enabled = NO;
}

- (void)endPeformMainAction
{
    [self.spinner stopAnimating];
    // reset titleLabel to what it was.
    [self.actionButton setTitle:self.actionButtonTitle forState:UIControlStateNormal];
    // enable button
    self.actionButton.enabled = YES;
}

# pragma mark Abstract
- (void)performMainAction
{
    return;
}


#pragma mark - Target/Action methods
- (IBAction)actionButtonTapped:(UIButton *)sender {
    [self startPerformMainAction];
    [self performMainAction];
}



@end
