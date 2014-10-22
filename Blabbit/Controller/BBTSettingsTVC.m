//
//  BBTSettingsTVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/1/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTSettingsTVC.h"
#import <MessageUI/MessageUI.h>
#import "BBTHTTPManager.h"
#import "BBTModelManager.h"

/**
 * Constants for button indices in action sheets
 */
static const NSUInteger kTellAFriendMailButtonIndex = 0;    // Mail
static const NSUInteger kTellAFriendMessageButtonIndex = 1; // Message

/**
 * Constants for messages used to Tell Friends about the app
 */
static NSString *const kTellAFriendMailSubject = @"Blabbit iPhone App";
static NSString *const kTellAFriendMailBody = @"Hey,\n\nI just downloaded Blabbit on my iPhone.\n\nIt lets me pose topics and get anonymous answers in realtime.\n\nGet it now from http://blabb.it and 'get into it'.";
static NSString *const kTellAFriendMessageBody = @"Check out Blabbit for your iPhone. Download it today from http://blabb.it";

@interface BBTSettingsTVC () <UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

// keep outlets to all cells in static table view so we know which is clicked.
@property (weak, nonatomic) IBOutlet UITableViewCell *tellAFriendCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *profileCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *passwordCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *soundsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *contactSupportCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *aboutCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *signInOrOutCell;

@property (weak, nonatomic) IBOutlet UISwitch *soundsCellSwitch;

// keep track of the multiple actionsheets so we know which we are handling
@property (strong, nonatomic) UIActionSheet *tellAFriendActionSheet;

@end

@implementation BBTSettingsTVC

#pragma mark - Properties
- (UIActionSheet *)tellAFriendActionSheet
{
    // lazy instantiation
    if (!_tellAFriendActionSheet) {
        _tellAFriendActionSheet = [[UIActionSheet alloc] initWithTitle:@"Tell a friend about Blabbit via..."
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:@"Mail", @"Message", nil];
    }
    return _tellAFriendActionSheet;
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // authenticated users have a different view of settings from anonymous users
    
    if ([BBTHTTPManager sharedManager].isHTTPAuthenticated) {
        // Profile/Password is active and clickable
        [self enableCell:self.profileCell];
        [self enableCell:self.passwordCell];
        
        // Already signed in so only option is to sign out
        self.signInOrOutCell.textLabel.text = @"Sign out";
        self.signInOrOutCell.textLabel.textColor = [UIColor redColor];
    
    } else {
        // Profile/Password are meaningless until authenticated
        [self disableCell:self.profileCell];
        [self disableCell:self.passwordCell];
        
        // Provide option to authenticate
        self.signInOrOutCell.textLabel.text = @"Sign in";
        self.signInOrOutCell.textLabel.textColor = kBBTDarkGreenColor;
    }
    
    // Read sounds settings from storage
    self.soundsCellSwitch.on = [BBTModelManager sharedManager].userSoundsSetting;
}

#pragma mark Helpers
- (void)enableCell:(UITableViewCell *)cell
{
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
}

- (void)disableCell:(UITableViewCell *)cell
{
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor lightGrayColor];
}

#pragma mark - Instance methods

#pragma mark Target-Action
- (IBAction)toggleSoundsSetting:(UISwitch *)sender
{
    [BBTModelManager sharedManager].userSoundsSetting = sender.isOn;
}




#pragma mark Actions

// -------------------------------------------------------------------------------
//  showMailPicker:
//  Action for the Compose Mail button.
// -------------------------------------------------------------------------------
- (void)showMailPicker
{
    // You must check that the current device can send email messages before you
    // attempt to create an instance of MFMailComposeViewController.  If the
    // device can not send email messages,
    // [[MFMailComposeViewController alloc] init] will return nil.  Your app
    // will crash when it calls -presentViewController:animated:completion: with
    // a nil view controller.
    if ([MFMailComposeViewController canSendMail]) {
        // The device can send email.
        [self displayMailComposerSheet];
        
    } else {
        // The device can not send email.
        // This would be a good place to show a message saying device can't
        // send mail.
    }
}

// -------------------------------------------------------------------------------
//  showSMSPicker:
//  Action for the Compose SMS button.
// -------------------------------------------------------------------------------
- (IBAction)showSMSPicker
{
    // You must check that the current device can send SMS messages before you
    // attempt to create an instance of MFMessageComposeViewController.  If the
    // device can not send SMS messages,
    // [[MFMessageComposeViewController alloc] init] will return nil.  Your app
    // will crash when it calls -presentViewController:animated:completion: with
    // a nil view controller.
    if ([MFMessageComposeViewController canSendText]) {
        // The device can send email.
        [self displaySMSComposerSheet];
    
    } else {
        // The device can not send email.
        // This would be a good place to show a message saying device can't
        // send SMS.
    }
}

#pragma mark Compose Mail/SMS

// -------------------------------------------------------------------------------
//  displayMailComposerSheet
//  Displays an email composition interface inside the application.
//  Populates all the Mail fields.
// -------------------------------------------------------------------------------
- (void)displayMailComposerSheet
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:kTellAFriendMailSubject];
    
    // Set up recipients
    NSArray *toRecipients = @[];
    NSArray *ccRecipients = @[];
    NSArray *bccRecipients = @[];
    
    [picker setToRecipients:toRecipients];
    [picker setCcRecipients:ccRecipients];
    [picker setBccRecipients:bccRecipients];
    
    // Fill out the email body text
    NSString *emailBody = kTellAFriendMailBody;
    [picker setMessageBody:emailBody isHTML:NO];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

// -------------------------------------------------------------------------------
//  displayMailComposerSheet
//  Displays an SMS composition interface inside the application.
// -------------------------------------------------------------------------------
- (void)displaySMSComposerSheet
{
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate = self;
    
    // You can specify one or more preconfigured recipients.  The user has
    // the option to remove or add recipients from the message composer view
    // controller.
    /* picker.recipients = @[@"Phone number here"]; */
    
    // You can specify the initial message text that will appear in the message
    // composer view controller.
    picker.body = kTellAFriendMessageBody;
    
    [self presentViewController:picker animated:YES completion:NULL];
}


#pragma mark - MFMailComposeViewControllerDelegate

// -------------------------------------------------------------------------------
//  mailComposeController:didFinishWithResult:
//  Dismisses the email composition interface when users tap Cancel or Send.
//  Proceeds to update the message field with the result of the operation.
// -------------------------------------------------------------------------------
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // A good place to notify users about errors associated with the interface
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - MFMessageComposeViewControllerDelegate
// -------------------------------------------------------------------------------
//  messageComposeViewController:didFinishWithResult:
//  Dismisses the message composition interface when users tap Cancel or Send.
//  Proceeds to update the feedback message field with the result of the
//  operation.
// -------------------------------------------------------------------------------
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    // A good place to notify users about errors associated with the interface
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the selected cell
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    // Action to perform depends on clicked cell
    if (selectedCell == self.tellAFriendCell) {
        [self.tellAFriendActionSheet showInView:self.tableView];
        
    } else if (selectedCell == self.signInOrOutCell) {
        // if authenticated sign out, else show sign in prompt
        if ([BBTHTTPManager sharedManager].isHTTPAuthenticated) {
            [[BBTHTTPManager sharedManager] signOut];
        } else {
            [[BBTHTTPManager sharedManager] startSignIn];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.tellAFriendActionSheet) {
        // tell a friend about Blabbit either via Mail or SMS.
        switch (buttonIndex) {
            case kTellAFriendMailButtonIndex:
                [self showMailPicker];
                break;
            
            case kTellAFriendMessageButtonIndex:
                [self showSMSPicker];
                break;
                
            default:
                break;
        }
    }
}


#pragma mark - Navigation
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"showProfileSettings"] ||
        [identifier isEqualToString:@"showChangePassword"]) {
        return [BBTHTTPManager sharedManager].isHTTPAuthenticated;
    }
    
    return YES;
}


@end
