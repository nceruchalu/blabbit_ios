//
//  BBTConversationsCDTVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/23/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTConversationsCDTVC.h"
#import "BBTConversationCDCVC.h"
#import "BBTModelManager.h"

@interface BBTConversationsCDTVC ()

/**
 * need this property to get a handle to the database
 */
@property (strong, nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;

@end

@implementation BBTConversationsCDTVC

#pragma mark - Properties

/**
 * This view controller cannot function until the managed object context is set
 */
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    [self setupFetchedResultsController];
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // setup the managedObjectContext @property which can change with re-authentication
    self.managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;

    // register observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextReady:)
                                                 name:kBBTMOCAvailableNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTMOCAvailableNotification
                                                  object:nil];
}


#pragma mark - UITableViewDelegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


#pragma mark - Instance Methods (public)
#pragma mark Abstract
- (void)setupFetchedResultsController
{
    return; // abstract
}



#pragma mark Notification Observer Methods

/**
 * ManagedObjectContext now available from BBTModelManager so update local copy
 */
- (void)managedObjectContextReady:(NSNotification *)aNotification
{
    self.managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;
}


#pragma mark - Navigation
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
                fromIndexPath:(NSIndexPath *)indexPath
                  ofTableView:(UITableView *)tableView
{
    if ([vc isKindOfClass:[BBTConversationCDCVC class]]) {
        // show an already-existent conversation
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:@"showConversation"]) {
            // get conversation
            NSFetchedResultsController *fetchedResultsController = [self fetchedResultsControllerForTableView:tableView];
            id <BBTConversation> conversation = [fetchedResultsController objectAtIndexPath:indexPath];
            
            BBTConversationCDCVC *conversationVC = (BBTConversationCDCVC *)vc;
            conversationVC.conversation = conversation;
            // a conversation VC shouldn't have to deal with tab bars. It's
            // just not the iOS way.
            conversationVC.hidesBottomBarWhenPushed = YES;
        }
        
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    UITableView *tableView = self.searchDisplayController.active ? self.searchDisplayController.searchResultsTableView : self.tableView;
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [tableView indexPathForCell:sender];
    }
    
    // account for the fact that the destination VC could be modally presented
    // as the root view controller of a Navigation View Controller
    id destinationVC = segue.destinationViewController;
    if ([destinationVC isKindOfClass:[UINavigationController class]]) {
        destinationVC = [((UINavigationController *)destinationVC).viewControllers firstObject];
    }
    
    [self prepareViewController:destinationVC
                       forSegue:segue.identifier
                  fromIndexPath:indexPath
                    ofTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id detailVC = [self.splitViewController.viewControllers lastObject];
    if ([detailVC isKindOfClass:[UINavigationController class]]) {
        detailVC = [((UINavigationController *)detailVC).viewControllers firstObject];
        [self prepareViewController:detailVC
                           forSegue:nil
                      fromIndexPath:indexPath
                        ofTableView:tableView];
    }
}


@end
