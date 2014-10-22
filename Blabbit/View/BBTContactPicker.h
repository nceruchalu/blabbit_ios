//
//  BBTContactPicker.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/29/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBContactModel.h"
#import "MBContactCollectionView.h"
#import "MBContactCollectionViewContactCell.h"
#import "MBContactCollectionViewPromptCell.h"
#import "MBContactCollectionViewEntryCell.h"

@class BBTContactPicker;

@protocol BBTContactPickerDataSource <NSObject>

@optional

- (NSArray *)contactModelsForContactPicker:(BBTContactPicker*)contactPickerView;
- (NSArray *)selectedContactModelsForContactPicker:(BBTContactPicker*)contactPickerView;

@end


@protocol BBTContactPickerDelegate <MBContactCollectionViewDelegate>

@optional

- (void)contactPicker:(BBTContactPicker*)contactPicker didUpdateContentHeightTo:(CGFloat)newHeight;
- (void)didShowFilteredContactsForContactPicker:(BBTContactPicker*)contactPicker;
- (void)didHideFilteredContactsForContactPicker:(BBTContactPicker*)contactPicker;

@end

/**
 * BBTContactPicker is an implementation of a contact picker that works similar
 * to what we are familiar with in Apple Mail app for iOS7.
 * This class is heavily based on MBContactPicker and serves as a drop-in 
 * replacement for it.
 */
@interface BBTContactPicker : UIView <UITableViewDataSource,
                                        UITableViewDelegate,
                                        MBContactCollectionViewDelegate>

#pragma mark - Properties, readonly
/**
 * Array of selected contacts
 */
@property (strong, nonatomic, readonly) NSArray *contactsSelected;

/**
 * Current height of contact picker collection view
 */
@property (nonatomic, readonly) CGFloat currentContentHeight;

/**
 * Height of keyboard frame.
 */
@property (nonatomic, readonly) CGFloat keyboardHeight;


#pragma mark - Properties, readwrite
/**
 * ContactPicker's Delegate
 */
@property (weak, nonatomic) IBOutlet id<BBTContactPickerDelegate> delegate;

/**
 * ContactPicker Data Source
 */
@property (weak, nonatomic) IBOutlet id<BBTContactPickerDataSource> datasource;

/**
 * Contact Picker prompt string
 */
@property (copy, nonatomic) NSString *prompt;

/**
 * Height of each item in contact picker. An item here being a selected contact.
 */
@property (nonatomic) NSInteger cellHeight;

/**
 * Maximum number of visible rows in contact picker's collection view.
 * If the contact items need more rows than this the scrollview will handle it
 */
@property (nonatomic) CGFloat maxVisibleRows;

/**
 * Contact Picker's animation speed which isn't used by this class but is saved
 *   here so that other classes incorporating this class can be sure of using
 *   consistent animation speeds
 */
@property (nonatomic) CGFloat animationSpeed;

/**
 * This BOOL configures the ContactPicker to show you contacts which have already
 *   been added to the collection as options for completion, but discards them
 *   when you choose them to prevent duplicate contacts in the collection.
 * This is set to YES by default to be consistent with the behavior of Apple's
 *   `Mail.app`, but is arguably a deficient user experience.
 */
@property (nonatomic) BOOL allowsCompletionOfSelectedContacts;

/**
 * Use this to set the enabledness of the BBTContactPicker control. The default
 * is YES
 */
@property (nonatomic) BOOL enabled;

/**
 * This BOOL configures if the prompt is shown. The default is YES
 */
@property (nonatomic) BOOL showPrompt;

#pragma mark - Instance Methods
/**
 * Reload the contacts in the Contact Picker's collection
 */
- (void)reloadData;

@end
