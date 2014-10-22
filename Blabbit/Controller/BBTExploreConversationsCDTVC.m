//
//  BBTExploreConversationsCDTVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/29/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTExploreConversationsCDTVC.h"
#import "BBTGroupConversation+XMPP.h"
#import "BBTGroupConversationsTableViewCell.h"
#import "BBTUtilities.h"
#import "BBTHTTPManager.h"
#import "BBTModelManager.h"
#import "BBTGroupConversationDetailViewController.h"
#import "BBTControllerHelper.h"

#pragma mark - Constants
static NSInteger const kSegmentedControlPopular = 0;
static NSInteger const kSegmentedControlInvites = 1;
static CGFloat const kTableRowHeight            = 99.0;
static NSString * const kSegmentedControlInvitesTitle = @"Invites";

@interface BBTExploreConversationsCDTVC ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *exploreSegmentedControl;

@end

@implementation BBTExploreConversationsCDTVC

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // start off from popular groupchats View
    self.exploreSegmentedControl.selectedSegmentIndex = kSegmentedControlPopular;
    
    // set search results tableview row height
    self.searchDisplayController.searchResultsTableView.rowHeight = kTableRowHeight;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // updated associated tab bar item badge and corresponding segment title
    [BBTControllerHelper updateExploreTabBadge];
    [self updateSegmentInvitesTitle];
    
    // Add Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(conversationsUpdated:)
                                                 name:kBBTConversationsUpdateNotification
                                               object:nil];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTConversationsUpdateNotification
                                                  object:nil];
}

#pragma mark - Instance Methods
#pragma mark Concrete implementations
/**
 * Creates an NSFetchRequest for BBTGroupConversations that you're invited to.
 *
 * This NSFetchRequest is used to build  our NSFetchedResultsController @property
 *   inherited from CoreDataTableViewController.
 *
 * Assumption: This method is only called when self.managedObjectContext has been
 *   configured.
 */
- (void)setupFetchedResultsController
{
    [self changeConversationsList:self.exploreSegmentedControl];
    
    // changing FRC so also update number of unread invitiations
    [self updateSegmentInvitesTitle];
}

#pragma mark Private
/*
 * Change the fetchedResultsController to alternate betwen popular and
 * invited-to groupchats
 *
 * @param sender    UISegmentedControl that decides what set of groupchats to use.
 */
- (IBAction)changeConversationsList:(UISegmentedControl *)sender
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTGroupConversation"];
        
        NSSortDescriptor *creationDateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
        NSSortDescriptor *lastModifiedSort = [NSSortDescriptor sortDescriptorWithKey:@"lastModified" ascending:NO];
        NSSortDescriptor *likesCountSort = [NSSortDescriptor sortDescriptorWithKey:@"likesCount" ascending:NO];
       
        [request setFetchBatchSize:20];
        
        // TODO: limit predicates to not consider expired groups
        if (sender.selectedSegmentIndex == kSegmentedControlPopular) {
            // show popular groupchats among all groupchats
            [request setPredicate:nil];
            [request setSortDescriptors:@[likesCountSort, creationDateSort, lastModifiedSort]];
            self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
            
        } else if (sender.selectedSegmentIndex == kSegmentedControlInvites) {
            // show groupchats you've been invited to
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(membership == %lu) OR (membership == %lu)", BBTGroupConversationMembershipInvited, BBTGroupConversationMembershipInvitedViewed];

            [request setPredicate:predicate];
            [request setSortDescriptors:@[creationDateSort, lastModifiedSort]];
            self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        }
        
    } else {
        self.fetchedResultsController = nil;
    }
}

/**
 * Fetch popular groupchat conversations from webserver.
 *
 * @param conversationsFetched  block to be called after fetching rooms, regardless
 *      of success or failure.
 */
- (void)fetchPopularConversations:(void (^)())conversationsFetched
{
    // Start spinner and force showing of refreshControl if not already
    // showing. This makes up for no activity indicator spinner.
    if (!self.refreshControl.refreshing) {
        // is this not a manual refresh operation?
        [self.refreshControl beginRefreshing];
        CGFloat newYOffset = self.refreshControl.frame.size.height + self.tableView.contentInset.top;
        [self.tableView setContentOffset:CGPointMake(0, -newYOffset) animated:YES];
    }
    
    [[BBTHTTPManager sharedManager] fetchPopularConversations:conversationsFetched];
    
}


/**
 * Set title of "invites" segment of View Controller's UISegmentedControl.
 * This segment could have a couple unread conversations (as indicated) by the
 * tab's badge, so append this count to the base title
 * This means the title is either:
 * - "Invites"
 * - "Invites (<x>)" where <x> will be substituted with a count.
 */
- (void)updateSegmentInvitesTitle
{
    NSString *title = kSegmentedControlInvitesTitle;
    // if there are unread invitations, append that here.
    int invitationsCount = (int)[BBTControllerHelper invitedButUnviewedConversationsCount];
    if (invitationsCount) {
        title = [NSString stringWithFormat:@"%@ (%d)", title, invitationsCount];
    }
    [self.exploreSegmentedControl setTitle:title forSegmentAtIndex:kSegmentedControlInvites];
}


#pragma mark - Notification Observer Methods
/**
 *  Selection of conversations updated so update invites segmented control title.
 */
- (void)conversationsUpdated:(NSNotification *)aNotification
{
    [self updateSegmentInvitesTitle];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Group Conversation Cell"; // get the cell
    
    // Observe that I'm dequeing from self.tableView as opposed to just tableView.
    //   and I'm also not specifying an indexPath
    //   This way there won't be exceptions thrown when tableView is a searchResultsTableView
    BBTGroupConversationsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Get conversation to configure the cell with
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
    BBTGroupConversation *conversation = [fetchedResultsController objectAtIndexPath:indexPath];
    
    // Configure the cell with data from the managed object
    cell.subjectLabel.text = conversation.subject;
    cell.likesCountLabel.text = [NSString stringWithFormat:@"%@", conversation.likesCount];
    cell.photoAttachedImageView.hidden = ([conversation.photoURL length] == 0);
    
    // set expiry time label
    NSString *expiryTime = [BBTUtilities timeLabelForConversationDate:[conversation expiryTime]];
    cell.expiryTimeLabel.text = expiryTime ? expiryTime : @"Expired";
    
    // show indicator for unacknowledged invitations
    BOOL unackdInvite = [conversation.membership integerValue] == BBTGroupConversationMembershipInvited;
    cell.unreadIndicatorView.hidden = !unackdInvite;
    
    return cell;
}

#pragma mark Deleting rows
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            // if the table is asking to commit a delete decline your invite.
            // by first getting the appropriate conversation
            NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
            BBTGroupConversation *conversation = [fetchedResultsController objectAtIndexPath:indexPath];
            
            // decline invitation by updating membership status. This invitation
            // isn't persisted on the server so nothing else to worry about.
            conversation.membership = @(BBTGroupConversationMembershipNone);
            
            // post notification to update UI badges and reflect change
            [[NSNotificationCenter defaultCenter] postNotificationName:kBBTConversationsUpdateNotification object:self];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Can only perform deletes on the conversations we've been invited to
    return ((tableView == self.tableView) &&
            (self.exploreSegmentedControl.selectedSegmentIndex == kSegmentedControlInvites));
}


#pragma mark - UITableViewDelegate
#pragma mark Deleting rows
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Ignore";
}


#pragma mark -  UISearchDisplayDelegate
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [super searchDisplayControllerWillBeginSearch:controller];
    
    // modify search bar style so that it looks decent
    UISearchBar *searchBar = self.searchDisplayController.searchBar;
    searchBar.barTintColor = [UIColor whiteColor];
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [super searchDisplayControllerWillEndSearch:controller];
    // clear out search results (already done by SearchCDTVC)
    // reset fetchedResultsController which is cleared out when we begin search
    [self setupFetchedResultsController];
    
    // reset search bar style to default
    UISearchBar *searchBar = self.searchDisplayController.searchBar;
    searchBar.barTintColor = nil;
    searchBar.searchBarStyle = UISearchBarStyleDefault;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // skip the server query and reload tableview now if there isn't a search string
    if (![searchString length]) {
        self.searchFetchedResultsController = nil;
        return NO;
    }
    
    // perform search here (a non-blocking network call)
    NSDictionary *parameters = @{kBBTRESTSearchQueryKey : searchString};
    [[BBTHTTPManager sharedManager] request:BBTHTTPMethodGET
                                     forURL:kBBTRESTSearchRooms
                                 parameters:parameters
                                    success:^(NSURLSessionDataTask *task, id responseObject)
     {
         // get array of dictionaries in search results
         NSArray *searchResultsJSON = [responseObject objectForKey:kBBTRESTListResultsKey];
         
         // put search results in core data
         NSManagedObjectContext *managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;
         [managedObjectContext performBlock:^{
             NSArray *searchResults = [BBTGroupConversation groupConversationsWithRoomInfoArray:searchResultsJSON inManagedObjectContext:managedObjectContext];
             
             // get unique key (room names) of rooms in response
             NSMutableArray *roomNames = [[NSMutableArray alloc] init];
             for (BBTGroupConversation *conversation in searchResults) {
                 [roomNames addObject:conversation.roomName];
             }
             
             // now reconfigure the searchFRC
             // this has a side-effect of reloading the tableView so use main thread.
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self setupSearchFetchedResultsControllerForRooms:roomNames];
             });
         }];
     }
                                    failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject)
     {
         // failed search so clear out searchFRC
         // this has a side-effect of reloading the tableView so use main thread.
         dispatch_async(dispatch_get_main_queue(), ^{
             self.searchFetchedResultsController = nil;
         });
     }];
    
    // we will reload search tableview by updating the search FRC
    return NO;
}

#pragma mark Helper
/**
 * Configure searchFetchedResultsController to only show data of a given
 * set of rooms (that were pulled from search results)
 *
 * @param roomNames List of room roomNames to restrict objects to.
 */
- (void)setupSearchFetchedResultsControllerForRooms:(NSArray *)roomNames
{
    NSManagedObjectContext *managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTGroupConversation"];
    
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"roomName"
                                                        ascending:YES];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(roomName IN[c] %@)", roomNames];
    
    [request setSortDescriptors:@[sd1]];
    [request setPredicate:predicate];
    [request setFetchBatchSize:20];
    
    self.searchFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
}


#pragma mark - Refresh
- (IBAction)refresh
{
    // show the spinner if not already showing
    [self.refreshControl beginRefreshing];
    
    [[BBTHTTPManager sharedManager] fetchPopularConversations:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue as UIKit only runs there
            [self.refreshControl endRefreshing];
        });
    }];
}


#pragma mark - Navigation
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
                fromIndexPath:(NSIndexPath *)indexPath
                  ofTableView:(UITableView *)tableView
{
    [super prepareViewController:vc forSegue:segueIdentifier fromIndexPath:indexPath ofTableView:tableView];
    
    if ([vc isKindOfClass:[BBTGroupConversationDetailViewController class]]) {
        // show the VC to view details of group conversation
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:@"showGroupConversationDetail"]) {
            BBTGroupConversationDetailViewController *groupDetailVC = (BBTGroupConversationDetailViewController *)vc;
            // configure VC
            NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
            BBTGroupConversation *conversation = [fetchedResultsController objectAtIndexPath:indexPath];
            groupDetailVC.conversation = conversation;
            // update conversation if you've been invited to it and about to view it
            if ([conversation.membership integerValue] == BBTGroupConversationMembershipInvited) {
                conversation.membership = @(BBTGroupConversationMembershipInvitedViewed);
                // post notification to update UI badges and reflect change
                [[NSNotificationCenter defaultCenter] postNotificationName:kBBTConversationsUpdateNotification object:self];
            }
        }
    }
}

@end
