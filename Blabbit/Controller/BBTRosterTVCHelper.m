//
//  BBTRosterTVCHelper.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/30/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTRosterTVCHelper.h"
#import "BBTSearchRosterTableViewCell.h"
#import "BBTXMPPManager.h"
#import "BBTRosterTableViewCell.h"
#import "XMPPUserCoreDataStorageObject+BBTUserModel.h"
#import "XMPPvCardCoreDataStorageObject.h"
#import "BBTUser+HTTP.h"
#import "BBTHTTPManager.h"

@implementation BBTRosterTVCHelper

#pragma mark - Class Methods 
#pragma mark Public
+ (void)configureCell:(BBTRosterTableViewCell *)cell withUser:(id)user
{
    if ([user isKindOfClass:[XMPPUserCoreDataStorageObject class]]) {
        [BBTRosterTVCHelper configureCell:cell withXMPPUser:user];
    
    } else { // if ([user isKindOfClass:[BBTUser class]]) {
        [BBTRosterTVCHelper configureCell:cell withHTTPUser:user];
    }
    
    // Search Cells have a button that shows if each represented user is/isn't
    // on your contact list. Configure that here.
    //
    // Observe that inbound friend requests  use an 'add' button so that the only
    // action available to the user (via the search table) is completing the
    // friend request cycle
    //
    if ([cell isKindOfClass:[BBTSearchRosterTableViewCell class]]) {
        BBTSearchRosterTableViewCell *searchCell = (BBTSearchRosterTableViewCell *)cell;
        
        if ([user isKindOfClass:[BBTUser class]]) {
            NSUInteger userFriendship = [((BBTUser *)user).friendship integerValue];
            
            switch (userFriendship) {
                case BBTUserFriendshipBoth:
                    // contact is a friend
                    searchCell.toggleFriendshipButton.hidden = NO;
                    [searchCell.toggleFriendshipButton setImage:[UIImage imageNamed:@"check-full"]
                                                       forState:UIControlStateNormal];
                    break;
                    
                case BBTUserFriendshipNone:
                case BBTUserFriendshipFrom:
                    // contact can be made a friend
                    searchCell.toggleFriendshipButton.hidden = NO;
                    [searchCell.toggleFriendshipButton setImage:[UIImage imageNamed:@"plus-line"]
                                                       forState:UIControlStateNormal];
                    break;
                    
                case BBTUserFriendshipTo:
                default:
                    // don't want to act on a sent friend request till recipient
                    // accepts/declines
                    searchCell.toggleFriendshipButton.hidden = YES;
                    break;
            }
        }
    }
}

+ (NSString *)userSectionNumToStatus:(int)sectionNum
{
    NSString *status = nil;
    
    switch (sectionNum) {
        case 0  :
            status = @"Available";
            break;
        case 1  :
            status = @"Away";
            break;
        default :
            status = @"Offline";
            break;
    }
    
    return status;
}


#pragma mark Private
/**
 * Configure a cell in UITableViewDataSource method: tableView:cellForRowAtIndexPath:
 * @param cell  Table view cell to be updated
 * @param user  User to be represented in table view cell of type XMPPUserCoreDataStorageObject
 */
+ (void)configureCell:(BBTRosterTableViewCell *)cell
         withXMPPUser:(XMPPUserCoreDataStorageObject *)user
{
    // Our xmppRosterStorage will cache user nicknames as they arrive from the xmppvCardTempModule.
    // It will also cache user photos as they arrive from he xmppvCardAvatarModule.
	// We only need to ask the vcard-temp module for user details, if the roster
    // doesn't have either or both of them.
    if (user.nickname) {
        cell.displayNameLabel.text = user.nickname;
        cell.onlineStatusLabel.text = user.username;
    }
    if (user.photo) {
        cell.avatarImageView.image = user.photo;
    }
    
    if (!user.nickname || !user.photo) {
        XMPPvCardCoreDataStorageObject *vcard = [BBTRosterTVCHelper vCardForJID:user.jid];
        
        // if user's nickname/formatted name or photo wasn't cached try getting it
        // from vCard. This is of course going to result in a Core Data fetch of
        // the vCard. So you might be tempted to optimize this and cache it upon
        // receipt. Well *dont* do that. Remember this function only got called
        // because there was an update to the user object. Trying to do another
        // update while in here breaks things. Live with the minor fetch. Not like
        // this happens often!
        
        BBTXMPPManager *xmppManager = [BBTXMPPManager sharedManager];
        
        // if user nickname wasn't cached, try getting it from vCard
        if (!user.nickname) {
            NSString *displayName = vcard.vCardTemp.formattedName;
            
            if (displayName) {
                // just got displayName so cache it to prevent future vCard Core Data fetches
                [xmppManager.xmppRosterStorage setNickname:displayName forUserWithJID:[user.jid bareJID] xmppStream:xmppManager.xmppStream];
                cell.displayNameLabel.text = displayName;
                cell.onlineStatusLabel.text = user.username;
                
            } else {
                cell.displayNameLabel.text = user.username;
                cell.onlineStatusLabel.text = nil;
            }
        }
        
        // if user photo wasn't cached, try getting it from vCard
        if (!user.photo) {
            NSData *photoData = vcard.photoData;
            
            if (photoData) {
                UIImage *photo = [UIImage imageWithData:photoData];
                // just got photo so cache it to prevent future vCard Core Data fetches
                [xmppManager.xmppRosterStorage setPhoto:photo forUserWithJID:[user.jid bareJID] xmppStream:xmppManager.xmppStream];
                cell.avatarImageView.image = photo;
                
            } else {
                cell.avatarImageView.image = [UIImage imageNamed:@"defaultAvatar"];
            }
        }
    }
}


/**
 * Configure a cell in UITableViewDataSource method: tableView:cellForRowAtIndexPath:
 * @param cell  Table view cell to be updated
 * @param user  User to be represented in table view cell of type BBTUser
 */
+ (void)configureCell:(BBTRosterTableViewCell *)cell
         withHTTPUser:(BBTUser *)user
{
    // The REST API will actually always return a displayName so the appropriate
    // existence check is looking for an empty string
    if ([user.displayName length]) {
        cell.displayNameLabel.text = user.displayName;
        cell.onlineStatusLabel.text = user.username;
        
    } else {
        cell.displayNameLabel.text = user.username;
        cell.onlineStatusLabel.text = nil;
    }
    
    // configure Avatar image
    if (user.avatarThumbnail) {
        cell.avatarImageView.image = user.avatarThumbnail;
    } else {
        cell.avatarImageView.image = [UIImage imageNamed:@"defaultAvatar"];
        [user updateThumbnailImage];
    }
}


/**
 * Get the user vCard which should contain both display name and photo data.
 * inspired by [XMPPvCardAvatarModule -photoDataForJID:]
 */
+ (XMPPvCardCoreDataStorageObject *)vCardForJID:(XMPPJID *)jid
{
    NSManagedObjectContext *moc = [[BBTXMPPManager sharedManager].xmppvCardStorage mainThreadManagedObjectContext];
    XMPPvCardCoreDataStorageObject *vcard = [XMPPvCardCoreDataStorageObject fetchOrInsertvCardForJID:jid
                                                                              inManagedObjectContext:moc];
    
    if (!vcard.vCardTemp.formattedName || !vcard.photoData) {
        [[BBTXMPPManager sharedManager].xmppvCardTempModule vCardTempForJID:jid shouldFetch:YES];
    }
    
    return vcard;
}


/**
 * Get the formatted or display name for a given JID from the user's vCard
 * inspired by [XMPPvCardAvatarModule -photoDataForJID:]
 */
+ (NSString *)displayNameForJID:(XMPPJID *)jid
{
    NSString *displayName = nil;
    
    NSManagedObjectContext *moc = [[BBTXMPPManager sharedManager].xmppvCardStorage mainThreadManagedObjectContext];
    XMPPvCardCoreDataStorageObject *vcard = [XMPPvCardCoreDataStorageObject fetchOrInsertvCardForJID:jid
                                                                              inManagedObjectContext:moc];
    displayName = vcard.vCardTemp.formattedName;
    
    if (!displayName) {
        [[BBTXMPPManager sharedManager].xmppvCardTempModule vCardTempForJID:jid shouldFetch:YES];
    }
    
    return displayName;
}


+ (void)configureAvatarforCell:(BBTRosterTableViewCell *)cell
                  withXMPPUser:(XMPPUserCoreDataStorageObject *)user
{
	// Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
	// We only need to ask the avatar module for a photo, if the roster doesn't have it.
	if (user.photo) {
		cell.avatarImageView.image = user.photo;
        
	} else {
        // get photo data, and this might require an async network request
        NSData *photoData = [[BBTXMPPManager sharedManager].xmppvCardAvatarModule photoDataForJID:user.jid];
       
        if (photoData) {
            cell.avatarImageView.image = [UIImage imageWithData:photoData];
        } else {
            cell.avatarImageView.image = [UIImage imageNamed:@"defaultAvatar"];
        }
        
	}
}

@end
