//
//  BBTConversationCDCVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/17/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTConversationCDCVC.h"
#import "BBTXMPPManager.h"
#import "BBTMessage+XMPP.h"
#import "BBTMessage+JSQMessageData.h"
#import "BBTGroupConversation+XMPP.h"
#import "BBTMessagesCollectionViewCellSystem.h"
#import "BBTModelManager.h"
#import "BBTUser+HTTP.h"
#import "BBTHTTPManager.h"

// Constants
// show a timestamp every kTimeStampFrequency messages.
static const NSUInteger kTimeStampFrequency = 3;
// number of messages to load on a page
static const NSUInteger kMessagesPerPage = 3;

// message colors (message text and bubble)
#define kBBTOutgoingMessageColor [UIColor whiteColor]
#define kBBTOutgoingBubbleColor kBBTThemeColor

#define kBBTIncomingMessageColor [UIColor blackColor]
#define kBBTIncomingBubbleColor [UIColor jsq_messageBubbleLightGrayColor]


@interface BBTConversationCDCVC ()

/**
 * configure this property to get a handle to the database
 */
@property (strong, nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;

// chat bubbles
@property (strong, nonatomic) UIImageView *outgoingBubbleImageView;
@property (strong, nonatomic) UIImageView *incomingBubbleImageView;

/**
 * need current page for pagination (0-indexed pages for simplicity of initialization)
 */
@property (nonatomic) NSUInteger currentPage;

/**
 * number of new messages (in & out). This is tracked so that we can account for 
 * them when changing page.
 */
@property (nonatomic) NSUInteger newMessageCount;

/**
 * keep track of the conversation room Name separately as groupchat conversations
 *   could be deleted by their owners and we don't want to reference the conversation
 *   property at that point. However we will use this property to figure out if
 *   the current conversation is the victim of a delete operation.
 * There are more complex ways to tell if an NSManagedObject has been deleted
 *   but this is a lot easier.
 *
 * @see http://stackoverflow.com/a/7896369
 */
@property (copy, nonatomic) NSString *conversationRoomName;


/**
 *  The collection view cell identifier to use for dequeuing system message
 *  collection view cells in the collectionView.
 *
 *  @discussion The default value is the string returned by 
 *      `[BBTMessagesCollectionViewCellSystem cellReuseIdentifier]`.
 *      This value must not be `nil`.
 *
 *  @see `BBTMessagesCollectionViewCellSystem`.
 *
 *  @warning Overriding this property's default value is *not* recommended.
 *  You should only override this property's default value if you are proividing your own cell prototypes.
 *  These prototypes must be registered with the collectionView for reuse and you are then responsible for
 *  completely overriding many delegate and data source methods for the collectionView,
 *  including `collectionView:cellForItemAtIndexPath:`.
 */
@property (copy, nonatomic) NSString *systemCellIdentifier;


@end

@implementation BBTConversationCDCVC

#pragma mark - Properties
@synthesize conversation = _conversation;

- (id<BBTConversation>)conversation
{
    // this isn't quite lazy instantiation as this property should be setup before
    // view is done loading... but in the event this isn't the case handle it now.
    if (!_conversation) [self setupConversation];
    return _conversation;
}

- (NSMutableDictionary *)avatars
{
    // lazy instantiation
    if (!_avatars) _avatars = [[NSMutableDictionary alloc] init];
    return _avatars;
}

// changing the current page requires updating the fetchRequestsController
// to fetch new data.
- (void)setCurrentPage:(NSUInteger)currentPage
{
    // update currentPage to account for the new messages by counting how many pages
    // the new messages account for and adding that to the current page
    NSUInteger pagesFromNewMessages = (NSUInteger)ceil((double)self.newMessageCount/kMessagesPerPage);
    _currentPage = currentPage + pagesFromNewMessages;
    
    // reset counter of new messages
    self.newMessageCount = 0;
    
    // get number of messages in VC now
    NSUInteger oldMessageCount = [self.collectionView numberOfItemsInSection:0];
    
    [self setupFetchedResultsController];
    
    // get number of new messages added to VC and scroll by that amount so the user
    // still sees the last message they were on prior to loading more messages
    // this effectively simulates "inserting more messages" when we really reloaded.
    NSUInteger newMessageCount = [self.collectionView numberOfItemsInSection:0];
    NSUInteger addedMessageCount = MAX(newMessageCount - oldMessageCount, 0);
    NSIndexPath *lastMessageIndexPath = [NSIndexPath indexPathForItem:addedMessageCount inSection:0];
    [self.collectionView scrollToItemAtIndexPath:lastMessageIndexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                        animated:NO];
}

// Configuring conversation means that conversation is about to be viewed so make
// make method call for when a message has been received while conversation is active.
//
// Also setup view controller's title so we know which conversation we are viewing
- (void)setConversation:(id<BBTConversation>)conversation
{
    // configure conversation when it is set for a viewing
    _conversation = conversation;
    [_conversation finishReceivingMessage];
    
    if ([conversation isKindOfClass:[BBTGroupConversation class]]) {
        BBTGroupConversation *groupConversation = (BBTGroupConversation *)_conversation;
        self.title = @"Comments";
        // keep track of the roomName separately incase the conversation object
        // is deleted while we are actively on here.
        self.conversationRoomName = groupConversation.roomName;
    } else {
        
        BBTUser *conversationContact = (BBTUser *)_conversation;
        self.title = [conversationContact formattedName];
    }
}

/**
 * This view controller cannot function until the managed object context is set
 */
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    // The logic for pagination and showing a "load earlier messages" button
    // depends on using NSFetchRequest's fetchOffset property. However whenever
    // an NSManagedObjectContext has unsaved changes the fetchOffset is ignored.
    // This seems like a CoreData bug, but the simple fix is when managed object
    // context is finally set for the view controller force a save on it.
    // You may be wondering why we only need to do a save 1 time and the reason
    // is once this VC is loaded any new messages that are submitted won't ever
    // be hidden. So users don't need to tap the "load earlier messages" button
    // to view any new messages.
    [[BBTModelManager sharedManager] saveUserDocument:^{
        // managed object context has been setup so enable VC for user interaction and
        // setup properties that depend on its existence: fetchedResultsController and avatars
        [self enableUserInteraction];
        
        [self setupFetchedResultsController];
        [self setupAvatarsForConversation];
    }];
}


#pragma mark - View Lifecycle
/**
 *  Override point for customization.
 *
 *  Customize your view.
 *  Look at the properties on `JSQMessagesViewController` to see what is possible.
 *
 *  Customize your layout.
 *  Look at the properties on `JSQMessagesCollectionViewFlowLayout` to see what is possible.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup the managedObjectContext @property
    [self setupManagedObjectContext];
    
    // configure our sender to be same as what we configure for outgoing messages
    // in [BBTMessage -sender] so that we aren't affected by username changes.
    self.sender = [[BBTXMPPManager sharedManager].xmppStream.myJID user];
    
    // only enable send button if there's text in there and remove camera button
    // since media messages are not yet implemented.
    // Note that you can set a custom `leftBarButtonItem` and a custom `rightBarButtonItem`
    BOOL hasText = [self.inputToolbar.contentView.textView hasText];
    
    if (self.inputToolbar.sendButtonOnRight) {
        self.inputToolbar.contentView.rightBarButtonItem.enabled = hasText;
        [self.inputToolbar.contentView.rightBarButtonItem setTitleColor:kBBTOutgoingBubbleColor forState:UIControlStateNormal];
        self.inputToolbar.contentView.leftBarButtonItem = nil;
    } else {
        self.inputToolbar.contentView.leftBarButtonItem.enabled = hasText;
        [self.inputToolbar.contentView.leftBarButtonItem setTitleColor:kBBTOutgoingBubbleColor forState:UIControlStateNormal];
        self.inputToolbar.contentView.rightBarButtonItem = nil;
    }
    
    // Create bubble images.
    // Be sure to create your avatars one time and reuse them for good performance.
    self.outgoingBubbleImageView = [JSQMessagesBubbleImageFactory
                                    outgoingMessageBubbleImageViewWithColor:kBBTOutgoingBubbleColor];
    
    self.incomingBubbleImageView = [JSQMessagesBubbleImageFactory
                                    incomingMessageBubbleImageViewWithColor:kBBTIncomingBubbleColor];
    
    // Set placeholder text
    self.inputToolbar.contentView.textView.placeHolder = @"New comment";
    
    // setup new system cell identifier
    self.systemCellIdentifier = [BBTMessagesCollectionViewCellSystem cellReuseIdentifier];
    // register this NIB, which contains the cell
    [self.collectionView registerNib:[BBTMessagesCollectionViewCellSystem nib]
          forCellWithReuseIdentifier:self.systemCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Enable/disable springy bubbles, default is YES.
    // For best results, toggle from `viewDidAppear:`
    // At this time I'll disable this because it results in Heavy CPU utilization
    //   https://github.com/jessesquires/JSQMessagesViewController/issues/281
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Add Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessageReceived:)
                                                 name:kBBTMessageNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusUpdateReceived:)
                                                 name:kBBTChatStateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(groupConversationDeleted:)
                                                 name:kBBTConversationDeleteNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTMessageNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTChatStateNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTConversationDeleteNotification
                                                  object:nil];
}


#pragma mark - Instance methods (public)
#pragma mark Abstract
- (void)setupConversation
{
    return; // abstract
}

#pragma mark Concrete
/**
 * Start populating the avatars property with any users we know are in
 *   conversation
 * It's safe to assume this function is only called when there's a managedObjectContext
 *
 * @warning self.avatars object keys should use consistent logic as in [BBTMessage -sender]
 */
- (void)setupAvatarsForConversation
{
    // diameters of incoming and outgoing avatar images
    CGFloat incomingDiameter = self.collectionView.collectionViewLayout.incomingAvatarViewSize.width;
    CGFloat outgoingDiameter = self.collectionView.collectionViewLayout.outgoingAvatarViewSize.width;
    
    
    // setup app user's avatar image
    NSString *myUsername = [[BBTXMPPManager sharedManager].xmppStream.myJID user];
    UIImage *myAvatarImage = [self avatarWithInitialsForUsername:myUsername
                                                        diameter:outgoingDiameter];
    [self.avatars setObject:myAvatarImage forKey:myUsername];
    
    // now setup avatar images of other users in conversation
    if ([self.conversation isKindOfClass:[BBTGroupConversation class]]) {
        // for a groupchat conversation first get the current list of conversation
        //   occupants.
        // Remember this list will change and new occupants can come on board at any time so be
        //   prepared for that.
        NSManagedObjectContext *context = [BBTXMPPManager sharedManager].managedObjectContextRoom;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPRoomOccupantCoreDataStorageObject"];
        // have to do a case-insensitive comparison as XMPP server changes cases
        request.predicate = [NSPredicate predicateWithFormat:@"roomJIDStr ==[c] %@", [((BBTGroupConversation *)self.conversation) jidStr]];
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        UIImage *occupantAvatarImage = nil;
        for (XMPPRoomOccupantCoreDataStorageObject *occupant in matches) {
            occupantAvatarImage = [self avatarWithInitialsForUsername:occupant.nickname
                                                             diameter:incomingDiameter];
            // Could have keyed these avatars with [occupant.realJID bare] but
            //   then when you receive messages all you get is a nickname and you
            //   will have to link nicknames to realJIDs before saving the message.
            // Also want to prepare for changing the backend to use anonymous rooms
            //   that don't broadcast JIDs.
            // What is important is to keep the logic consistent with whatever is
            //   done in message.sender
            [self.avatars setObject:occupantAvatarImage forKey:occupant.nickname];
        }
    } else {
        // a one-on-one chat is simple... the only other avatar is that of the contact
        NSString *contactUsername = [((BBTUser *)self.conversation) username];
        UIImage *contactAvatarImage = [self avatarWithInitialsForUsername:contactUsername
                                                                 diameter:incomingDiameter];
        [self.avatars setObject:contactAvatarImage forKey:contactUsername];
    }
}


#pragma mark - Instance Methods (private)
/*
 * configure self.managedObjectContext to use the shared chats managedObjectContext
 */
- (void)setupManagedObjectContext
{
    if ([BBTModelManager sharedManager].managedObjectContext) {
        self.managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;

    } else {
        // if managedObjectContext isnt setup yet add listener for when this
        //  becomes the case. In the meantime lockdown the VC
        // Add Observers
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextReady:)
                                                     name:kBBTMOCAvailableNotification
                                                   object:nil];
        
        // lockdown the VC
        [self disableUserInteraction];
    }
}

/**
 * Creates an NSFetchRequest for BBTMessages in this BBTConversation sorted in
 *   ascending date order as this is how normal conversation UIs work.
 * This NSFetchRequest is used to build  our NSFetchedResultsController @property
 *   inherited from CoreDataTableViewController.
 *
 * Assumption: This method is only called when self.managedObjectContext has been
 *   configured.
 */
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"BBTMessage"];
        if ([self.conversation isKindOfClass:[BBTUser class]]) {
            request.predicate = [NSPredicate predicateWithFormat:@"contact = %@", self.conversation];
        } else {
            request.predicate = [NSPredicate predicateWithFormat:@"groupConversation = %@", self.conversation];
        }
        
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"localTimestamp"
                                                                  ascending:YES]];
        request.fetchBatchSize = 20;
        
        
        // pagination:
        // If the total number of messages in this conversation is more than
        //   the number of messages that could be loaded for the current page
        //   account for this with a fetchOffset, because we don't want to set a
        //   negative offset. That doesn't make sense.
        // If an offset is being set then there are more messages to load, so
        //   show user an icon saying so.
        NSUInteger totalNumberOfMessages = [self.managedObjectContext countForFetchRequest:request
                                                                                     error:NULL];

        NSUInteger maxNumberOfMessagesToLoad = (self.currentPage + 1)*kMessagesPerPage;
        if (totalNumberOfMessages > maxNumberOfMessagesToLoad) {
            request.fetchOffset = totalNumberOfMessages - maxNumberOfMessagesToLoad;
            // Don't need a fetch limit as we want to show any new messages.
            // If we didn't want to show new messages then we could probably use:
            //   request.fetchLimit = maxNumberOfMessagesToLoad;
            
            self.showLoadEarlierMessagesHeader = YES;
        } else {
            self.showLoadEarlierMessagesHeader = NO;
        }
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil
                                                                                       cacheName:nil];
    } else {
        self.fetchedResultsController = nil;
    }
}

/**
 * Generate an avatar image with initials for a given username
 * 
 * @return UIImage that can serve as an avatar with initials
 */
- (UIImage *)avatarWithInitialsForUsername:(NSString *)username
                                  diameter:(NSUInteger)diameter
{
    // first get initials from a username
    NSString *initialsFromUsername = nil;
    
    // get first 2 characters of username as initial. If there aren't up to 2
    //   character then use first character only.
    if ([username length] >= 2) {
        // 2 or more characters
        initialsFromUsername = [username substringToIndex:2];
    } else if ([username length] == 1) {
        // only one character
        initialsFromUsername = [username substringToIndex:1];
    } else {
        // an empty string... weird...
        initialsFromUsername = @"?";
    }
    
    UIImage *avatarImage = [JSQMessagesAvatarFactory avatarWithUserInitials:initialsFromUsername
                                                            backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                                                                  textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                                                                       font:[UIFont systemFontOfSize:14.0f]
                                                                   diameter:diameter];
    return avatarImage;
}


/**
 * Disable the View Controller from responding to user interaction
 */
- (void)disableUserInteraction
{
    self.inputToolbar.contentView.leftBarButtonItem.enabled = NO;
    self.inputToolbar.contentView.rightBarButtonItem.enabled = NO;
}

/**
 * Enable the View Controller for user interaction
 */
- (void)enableUserInteraction
{
    self.inputToolbar.contentView.leftBarButtonItem.enabled = YES;
    self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
}

#pragma mark Notification Observer Methods

/**
 * ManagedObjectContext now available from BBTXMPPManager
 */
- (void)managedObjectContextReady:(NSNotification *)aNotification
{
    self.managedObjectContext = [BBTModelManager sharedManager].managedObjectContext;
    
    // remove listener now
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTMOCAvailableNotification
                                                  object:nil];
}

- (void)statusUpdateReceived:(NSNotification *)aNotification
{
    BBTChatState chatState=  [[[aNotification userInfo] valueForKey:@"chatState"] integerValue];
    NSManagedObject * conversation = [[aNotification userInfo] valueForKey:@"conversation"];
    
    // only process this status update if it belongs in this conversation
    if ([[conversation objectID] isEqual:[((NSManagedObject *)self.conversation) objectID]]) {
        if (chatState == BBTChatStateComposing) {
            self.showTypingIndicator = YES;
        } else {
            self.showTypingIndicator = NO;
        }
    }
}

/**
 *  Upon receiving a message do the following
 *  1. Play sound (optional)
 *  2. Call `finishReceivingMessage`
 */
- (void)newMessageReceived:(NSNotification *)aNotification
{
    NSManagedObject *conversation = [[aNotification userInfo] valueForKey:@"conversation"];
    // only process this status update if it belongs in this conversation
    if ([[conversation objectID] isEqual:[((NSManagedObject *)self.conversation) objectID]]) {
        if ([BBTModelManager sharedManager].userSoundsSetting) {
            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        }
        [self finishReceivingMessage];
    }
}


/**
 * When the conversation is deleted clear out strong reference to it and
 * go back to previous page
 */
- (void)groupConversationDeleted:(NSNotification *)aNotification
{
    NSString *roomName = [[aNotification userInfo] valueForKey:@"roomName"];
    // only process this delete notification if it is for this conversation
    if ([roomName caseInsensitiveCompare:self.conversationRoomName] == NSOrderedSame) {
        self.conversation = nil;
        // The user will go to a disabled view controller. That's a good indicator
        // of deletion.
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark JSQMessagesCollectionViewDataSource Helper
- (id<JSQMessageData>)messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.collectionView numberOfItemsInSection:indexPath.section] > 0) {
        return [self.fetchedResultsController objectAtIndexPath:indexPath]; // a (BBTMessage *)
    } else {
        return nil;
    }
}

#pragma mark UICollectionViewDataSource Helper
- (void)configureCell:(JSQMessagesCollectionViewCell *)cell
      withSystemEvent:(BBTMessage *)message
{
    cell.textView.text = nil;
    cell.messageBubbleImageView = nil;
    cell.avatarImageView = nil;
    
    cell.cellTopLabel.attributedText = [message systemMessage];
    cell.messageBubbleTopLabel.attributedText = nil;
    cell.cellBottomLabel.attributedText = nil;
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textView.dataDetectorTypes = UIDataDetectorTypeAll;
}


#pragma mark - JSQMessagesViewController method overrides
/**
 * When finished sending/receiving messages
 * - Don't reloadData on collectionView when finished sending/receiving message
 * - Don't automatically scroll to bottom
 * - Simply hide typing indicator.
 * Using NSFetchedResultsController to make this work right.
 */
- (void)finishSendingMessage
{
    UITextView *textView = self.inputToolbar.contentView.textView;
    textView.text = nil;
    
    [self.inputToolbar toggleSendButtonEnabled];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:textView];
    
    [self finishSendingOrReceivingMessage];
}
- (void)finishReceivingMessage
{
    [self.conversation finishReceivingMessage];
    [self finishSendingOrReceivingMessage];
}
- (void)finishSendingOrReceivingMessage
{
    [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
    
    self.showTypingIndicator = NO;
    self.newMessageCount++;
}

/**
 *  Send a message with the following steps:
 *  1. Play sound (optional)
 *  2. Add new id<JSQMessageData> object to your data source
 *  3. Call `finishSendingMessage`
 *  4. For a groupchat, add yourself as convervation member if not already one.
 */
- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                    sender:(NSString *)sender
                      date:(NSDate *)date
{
    if ([BBTModelManager sharedManager].userSoundsSetting) {
        [JSQSystemSoundPlayer jsq_playMessageSentSound];
    }
    
    // Create Message with text argument as the body
    [self.conversation sendMessageWithBody:text];
    
    [self finishSendingMessage];
    
    if ([self.conversation isKindOfClass:[BBTGroupConversation class]]) {
        BBTGroupConversation *groupConversation = (BBTGroupConversation *)self.conversation;
        // if not already a conversation member, grant user membership
        [groupConversation grantMembership];
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    // Handle camera button press event.
}


#pragma mark - JSQMessagesCollectionViewDataSource
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self messageDataForItemAtIndexPath:indexPath];
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView bubbleImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIImageView *bubbleImage = nil;
    // Reuse created bubble images, but create new imageView to add to each cell
    // Otherwise, each cell would be referencing the same imageView and bubbles
    // would disappear from cells
    BBTMessage *message = [self messageDataForItemAtIndexPath:indexPath];
    
    if (![message.isIncoming boolValue]) {
        bubbleImage = [[UIImageView alloc] initWithImage:self.outgoingBubbleImageView.image
                                        highlightedImage:self.outgoingBubbleImageView.highlightedImage];
    } else {
        bubbleImage = [[UIImageView alloc] initWithImage:self.incomingBubbleImageView.image
                                        highlightedImage:self.incomingBubbleImageView.highlightedImage];
    }
    return bubbleImage;
}


/**
 * Return `nil` here if you do not want avatars.
 * If you do return `nil`, be sure to do the following in `viewDidLoad`:
 *   self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
 *   self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
 *
 * It is possible to have only outgoing avatars or only incoming avatars, too.
 *
 * Reuse created avatar images, but create new imageView to add to each cell
 * Otherwise, each cell would be referencing the same imageView and avatars would
 *   disappear from cells
 *
 * Note: these images will be sized according to these values:
 *   self.collectionView.collectionViewLayout.incomingAvatarViewSize
 *   self.collectionView.collectionViewLayout.outgoingAvatarViewSize
 *  Override the defaults in `viewDidLoad`
 */
- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BBTMessage *message = [self messageDataForItemAtIndexPath:indexPath];
    
    UIImage *avatarImage = [self.avatars objectForKey:message.sender];
    
    if (!avatarImage) {
        // if there's no avatar image yet for this sender then this is a groupchat
        //   where the sender joined the conversation after self.avatars was setup
        //   so add this here
        CGFloat incomingDiameter = self.collectionView.collectionViewLayout.incomingAvatarViewSize.width;
        avatarImage = [self avatarWithInitialsForUsername:message.sender
                                                 diameter:incomingDiameter];
        [self.avatars setObject:avatarImage forKey:message.sender];
    }
    
    return [[UIImageView alloc] initWithImage:avatarImage];
}


/**
 *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
 *  The other label text delegate methods should follow a similar pattern.
 *
 *  Show a system message or a timestamp for every kTimeStampFrequency non-system messages.
 */
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    BBTMessage *message = [self messageDataForItemAtIndexPath:indexPath];
    if ([message.isSystemEvent boolValue]) {
        return [message systemMessage];
        
    } else if (indexPath.item % kTimeStampFrequency == 0) {
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}


- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    BBTMessage *message = [self messageDataForItemAtIndexPath:indexPath];
    
    //iOS7-style sender name labels
    if (![message.isIncoming boolValue]) {
        return nil;
    }
    
    if (indexPath.item - 1 >= 0) {
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:(indexPath.item-1)
                                                             inSection:indexPath.section];
        BBTMessage *previousMessage = [self.fetchedResultsController objectAtIndexPath:previousIndexPath];
        if ([[previousMessage sender] isEqualToString:message.sender]) {
            return nil;
        }
    }
    
    // Don't specify attributes to use the defaults.
    return [[NSAttributedString alloc] initWithString:message.sender];
     */
    // This would have been a good place to return sender name labels but Blabbit
    // is an anonymous-texting app so this isn't going to happen
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - UICollectionViewDataSource

/**
 *  Configure almost *anything* on the cell
 *  Text colors, label text, label colors, etc.
 *
 *  DO NOT set `cell.textView.font` !
 *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` 
 *    to the font you want in `viewDidLoad`
 *
 *  DO NOT manipulate cell layout information!
 *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` 
 *    from `viewDidLoad`
 */
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = nil;
    BBTMessage *message = [self messageDataForItemAtIndexPath:indexPath];
    if ([message.isSystemEvent boolValue]) {
        // System messages are not covered by default JSQMessagesCollectionView
        // so will give it special treatment here
        NSString *cellIdentifier = self.systemCellIdentifier;
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        [self configureCell:cell withSystemEvent:message];
        
    } else {
        // Regular messages are handled wonderfully by JSQMessagesCollectionView
        // so let superclass do some work
        cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
        // Configure the cell...
        // set text color
        if (![message.isIncoming boolValue]) {
            cell.textView.textColor = kBBTOutgoingMessageColor;
        } else {
            cell.textView.textColor = kBBTIncomingMessageColor;
        }
        // configure appearance of hyperlinks
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}

/**
 * Override this method to set header view's text color.
 */
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *supplementaryElementView = [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    
    if ([supplementaryElementView isKindOfClass:[JSQMessagesLoadEarlierHeaderView class]]) {
        JSQMessagesLoadEarlierHeaderView *loadMoreView = (JSQMessagesLoadEarlierHeaderView *)supplementaryElementView;
        [loadMoreView.loadButton setTitleColor:kBBTThemeColor forState:UIControlStateNormal];
    }
    
    return supplementaryElementView;
}


#pragma mark - JSQMessagesCollectionViewDelegateFlowLayout
/**
 * System Event messages only need to account for CellTopLabel.
 * However regular messages should go by the default implementation of JSQMessagesViewController.
 */
- (CGSize)collectionView:(JSQMessagesCollectionView *)collectionView
                  layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BBTMessage *message = [self messageDataForItemAtIndexPath:indexPath];
    if ([message.isSystemEvent boolValue]) {
        CGFloat cellHeight = [self collectionView:collectionView layout:collectionViewLayout heightForCellTopLabelAtIndexPath:indexPath];
        return CGSizeMake(collectionViewLayout.itemWidth, cellHeight);
        
    } else {
        return [super collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    }
}

/**
 *  Each label in a cell has a `height` delegate method that corresponds to its 
 *    text dataSource method
 *
 *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
 *  The other label height delegate methods should follow similarly
 *
 *  Show a system message or a timestamp for every kTimeStampFrequency non-system messages.
 */
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    BBTMessage *message = [self messageDataForItemAtIndexPath:indexPath];
    if ([message.isSystemEvent boolValue]) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
        
    } else if (indexPath.item % kTimeStampFrequency == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    // iOS7-style sender name labels
   BBTMessage *currentMessage = [self messageDataForItemAtIndexPath:indexPath];
    if (![currentMessage.isIncoming boolValue]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 >= 0) {
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:(indexPath.item-1)
                                                             inSection:indexPath.section];
        BBTMessage *previousMessage = [self.fetchedResultsController objectAtIndexPath:previousIndexPath];
        if ([[previousMessage sender] isEqualToString:[currentMessage sender]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
     */
    // This would have been a good place to return sender name labels but Blabbit
    // is an anonymous-texting app so this isn't going to happen
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    
    return 0.0f;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView
                    didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    // user wants to load earlier messages so do so by going up to the next page
    self.currentPage++;
    
}


#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // JSQMessagesViewController does work here
    [super textViewDidBeginEditing:textView];
    
    // send chatstate to conversation
    [self.conversation sendChatState:BBTChatStateComposing];
}

- (void)textViewDidChange:(UITextView *)textView
{
    // JSQMessagesViewController does work here
    [super textViewDidChange:textView];
    
    // send chatstate to conversation
    BBTChatState status= [textView.text length] ? BBTChatStateComposing : BBTChatStateActive;
    [self.conversation sendChatState:status];
}

@end
