//
//  BBTFriendsRosterCDTVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/15/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTFriendsRosterCDTVC.h"
#import "BBTXMPPManager.h"
#import "BBTContactConversationCDCVC.h"
#import "BBTHTTPManager.h"
#import "BBTUser+HTTP.h"
#import "BBTModelManager.h"
#import "BBTControllerHelper.h"

#pragma mark - Constants
static NSInteger const kSegmentedControlFriends  = 0;
static NSInteger const kSegmentedControlRequests = 1;
static CGFloat const kTableRowHeight = 49.0;
static NSString * const kSegmentedControlRequestsTitle = @"Requests";

@interface BBTFriendsRosterCDTVC ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *contactsSegmentedControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;


@property (strong, nonatomic) UIAlertView *alertView;

// A reference to the searchBarView which is frequently removed and re-inserted
// in view hierarchy
@property (strong, nonatomic) UIView *searchBarView;

@end

@implementation BBTFriendsRosterCDTVC

#pragma mark - Properties
- (UIAlertView *)alertView
{
    // lazy instantiation
    if (!_alertView) {
        _alertView = [[UIAlertView alloc] initWithTitle:@"Add Contact"
                                                message:@"Enter someone's username to find them on Blabbit"
                                               delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"Save", nil];
        _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        UITextField *textField = [_alertView textFieldAtIndex:0];
        textField.borderStyle = UITextBorderStyleNone;
        textField.clearsOnBeginEditing = YES;
        textField.placeholder = @"Username";
        textField.textAlignment = NSTextAlignmentCenter;
    }
    return _alertView;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // start off from friends view
    self.contactsSegmentedControl.selectedSegmentIndex = kSegmentedControlFriends;

    // and setup fetchedResultsController
    [self setupFetchedResultsController];
    
    // hide searchBar, but first save it for future reference;
    self.searchBarView = self.tableView.tableHeaderView;
    self.tableView.tableHeaderView = nil;
    
    // set search results tableview row height
    self.searchDisplayController.searchResultsTableView.rowHeight = kTableRowHeight;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // limit functionality for anonymous users
    BOOL authenticated = [BBTHTTPManager sharedManager].httpAuthenticated;
    self.searchButton.enabled = authenticated;
    [self setAddButtonEnabled];
    
    // update associated tab bar item badge and corresponding segment title
    [BBTControllerHelper updateContactsTabBadge];
    [self updateSegmentRequestsTitle];
    
    // Add Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rosterUpdated:)
                                                 name:kBBTRosterUpdateNotification
                                               object:nil];
    
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
                                                    name:kBBTRosterUpdateNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTAuthenticationNotification
                                                  object:nil];
    
}


#pragma mark - Instance Methods (private)
- (void)setupFetchedResultsController
{
    [self changeContactsList:self.contactsSegmentedControl];
    
    // changing FRC so also update number of pending friend requests
    [self updateSegmentRequestsTitle];
}

/**
 * Set title of "requests" segment of View Controller's UISegmentedControl.
 * This segment could have a couple pending friend requests (as indicated) by the
 * tab's badge, so append this count to the base title
 * This means the title is either:
 * - "Requests"
 * - "Requests (<x>)" where <x> will be substituted with a count.
 */
- (void)updateSegmentRequestsTitle
{
    NSString *title = kSegmentedControlRequestsTitle;
    // if there are unread invitations, append that here.
    int friendRequestsCount = (int)[BBTControllerHelper friendRequestsCount];
    if (friendRequestsCount) {
        title = [NSString stringWithFormat:@"%@ (%d)", title, friendRequestsCount];
    }
    [self.contactsSegmentedControl setTitle:title forSegmentAtIndex:kSegmentedControlRequests];
}

/**
 * Set enablement of add button to require authentication on both HTTP and XMPP
 */
- (void)setAddButtonEnabled
{
    // can only create groups if completely authenticated (HTTP & XMPP)
    self.addButton.enabled = [BBTHTTPManager sharedManager].httpAuthenticated && [BBTXMPPManager sharedManager].xmppStream.isAuthenticated;
}

#pragma mark - Notification Observer Methods
/**
 * XMPP Roster now updated so update explore contacts tab bar badge
 */
- (void)rosterUpdated:(NSNotification *)aNotification
{
    [self updateSegmentRequestsTitle];
}

/**
 *  Upon change of user authentication on XMPP stream.
 */
- (void)xmppStreamAuthenticationChange:(NSNotification *)aNotification
{
    [self setAddButtonEnabled];
}

#pragma mark - Instance Methods (public)
#pragma mark Concrete

- (NSString *)cellIdentifier
{
    static NSString *friendsIdentifier       = @"Friends Roster Cell";
    static NSString *requestsIdentifier      = @"Requests Roster Cell";
    static NSString *searchResultsIdentifier = @"Search Results Roster Cell";
    
    NSString *identifier = nil;
    if (self.searchDisplayController.isActive) {
        identifier = searchResultsIdentifier;
        
    } else if (self.contactsSegmentedControl.selectedSegmentIndex == kSegmentedControlFriends) {
        identifier = friendsIdentifier;
    } else if (self.contactsSegmentedControl.selectedSegmentIndex == kSegmentedControlRequests) {
        identifier = requestsIdentifier;
    }
    return identifier;
}

- (id)userAtIndexPath:(NSIndexPath *)indexPath ofTableView:(UITableView *)tableView
{
    NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
    return [fetchedResultsController objectAtIndexPath:indexPath];
}

#pragma mark - Target/Action Methods
- (IBAction)startSearch
{
    // show searchBar then make searchDisplayController active
    self.tableView.tableHeaderView = self.searchBarView;
    [self.searchBarView becomeFirstResponder];
    [self.searchDisplayController setActive:YES animated:YES];
}


- (void)endSearch
{
    // hide searchBar
    [self.searchBarView resignFirstResponder];
    self.tableView.tableHeaderView = nil;
    // clear out search results (already done by SearchCDTVC)
}

/*
 * Change the fetchedResultsController to alternate betwen friends and
 * pending (inbound) friend requests
 */
- (IBAction)changeContactsList:(UISegmentedControl *)sender
{
    NSManagedObjectContext *managedObjectContext = [[BBTXMPPManager sharedManager] managedObjectContextRoster];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum"
                                                        ascending:YES];
    NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName"
                                                        ascending:YES
                                                         selector:@selector(caseInsensitiveCompare:)];
    
    NSString *predicateFormat = nil;
    if (sender.selectedSegmentIndex == kSegmentedControlFriends) {
        // show contacts that are user's friends which is defined by 2 criteria
        // 1. subscription == both
        //   This means you've both subscribed to each other.
        //
        // 2. subscription == from and ask == subscribe
        //   This means you accepted a request and are waiting for contact to notice.
        //   The idea here is that when you get a friend request and you accept it
        //   all you're really doing is subscribing to that user. When the user
        //   logs into the app next an auto-accept of the subscription request will
        //   happen so this friend request is effectively complete when you have
        //   a subscription from  and you've asked to subscribe to the contact.
        predicateFormat =   @"   (subscription == \"both\")"
                            @"OR ((subscription == \"from\") AND (ask == \"subscribe\"))";
        
    } else if (sender.selectedSegmentIndex == kSegmentedControlRequests) {
        // show contacts that have sent user friend requests
        // The idea is that if all you have is a subscription from, then it means
        //   the user sent you a subscribe request and you auto-accepted as that's
        //   how the app works, but then you haven't confirmed the friendship if you
        //   haven't made an ask so it's still a pending friend request
        predicateFormat =   @"(subscription == \"from\") AND (ask == nil)";
    }
    
    // At this time sent friend requests aren't being shown but this is a simple
    // query as friend requests you've sent are defined by 2 criteria:
    // 1. subscription = to
    //   This means you've subscribed to a contact who has logged in to the
    //   app and auto-accepted the subscription request. You still have to
    //   wait for the user to either accept or deny your request.
    // 2. subscription == none and ask == subscribe
    //   This means you initiated a request and are waiting for user to login
    //   and either accept or deny it.
    //
    // Why don't we show friend outbound friend requests? This is best explained
    // with an example:
    // 1. admin adds nceruchalu
    //      roster: admin -> nceruchalu = [S=N, A=O]
    //              nceruchalu -> admin : [S=N, A=I]
    //
    // 2. admin cancels add request
    //      roster: nceruchalu -> admin : [S=N, A=I]
    //
    // 3. nceruchalu logs in and still sees friend request
    //      roster: nceruchalu -> admin : [S=F, A=N]
    //
    // 4. If nceruchalu declines friend request then all would be well, if
    //    however nceruchalu acccepts friend request then things get out of sync
    //      roster: admin -> nceruchalu : [S=N, A=I]
    //              nceruchalu -> admin : [S=F, A=O]
    //
    // 5. admin now logs in and things stay out of sync. nceruchalu believes this
    //    is a completed friendship while admin only sees a pending friend request
    //      roster: admin -> nceruchalu : [S=F, A=N]
    //              nceruchalu -> admin : [S=B, A=N]
    //
    // 6. admin declines this and we have a problem as nceruchalu will see a
    //    friend request again.
    //      roster: nceruchalu -> admin : [S=F, A=N]
    //
    // 7. Note that step (6) is equivalent to step (3) above and potential for
    //    an infinite loop of admin persistently declining friend requests while
    //    nceruchalu gets tired of having to accept friend requests. All this
    //    happened because admin added nceruchalu then quickly canceled the
    //    addition.
    //
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
    
    [request setSortDescriptors:@[sd1, sd2]];
    [request setPredicate:predicate];
    [request setFetchBatchSize:20];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:@"sectionNum"
                                                                                   cacheName:nil];
}

/*
 * show UIAlert that prompts for username of user to send friend request
 */
- (IBAction)startFriendRequest
{
    // show alert view
    [self.alertView show];
    
}

- (IBAction)acceptFriendRequest:(UIButton *)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    // to ensure the button indeed is in a cell: I know this is overkill...
    if (indexPath) {
        XMPPUserCoreDataStorageObject *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [[BBTXMPPManager sharedManager].xmppRoster addUser:[user jid]
                                              withNickname:nil];
    }
}

- (IBAction)declineFriendRequest:(UIButton *)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    // to ensure the button indeed is in a cell: I know this is overkill...
    if (indexPath) {
        XMPPUserCoreDataStorageObject *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [[BBTXMPPManager sharedManager].xmppRoster removeUser:[user jid]];
    }
}

// this comes from Search Results Table
- (IBAction)toggleFriendship:(UIButton *)sender
{
    UITableView *tableView = self.searchDisplayController.searchResultsTableView;
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:tableView];
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:buttonPosition];
    
    // to ensure the button indeed is in a cell: I know this is overkill...
    if (indexPath) {
        BBTUser *user = [self.searchFetchedResultsController objectAtIndexPath:indexPath];

        NSUInteger userFriendship = [user.friendship integerValue];
        
        if (userFriendship == BBTUserFriendshipBoth) {
            // user is already on contact list, so go ahead and delete user
            [[BBTXMPPManager sharedManager].xmppRoster removeUser:[user jid]];
            user.friendship = @(BBTUserFriendshipNone);
        
        } else if (userFriendship == BBTUserFriendshipNone) {
            // user isn't on contact list yet but can be added, so add user
            [[BBTXMPPManager sharedManager].xmppRoster addUser:[user jid] withNickname:nil];
            user.friendship = @(BBTUserFriendshipTo);
            
        } else if (userFriendship == BBTUserFriendshipFrom) {
            // user has sent us an inbound friend request, so accept it
            [[BBTXMPPManager sharedManager].xmppRoster addUser:[user jid] withNickname:nil];
            user.friendship = @(BBTUserFriendshipBoth);
        }
    }
}


#pragma mark - UITableViewDataSource
#pragma mark Deleting rows
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            // if the table is asking to commit a delete command
            //   remove the contact from user's roster
            XMPPUserCoreDataStorageObject *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
            [[BBTXMPPManager sharedManager].xmppRoster removeUser:[user jid]];
            
            // ideally we would remove the row from the tableview with an animation
            //   but we are using a CoreDataTableViewController so no need for that.
            //   [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ((tableView == self.tableView) &&
            (self.contactsSegmentedControl.selectedSegmentIndex == kSegmentedControlFriends));
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return [super tableView:tableView titleForHeaderInSection:section];
    } else {
        return nil;
    }
}


#pragma mark - UITableViewDelegate
#pragma mark Deleting rows
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Unfriend";
}

#pragma mark Selecting rows
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // if "Save" is clicked attempt to add a contact
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSString *username = [alertView textFieldAtIndex:0].text;
        
        // first check that username is valid
        NSString *userDetailURL = [NSString stringWithFormat:@"%@%@/",kBBTRESTUsers, username];
        [[BBTHTTPManager sharedManager] request:BBTHTTPMethodGET
                                         forURL:userDetailURL
                                     parameters:nil success:^(NSURLSessionDataTask *task, id responseObject)
        {
            // username is valid, so send an invitation to appropriate JID
            NSString *jidString = [NSString stringWithFormat:@"%@@%@",username, kBBTXMPPServer];
            [[BBTXMPPManager sharedManager] sendInvitationToJID:jidString];
        }
                                        failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject)
        {
            /// username is invalid, so let user know this failed
            [BBTHTTPManager alertWithTitle:@"Username is invalid" message:@"That username didn't seem to work."];
        }];
    }
    // clear alertView text;
    [alertView textFieldAtIndex:0].text = @"";
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    // only enable save button if there is text in the textfield.
    return ([[alertView textFieldAtIndex:0].text length] > 0);
}


#pragma mark -  UISearchDisplayDelegate
- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [super searchDisplayControllerWillEndSearch:controller];
    [self endSearch];
    // reset fetchedResultsController which is cleared out when we begin search
    [self setupFetchedResultsController];
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
                                     forURL:kBBTRESTSearchUsers
                                 parameters:parameters
                                    success:^(NSURLSessionDataTask *task, id responseObject)
     {
         // get array of dictionaries in search results
         NSArray *searchResultsJSON = [responseObject objectForKey:kBBTRESTListResultsKey];
         
         // put search results in core data
         NSManagedObjectContext *managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;
         [managedObjectContext performBlockAndWait:^{
             NSArray *searchResults = [BBTUser usersWithUserInfoArray:searchResultsJSON inManagedObjectContext:managedObjectContext];
             
             // update the search result's users' friendship status asynchronously
             [managedObjectContext performBlock:^{
                 [BBTUser checkUsersAgainstRoster:searchResults];
             }];
         }];
                  
         
         // get unique key (usernames) of users in search results
         NSMutableArray *usernames = [[NSMutableArray alloc] init];
         for (NSDictionary *userDictionary in searchResultsJSON) {
             [usernames addObject:[userDictionary[kBBTRESTUserUsernameKey] description]];
         }
         
         // now reconfigure the searchFRC
         // this has a side-effect of reloading the tableView so use main thread.
         dispatch_async(dispatch_get_main_queue(), ^{
             [self setupSearchFetchedResultsControllerForUsers:usernames];
         });
     }
                                    failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject)
     {
         // failed search so clear out searchFRC
         // this has a side-effect of reloading the tableView so use main thread.
         dispatch_async(dispatch_get_main_queue(), ^{
             self.searchFetchedResultsController = nil;
         });
     }];
    
    return NO;
}

#pragma mark Helper
/**
 * Configure searchFetchedResultsController to only show data of a given
 * set of users (that were pulled from search results)
 *
 * @param usernames List of user usernames to restrict objects to.
 */
- (void)setupSearchFetchedResultsControllerForUsers:(NSArray *)usernames
{
    NSManagedObjectContext *managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTUser"];
    
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"username"
                                                        ascending:YES];
    
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(username IN[c] %@)", usernames];
    
    [request setSortDescriptors:@[sd1]];
    [request setPredicate:predicate];
    [request setFetchBatchSize:20];
    
    self.searchFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
}


#pragma mark - Navigation
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
                fromIndexPath:(NSIndexPath *)indexPath
{
    XMPPUserCoreDataStorageObject *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([vc isKindOfClass:[BBTContactConversationCDCVC class]]) {
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:@"modalConversationSegue"]) {
            
            BBTContactConversationCDCVC *conversationVC = (BBTContactConversationCDCVC *)vc;
            conversationVC.contact = user;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    // account for the fact that the destination VC is modally presented but in a
    // Navigation View Controller
    id destinationVC = segue.destinationViewController;
    if ([destinationVC isKindOfClass:[UINavigationController class]]) {
        destinationVC = [((UINavigationController *)destinationVC).viewControllers firstObject];
    }
    
    [self prepareViewController:destinationVC
                       forSegue:segue.identifier
                  fromIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id detailVC = [self.splitViewController.viewControllers lastObject];
    if ([detailVC isKindOfClass:[UINavigationController class]]) {
        detailVC = [((UINavigationController *)detailVC).viewControllers firstObject];
        [self prepareViewController:detailVC
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}


#pragma mark Disabling Chats
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"modalConversationSegue"]) {
        return NO;
    }
    return YES;
}

@end
