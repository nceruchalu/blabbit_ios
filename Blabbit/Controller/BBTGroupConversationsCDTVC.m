//
//  BBTGroupConversationsCDTVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/13/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTGroupConversationsCDTVC.h"
#import "BBTCreateGroupConversationViewController.h"
#import "BBTXMPPManager.h"
#import "BBTGroupConversation+XMPP.h"
#import "BBTGroupConversationsTableViewCell.h"
#import "BBTGroupConversationDetailViewController.h"
#import "BBTUtilities.h"
#import "BBTModelManager.h"
#import "BBTHTTPManager.h"

#pragma mark - Constants
// Search scope indices for "All" and "Mine"
static const NSInteger __unused kSearchScopeAll  = 0;
static const NSInteger kSearchScopeMine = 1;
static CGFloat const kTableRowHeight = 99.0;

@interface BBTGroupConversationsCDTVC ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *createButton;

@end

@implementation BBTGroupConversationsCDTVC

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set search results tableview row height
    self.searchDisplayController.searchResultsTableView.rowHeight = kTableRowHeight;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Would refresh here but this is just wasting network resources
    //[self refresh];
    
    [self setCreateButtonEnabled];
    
    // Add Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(xmppStreamAuthenticationChange:)
                                                 name:kBBTAuthenticationNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTAuthenticationNotification
                                                  object:nil];
}


#pragma mark - Instance Methods

#pragma mark Private
/**
 * Set enablement of create button to require authentication on both HTTP and XMPP
 */
- (void)setCreateButtonEnabled
{
    // can only create groups if completely authenticated (HTTP & XMPP)
    self.createButton.enabled = [BBTHTTPManager sharedManager].httpAuthenticated && [BBTXMPPManager sharedManager].xmppStream.isAuthenticated;
}

#pragma mark Concrete implementations
/**
 * Creates an NSFetchRequest for BBTGroupConversations that you're a member of.
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
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTGroupConversation"];
        
        request.predicate = [NSPredicate predicateWithFormat:@"membership == %lu",BBTGroupConversationMembershipMember];
        
        NSSortDescriptor *creationDateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                                           ascending:NO];
        NSSortDescriptor *lastModifiedSort = [NSSortDescriptor sortDescriptorWithKey:@"lastModified"
                                                                           ascending:NO];
        request.sortDescriptors = @[creationDateSort, lastModifiedSort];
        request.fetchBatchSize = 20;
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self. managedObjectContext
                                                                              sectionNameKeyPath:nil
                                                                                       cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }
}


#pragma mark - Notification Observer Methods
/**
 *  Upon change of user authentication on XMPP stream.
 */
- (void)xmppStreamAuthenticationChange:(NSNotification *)aNotification
{
    [self setCreateButtonEnabled];
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
    
    return cell;
}

#pragma mark Deleting rows
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // if the table is asking to commit a delete command, leave the conversation
        // by first getting the appropriate conversation
        NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
        BBTGroupConversation *conversation = [fetchedResultsController objectAtIndexPath:indexPath];
        
        // revoke group membership on server and locally
        [conversation revokeMembership];
    }
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
    NSInteger searchOption = self.searchDisplayController.searchBar.selectedScopeButtonIndex;
    [self updateFilteredContentForSearchString:searchString scope:searchOption];
    
    // we will reload search tableview by updating the search FRC
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    NSString *searchString = self.searchDisplayController.searchBar.text;
    [self updateFilteredContentForSearchString:searchString scope:searchOption];
    
    // we will reload search tableview by updating the search FRC
    return NO;
}

#pragma mark Content Filtering

/**
 * Configure searchFetchedResultsController to perform a search limiting results
 * to the specified scope
 *
 * @param searchString  search query string (conversation subject)
 * @param scope         search scope: all groupchats or only groupchats owned by user
 */
- (void)updateFilteredContentForSearchString:(NSString *)searchString scope:(NSInteger)scope
{
    
    
    // strip out all the leading and trailing spaces
    NSString *strippedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // skip the fetch request and reload tableview now if there isn't a search string
    if (![strippedSearchString length]) {
        self.searchFetchedResultsController = nil;
        return;
    }
    
    // break up the search terms (separated by spaces)
    NSArray *searchItems = [strippedSearchString componentsSeparatedByString:@" "];
    
    // build all the expressions for each value in the searchString
    NSMutableArray *subjectPredicates = [NSMutableArray array];
    
    for (NSString *searchStringItem in searchItems) {
        // each searchString creates an AND predicate for groupchat subject
        //
        // example if searchItems contains "iphone 599 2007":
        //      subject CONTAINS[c] "iphone"
        //      subject CONTAINS[c] "599"
        //      subject CONTAINS[c] "2007"
        //
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subject CONTAINS[c] %@",searchStringItem];
        
        // add this predicate to our master OR predicate
        [subjectPredicates addObject:predicate];
    }
    
    // combine all the match predicates by "AND"s
    NSCompoundPredicate *subjectMatchPredicate = (NSCompoundPredicate *)[NSCompoundPredicate andPredicateWithSubpredicates:subjectPredicates];
    
    // predicate has to account for the scope by ANDing it in
    NSCompoundPredicate *scopedCompoundPredicate = nil;
    
    if (scope == kSearchScopeMine) {
        // we have an ownership scope to narrow our search further
        NSPredicate *scopePredicate = [NSPredicate predicateWithFormat:@"(isOwner == YES)"];
        
        scopedCompoundPredicate = (NSCompoundPredicate *)[NSCompoundPredicate andPredicateWithSubpredicates:@[subjectMatchPredicate, scopePredicate]];
        
    } else { // if (scope == kSearchScopeAll)
        // no ownership scope, so just match up the subjects of the GroupConversation
        scopedCompoundPredicate = subjectMatchPredicate;
    }
    
    // Don't forget that we are in a View Controller where we only show groupchats
    // we are members of.
    NSPredicate *memberPredicate = [NSPredicate predicateWithFormat:@"(membership == %lu)",BBTGroupConversationMembershipMember];
    NSCompoundPredicate *finalCompoundPredicate = (NSCompoundPredicate *)[NSCompoundPredicate andPredicateWithSubpredicates:@[scopedCompoundPredicate, memberPredicate]];
    
    // Finally setup searchFetchedResultsController
    NSManagedObjectContext *managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTGroupConversation"];
    
    NSSortDescriptor *creationDateSort = [NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                                       ascending:NO];
    NSSortDescriptor *lastModifiedSort = [NSSortDescriptor sortDescriptorWithKey:@"lastModified"
                                                                       ascending:NO];
    
    [request setSortDescriptors:@[creationDateSort, lastModifiedSort]];
    [request setPredicate:finalCompoundPredicate];
    [request setFetchBatchSize:20];
    
    self.searchFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
}


#pragma mark - Refresh
- (IBAction)refresh
{
    // show the spinner if not already showing
    [self.refreshControl beginRefreshing];
    
    [[BBTHTTPManager sharedManager] setupRooms:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
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
            groupDetailVC.conversation = [fetchedResultsController objectAtIndexPath:indexPath];
        }
        
    } else if ([vc isKindOfClass:[BBTCreateGroupConversationViewController class]]) {
        // show the VC to create a new conversation
        if ([segueIdentifier isEqualToString:@"newConversation"]) {
            // should configure VC, however it already auto-populates its contact
            // list so nothing to do here.
        }
    }
}


#pragma mark Modal Unwinding
- (IBAction)createdGroupConversation:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[BBTCreateGroupConversationViewController class]]) {
        BBTCreateGroupConversationViewController *createGroupVC = (BBTCreateGroupConversationViewController *)segue.sourceViewController;
        BBTGroupConversation *createdConversation = createGroupVC.createdConversation;
        if (createdConversation) {
            // if a conversation was created do something interesting here.
        }
    }
}


@end
