//
//  BBTContactConversationCDCVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTContactConversationCDCVC.h"
#import "XMPPUserCoreDataStorageObject+BBTUserModel.h"
#import "BBTXMPPManager.h"
#import "BBTUser+HTTP.h"

@interface BBTContactConversationCDCVC ()

@end

@implementation BBTContactConversationCDCVC

#pragma mark - Properties
// when our model is set update the conversation @property, if there is a
// managedObjectContext is set here we update our title to be the Contact's name
- (void)setContact:(XMPPUserCoreDataStorageObject *)contact
{
    _contact = contact;
    if (self.managedObjectContext) [self setupConversation];
}


#pragma mark - Instance Methods (public)
#pragma mark Concrete
// request for the Conversation with the associated contact
- (void)setupConversation
{
    if (self.managedObjectContext) {
        self.conversation = [BBTUser conversationWithContact:self.contact
                                      inManagedObjectContext:self.managedObjectContext];
        self.title = [self.contact formattedName];
    }
}

#pragma mark Overrides
- (void)setupAvatarsForConversation
{
    // superclass does some good work so leave that going
    [super setupAvatarsForConversation];
    [self configureAvatarWithImageForContact];
    
}

#pragma mark - Instance Methods (private)
/**
 * Update self.avatars with an avatar with image for conversation's contact
 */
- (void)configureAvatarWithImageForContact
{
    XMPPUserCoreDataStorageObject *user = self.contact;
    
    // diameter of incoming avatar image
    CGFloat incomingDiameter = self.collectionView.collectionViewLayout.incomingAvatarViewSize.width;
    
    BBTUser *contactConversation = (BBTUser *)self.conversation;
    
    // Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
	// We only need to ask the avatar module for a photo, if the roster doesn't have it.
	if (user.photo) {
        UIImage *avatarImage = [JSQMessagesAvatarFactory avatarWithImage:user.photo
                                                                diameter:incomingDiameter];
		[self.avatars setObject:avatarImage forKey:[contactConversation username]];
        
	} else {
        // get photo data, and this might require an async network request
        NSData *photoData = [[BBTXMPPManager sharedManager].xmppvCardAvatarModule photoDataForJID:user.jid];
        
        UIImage *userPhoto = nil;
        if (photoData) {
            userPhoto = [UIImage imageWithData:photoData];
        } else {
            userPhoto = [UIImage imageNamed:@"defaultAvatar"];
        }
        UIImage *avatarImage = [JSQMessagesAvatarFactory avatarWithImage:userPhoto
                                                                diameter:incomingDiameter];
        [self.avatars setObject:avatarImage forKey:[contactConversation username]];
	}
}


#pragma mark - Target-Action Methods
- (IBAction)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}


@end
