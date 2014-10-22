//
//  BBTContactPicker.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/29/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTContactPicker.h"
#import "BBTRosterTableViewCell.h"
#import "XMPPUserCoreDataStorageObject+BBTUserModel.h"
#import "BBTRosterTVCHelper.h"

// Constants
static const CGFloat kMaxVisibleRows = 2;
static NSString *const kMBPrompt = @"To:";
static const CGFloat kAnimationSpeed = .25;
static NSString *const searchTableCellIdentifier = @"BBTContactPickerCell";


@interface BBTContactPicker ()

// Properties; readonly publicly but readwrite privately
@property (nonatomic, readwrite) CGFloat keyboardHeight;

// These properties are weak as they are of no use if not in the view hierarchy.
@property (weak, nonatomic) MBContactCollectionView *contactCollectionView;
@property (weak, nonatomic) UITableView *searchTableView;

@property (strong, nonatomic) NSArray *filteredContacts;
@property (strong, nonatomic) NSArray *contacts;

@property (nonatomic) CGSize contactCollectionViewContentSize;
@property (nonatomic) CGFloat originalHeight;
@property (nonatomic) CGFloat originalYOffset;
@property (nonatomic) BOOL hasLoadedData;

@end


@implementation BBTContactPicker

#pragma mark - Properties

- (NSArray*)contactsSelected
{
    // selected contacts are actually saved in collection view
    return self.contactCollectionView.selectedContacts;
}

- (CGFloat)currentContentHeight
{
    // content height has to fit at least one row and has to be less than or equal
    // to height given the maximum number of visible rows. We will take the minimum
    // of these two extremes.
    CGFloat minimumSizeWithContent = MAX(self.cellHeight, self.contactCollectionViewContentSize.height);
    CGFloat maximumSize = self.maxVisibleRows * self.cellHeight;
    return MIN(minimumSizeWithContent, maximumSize);
}

- (void)setPrompt:(NSString *)prompt
{
    _prompt = [prompt copy];
    self.contactCollectionView.prompt = _prompt;
}

- (NSInteger)cellHeight
{
    return self.contactCollectionView.cellHeight;
}

- (void)setCellHeight:(NSInteger)cellHeight
{
    self.contactCollectionView.cellHeight = cellHeight;
    [self.contactCollectionView.collectionViewLayout invalidateLayout];
}

- (void)setMaxVisibleRows:(CGFloat)maxVisibleRows
{
    _maxVisibleRows = maxVisibleRows;
    [self.contactCollectionView.collectionViewLayout invalidateLayout];
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    
    self.contactCollectionView.allowsSelection = enabled;
    self.contactCollectionView.allowsTextInput = enabled;
    
    if (!enabled)
    {
        [self resignFirstResponder];
    }
}

- (void)setShowPrompt:(BOOL)showPrompt
{
    _showPrompt = showPrompt;
    self.contactCollectionView.showPrompt = showPrompt;
}


#pragma mark - Initialization
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    // use default prompt and show it.
    self.prompt = kMBPrompt;
    self.showPrompt = YES;
    
    self.originalHeight = -1;
    self.originalYOffset = -1;
    self.maxVisibleRows = kMaxVisibleRows;
    self.animationSpeed = kAnimationSpeed;
    self.allowsCompletionOfSelectedContacts = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.clipsToBounds = YES;
    self.enabled = YES;
    
    // border color will be same as that used for UITableViewCell
    UIColor *borderColor = [UIColor colorWithRed:224/255.0
                                           green:224/255.0
                                            blue:224/255.0
                                           alpha:1.0];
    
    // setup contact picker's collection view
    MBContactCollectionView *contactCollectionView = [MBContactCollectionView contactCollectionViewWithFrame:self.bounds];
    contactCollectionView.contactDelegate = self;
    contactCollectionView.clipsToBounds = YES;
    contactCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    contactCollectionView.layer.borderColor = borderColor.CGColor;
    contactCollectionView.layer.borderWidth = 1.0;
    // background color will be same as that used for UINavigationBar
    contactCollectionView.backgroundColor = [UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1.0];
    [self addSubview:contactCollectionView];
    self.contactCollectionView = contactCollectionView;
    
    // setup contact picker's table view
    UITableView *searchTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height, self.bounds.size.width, 0)];
    searchTableView.dataSource = self;
    searchTableView.delegate = self;
    searchTableView.translatesAutoresizingMaskIntoConstraints = NO;
    searchTableView.hidden = YES;
    [self addSubview:searchTableView];
    self.searchTableView = searchTableView;
    
    // setup tableView's cell
    // load the NIB file
    UINib *nib = [UINib nibWithNibName:@"BBTRosterTableViewCell" bundle:nil];
    // register this NIB, which contains the cell
    [self.searchTableView registerNib:nib forCellReuseIdentifier:searchTableCellIdentifier];
    
    // setup layout constraints
    [contactCollectionView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [searchTableView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[contactCollectionView(>=%ld,<=%ld)][searchTableView(>=0)]|", (long)self.cellHeight, (long)self.cellHeight]
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(contactCollectionView, searchTableView)]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contactCollectionView]-(0@500)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(contactCollectionView)]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contactCollectionView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(contactCollectionView)]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchTableView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(searchTableView)]];
    
    
#ifdef DEBUG_BORDERS
    self.layer.borderColor = [UIColor grayColor].CGColor;
    self.layer.borderWidth = 1.0;
    contactCollectionView.layer.borderColor = [UIColor redColor].CGColor;
    contactCollectionView.layer.borderWidth = 1.0;
    searchTableView.layer.borderColor = [UIColor blueColor].CGColor;
    searchTableView.layer.borderWidth = 1.0;
#endif
}


#pragma mark - Instance Methods
- (void)reloadData
{
    self.contactCollectionView.selectedContacts = [[NSMutableArray alloc] init];
    
    if ([self.datasource respondsToSelector:@selector(selectedContactModelsForContactPicker:)])
    {
        [self.contactCollectionView.selectedContacts addObjectsFromArray:[self.datasource selectedContactModelsForContactPicker:self]];
    }
    
    self.contacts = [self.datasource contactModelsForContactPicker:self];
    
    [self.contactCollectionView reloadData];
    [self.contactCollectionView performBatchUpdates:^{
    } completion:^(BOOL finished) {
        [self.contactCollectionView scrollToEntryAnimated:NO onComplete:nil];
    }];
}

- (void)showSearchTableView
{
    self.searchTableView.hidden = NO;
    if ([self.delegate respondsToSelector:@selector(didShowFilteredContactsForContactPicker:)])
    {
        [self.delegate didShowFilteredContactsForContactPicker:self];
    }
}

- (void)hideSearchTableView
{
    self.searchTableView.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(didHideFilteredContactsForContactPicker:)])
    {
        [self.delegate didHideFilteredContactsForContactPicker:self];
    }
}

- (void)updateCollectionViewHeightConstraints
{
    for (NSLayoutConstraint *constraint in self.constraints)
    {
        if (constraint.firstItem == self.contactCollectionView)
        {
            if (constraint.firstAttribute == NSLayoutAttributeHeight)
            {
                if (constraint.relation == NSLayoutRelationGreaterThanOrEqual)
                {
                    constraint.constant = self.cellHeight;
                }
                else if (constraint.relation == NSLayoutRelationLessThanOrEqual)
                {
                    constraint.constant = self.currentContentHeight;
                }
            }
        }
    }
}


#pragma mark - UIView method overrides
- (void)didMoveToWindow
{
    if (self.window)
    {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(keyboardChangedStatus:) name:UIKeyboardWillShowNotification object:nil];
        [nc addObserver:self selector:@selector(keyboardChangedStatus:) name:UIKeyboardWillHideNotification object:nil];
        
        if (!self.hasLoadedData)
        {
            [self reloadData];
            self.hasLoadedData = YES;
        }
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow == nil)
    {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}


#pragma mark - Keyboard Notification Handling
- (void)keyboardChangedStatus:(NSNotification*)notification
{
    CGRect keyboardRect;
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];
    self.keyboardHeight = keyboardRect.size.height;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredContacts.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // get a new or recycled cell
    BBTRosterTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:searchTableCellIdentifier
                                                                          forIndexPath:indexPath];
    
    // get user to populate cell with
    XMPPUserCoreDataStorageObject *user =  (XMPPUserCoreDataStorageObject *)self.filteredContacts[indexPath.row];
    
    // configure the cell
    [BBTRosterTVCHelper configureCell:cell withUser:user];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MBContactPickerModelProtocol> model = self.filteredContacts[indexPath.row];
    
    [self hideSearchTableView];
    [self.contactCollectionView addToSelectedContacts:model withCompletion:^{
        [self becomeFirstResponder];
    }];
    
    
}

#pragma mark - ContactCollectionViewDelegate

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView willChangeContentSizeTo:(CGSize)newSize
{
    if (!CGSizeEqualToSize(self.contactCollectionViewContentSize, newSize))
    {
        self.contactCollectionViewContentSize = newSize;
        [self updateCollectionViewHeightConstraints];
        
        if ([self.delegate respondsToSelector:@selector(contactPicker:didUpdateContentHeightTo:)])
        {
            [self.delegate contactPicker:self didUpdateContentHeightTo:self.currentContentHeight];
        }
    }
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView entryTextDidChange:(NSString*)text
{
    if ([text isEqualToString:@" "])
    {
        [self hideSearchTableView];
    }
    else
    {
        [self.contactCollectionView.collectionViewLayout invalidateLayout];
        
        [self.contactCollectionView performBatchUpdates:^{
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self.contactCollectionView setFocusOnEntry];
        }];
        
        [self showSearchTableView];
        NSString *searchString = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSPredicate *predicate;
        if (self.allowsCompletionOfSelectedContacts) {
            predicate = [NSPredicate predicateWithFormat:@"contactTitle contains[cd] %@", searchString];
        } else {
            predicate = [NSPredicate predicateWithFormat:@"contactTitle contains[cd] %@ && !SELF IN %@", searchString, self.contactCollectionView.selectedContacts];
        }
        self.filteredContacts = [self.contacts filteredArrayUsingPredicate:predicate];
        [self.searchTableView reloadData];
    }
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didRemoveContact:(id<MBContactPickerModelProtocol>)model
{
    if ([self.delegate respondsToSelector:@selector(contactCollectionView:didRemoveContact:)])
    {
        [self.delegate contactCollectionView:contactCollectionView didRemoveContact:model];
    }
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didAddContact:(id<MBContactPickerModelProtocol>)model
{
    if ([self.delegate respondsToSelector:@selector(contactCollectionView:didAddContact:)])
    {
        [self.delegate contactCollectionView:contactCollectionView didAddContact:model];
    }
}

- (void)contactCollectionView:(MBContactCollectionView*)contactCollectionView didSelectContact:(id<MBContactPickerModelProtocol>)model
{
    if ([self.delegate respondsToSelector:@selector(contactCollectionView:didSelectContact:)])
    {
        [self.delegate contactCollectionView:contactCollectionView didSelectContact:model];
    }
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

- (BOOL)becomeFirstResponder
{
    if (!self.enabled)
    {
        return NO;
    }
    
    if (![self isFirstResponder])
    {
        if (self.contactCollectionView.indexPathOfSelectedCell)
        {
            [self.contactCollectionView scrollToItemAtIndexPath:self.contactCollectionView.indexPathOfSelectedCell atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
        }
        else
        {
            [self.contactCollectionView setFocusOnEntry];
        }
    }
    
    return YES;
}

- (BOOL)resignFirstResponder
{
    return [self.contactCollectionView resignFirstResponder];
}



@end
