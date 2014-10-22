//
//  BBTContactConversationsCDTVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/13/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTContactConversationsCDTVC.h"
#import "BBTContactConversationsTableViewCell.h"
#import "BBTMessage.h"
#import "BBTUser+HTTP.h"
#import "BBTUtilities.h"

@interface BBTContactConversationsCDTVC ()

@end

@implementation BBTContactConversationsCDTVC

#pragma mark Concrete implementations
/**
 * Creates an NSFetchRequest for BBTConversations sorted by ascending
 *   lastMessage.localTimestamp as this is how normal conversation UIs work.
 *
 * This NSFetchRequest is used to build  our NSFetchedResultsController @property
 *   inherited from CoreDataTableViewController.
 *
 * Assumption: This method is only called when self.managedObjectContext has been
 *   configured.
 */
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTUser"];
        
        // prefetch to avoid faulting individually
        [request setRelationshipKeyPathsForPrefetching:@[@"lastMessage"]];
        
        request.predicate = [NSPredicate predicateWithFormat:@"messages.@count > 0"];
        
        NSSortDescriptor *lastMessageDateSort = [NSSortDescriptor sortDescriptorWithKey:@"lastMessage.localTimestamp" ascending:NO];
        
        request.sortDescriptors = @[lastMessageDateSort];
        request.fetchBatchSize = 20;
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self. managedObjectContext sectionNameKeyPath:nil
                                                                                       cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Contact Conversation Cell"; // get the cell
    BBTContactConversationsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                                               forIndexPath:indexPath];
    BBTUser *conversationContact = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // configure the cell with data from the managed object
     cell.displayNameLabel.text = [conversationContact formattedName];
     cell.lastMessageLabel.text = conversationContact.lastMessage.body;
     cell.dateLabel.text = [BBTUtilities dayLabelForMessageDate:conversationContact.lastMessage.localTimestamp];
     cell.unreadMessageCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[conversationContact.unreadMessageCount unsignedIntegerValue]];
    
    // set avatar image
    if (conversationContact.avatarThumbnail) {
        cell.avatarImageView.image = conversationContact.avatarThumbnail;
    } else {
        cell.avatarImageView.image = [UIImage imageNamed:@"defaultAvatar"];
        [conversationContact updateThumbnailImage];
    }
    
    return cell;
}

#pragma mark Deleting rows
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // if the table is asking to commit a delete command, delete the messages
        // sent by the contact
        BBTUser *conversationContact = [self.fetchedResultsController objectAtIndexPath:indexPath];
        for (BBTMessage *message in conversationContact.messages) {
            [conversationContact.managedObjectContext deleteObject:message];
        }
    }
}

@end
