//
//  BBTShareGroupConversationViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 8/9/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTShareGroupConversationViewController.h"
#import "BBTXMPPManager.h"
#import "BBTGroupConversation+XMPP.h"
#import "BBTHTTPManager.h"

@interface BBTShareGroupConversationViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation BBTShareGroupConversationViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // disable done button by default
    self.doneButton.enabled = NO;
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Can only use done button if there are selected contacts and we are authenticated.
 * So this method enables done button if there is at least one selected contact,
 * else it disables it.
 */
- (void)updateDoneButtonWithSelectedContacts
{
    self.doneButton.enabled = [BBTHTTPManager sharedManager].httpAuthenticated && ([self.selectedContacts count] > 0);
}

#pragma mark - Target-Action Methods
/**
 * Invite the selected contacts and grant user membership in conversation
 */
- (IBAction)inviteContacts:(id)sender
{
    // invite the selected contacts
    [[BBTXMPPManager sharedManager] sendRoomInvitations:[self.conversation jid]
                                             toContacts:self.selectedContacts];
    // if not already a conversation member, grant user membership
    [self.conversation grantMembership];
    
    // done with this share view controller so pop it.
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - BBTContactPickerDelegate

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didSelectContact:(id<MBContactPickerModelProtocol>)model
{
    [super contactCollectionView:contactCollectionView didSelectContact:model];
    [self updateDoneButtonWithSelectedContacts];
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didAddContact:(id<MBContactPickerModelProtocol>)model
{
    [super contactCollectionView:contactCollectionView didAddContact:model];
    [self updateDoneButtonWithSelectedContacts];
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didRemoveContact:(id<MBContactPickerModelProtocol>)model
{
    [super contactCollectionView:contactCollectionView didRemoveContact:model];
    [self updateDoneButtonWithSelectedContacts];
}


@end
