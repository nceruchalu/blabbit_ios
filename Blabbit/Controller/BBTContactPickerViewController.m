//
//  BBTContactPickerViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/29/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTContactPickerViewController.h"
#import "BBTXMPPManager.h"
#import <CoreData/CoreData.h>

static const NSUInteger kContactPickerHeight = 40;

@interface BBTContactPickerViewController () <BBTContactPickerDataSource>

@property (weak, nonatomic) IBOutlet BBTContactPicker *contactPickerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactPickerViewHeightConstraint;

@property (strong, nonatomic, readwrite) NSArray *contacts;

@end

@implementation BBTContactPickerViewController

#pragma mark - Properties
- (NSArray *)selectedContacts
{
    return self.contactPickerView.contactsSelected;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup contactPicker
    self.contactPickerView.cellHeight = kContactPickerHeight;
    [[MBContactCollectionViewContactCell appearance] setTintColor:[UIColor orangeColor]];
    self.contactPickerView.delegate = self;
    self.contactPickerView.datasource = self;
    
    // setup contact list
    NSFetchRequest *request = [self friendsFetchRequest];
    NSManagedObjectContext *managedObjectContext = [BBTXMPPManager sharedManager].managedObjectContextRoster;
    self.contacts = [managedObjectContext executeFetchRequest:request error:NULL];
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Generate a fetch request that would pull all the user's friends
 */
- (NSFetchRequest *)friendsFetchRequest
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPUserCoreDataStorageObject"];
    
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum"
                                                        ascending:YES];
    NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName"
                                                        ascending:YES
                                                         selector:@selector(caseInsensitiveCompare:)];
    // show contacts that are user's friends
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subscription == \"both\""];
    
    [request setSortDescriptors:@[sd1, sd2]];
    [request setPredicate:predicate];
    
    return request;
}

#pragma mark - BBTContactPickerDataSource

// Use this method to give the contact picker the entire set of possible contacts
- (NSArray *)contactModelsForContactPicker:(BBTContactPicker *)contactPickerView
{
    return self.contacts;
}

// Use this method to pre-populate contacts in the picker view. Optional
- (NSArray *)selectedContactModelsForContactPicker:(BBTContactPicker *)contactPickerView
{
    return @[];
}

#pragma mark - BBTContactPickerDelegate

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didSelectContact:(id<MBContactPickerModelProtocol>)model
{
    //Selected model
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didAddContact:(id<MBContactPickerModelProtocol>)model
{
    //Added model
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didRemoveContact:(id<MBContactPickerModelProtocol>)model
{
    //Removed model
}

// This delegate method is called to allow the parent view to increase the size of
// the contact picker view to show the search table view
- (void)didShowFilteredContactsForContactPicker:(BBTContactPicker *)contactPicker
{
    if (self.contactPickerViewHeightConstraint.constant <= contactPicker.currentContentHeight)
    {
        [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
            CGRect pickerRectInWindow = [self.view convertRect:contactPicker.frame fromView:nil];
            CGFloat newHeight = self.view.window.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight;
            // to ensure we don't break layout constraints, new height must be
            // at least a contactPicker cell's height.
            newHeight = MAX(newHeight, contactPicker.cellHeight);
            self.contactPickerViewHeightConstraint.constant = newHeight;
            [self.view layoutIfNeeded];
        }];
    }
}

// This delegate method is called to allow the parent view to decrease the size of
// the contact picker view to hide the search table view
- (void)didHideFilteredContactsForContactPicker:(BBTContactPicker *)contactPicker
{
    if (self.contactPickerViewHeightConstraint.constant > contactPicker.currentContentHeight)
    {
        [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
            self.contactPickerViewHeightConstraint.constant = contactPicker.currentContentHeight;
            [self.view layoutIfNeeded];
        }];
    }
}

// This delegate method is invoked to allow the parent to increase the size of the
// collectionview that shows which contacts have been selected. To increase or decrease
// the number of rows visible, change the maxVisibleRows property of the BBTContactPicker
- (void)contactPicker:(BBTContactPicker *)contactPicker didUpdateContentHeightTo:(CGFloat)newHeight
{
    self.contactPickerViewHeightConstraint.constant = newHeight;
    [UIView animateWithDuration:contactPicker.animationSpeed animations:^{
        [self.view layoutIfNeeded];
    }];
}

@end
