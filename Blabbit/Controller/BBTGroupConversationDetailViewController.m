//
//  BBTGroupConversationDetailViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/19/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTGroupConversationDetailViewController.h"
#import "BBTGroupConversation+XMPP.h"
#import "BBTGroupConversation+CLLocation.h"
#import "UIImageView+AFNetworking.h"
#import "BBTUtilities.h"
#import "BBTHTTPManager.h"
#import "BBTXMPPManager.h"
#import "BBTConversationCDCVC.h"
#import "BBTShareGroupConversationViewController.h"
#import "AFURLResponseSerialization.h"

#import <QuartzCore/QuartzCore.h>

// Constants
static const CGFloat kShadowWidth = 1.0f;

@interface BBTGroupConversationDetailViewController () <UIAlertViewDelegate>

/**
 * Constraints used in configuring height of text view.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentContainerLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentContainerTrailingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectTextViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectTextViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subjectTextViewHeightConstraint;

/**
 * Need photo imageview height constraint to effectively hide imageview when
 * there isnt a photo associated with GroupConversation
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoImageViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *contentContainerView;
@property (weak, nonatomic) IBOutlet UITextView *subjectTextView;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (weak, nonatomic) IBOutlet UILabel *expiryTimeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *locationIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UIButton *commentsButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *flagButton;

@property (nonatomic) BOOL roomInteractionEnabled;


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
 * Cache photoImageViewHeightConstraint.constant as this will be overriden
 */
@property (nonatomic) CGFloat cachedPhotoImageViewHeightConstraint;

@end

@implementation BBTGroupConversationDetailViewController

#pragma mark - Properties
// handle a model update
- (void)setConversation:(BBTGroupConversation *)conversation
{
    _conversation = conversation;
    // keep track of the roomName separately incase the conversation object
    // is deleted while we are actively on here.
    self.conversationRoomName = conversation.roomName;
    
    // We should update the detail properties by calling `-setupDetails` but
    // when a room is deleted we should get rid of our conversation object and
    // clearing out the view controller will lead to a poor user experience
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // configure views
    self.contentContainerView.layer.borderColor = kBBTLightGrayBorderColor.CGColor;
    self.contentContainerView.layer.borderWidth = 1.0f;
    
    // remove left and right padding
    self.subjectTextView.textContainer.lineFragmentPadding = 0;
    
    // Add shadow to image
    /*
    self.photoImageView.layer.shadowColor = kBBTLightGrayBorderColor.CGColor;
    self.photoImageView.layer.shadowOffset = CGSizeMake(kShadowWidth, kShadowWidth);
    self.photoImageView.layer.shadowOpacity = 1;
    self.photoImageView.layer.shadowRadius = 1.0;
    self.photoImageView.clipsToBounds = NO;
    */
    self.photoImageView.layer.borderColor = kBBTLightGrayBorderColor.CGColor;
    self.photoImageView.layer.borderWidth = kShadowWidth;
    self.photoImageView.clipsToBounds = YES;
    
    [self setupDetails];
    
    // This one time, refresh the `liked` status of user for this conversation
    [self refreshGroupConversationLiked];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // get latest version of comments count
    [self updateCommentsCountDetails];
    
    // each time the view appears we need to ensure the room still exists.
    // If it isn't successful assume something is wrong with room and freeze it
    // We do this because we don't want to create a room in the process of trying
    // to join a deleted room.
    //
    // before making the request, temporarily disable user interaction.
    // it will be enabled on a successful response
    [self disableUserInteraction];
    [self refreshGroupConversationDetails];
    
    // Add Observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMessageReceived:)
                                                 name:kBBTMessageNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(groupConversationDeleted:)
                                                 name:kBBTConversationDeleteNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(groupConversationSynced:)
                                                 name:kBBTConversationSyncNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(groupConversationJoined:)
                                                 name:kBBTConversationJoinNotification
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
                                                    name:kBBTMessageNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTConversationDeleteNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTConversationSyncNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTConversationJoinNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBBTAuthenticationNotification
                                                  object:nil];
}


#pragma mark - View Orientation
- (void)viewWillLayoutSubviews
{
    [self prepareViewsForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

#pragma mark Helpers
- (void)prepareViewsForOrientation:(UIInterfaceOrientation)orientation
{
    // is it landscape? if so make special changes
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        
    } else {
        
    }
    
    // update subject textView height
    // at this point only the view has updated its bounds so use that to derive
    // textview width
    CGFloat newTextViewWidth = self.view.bounds.size.width - self.subjectTextViewLeadingConstraint.constant - self.subjectTextViewTrailingConstraint.constant - self.contentContainerLeadingConstraint.constant - self.contentContainerTrailingConstraint.constant;
    CGSize sizeThatFitsTextView  = [self.subjectTextView sizeThatFits:CGSizeMake(newTextViewWidth, MAXFLOAT)];
    self.subjectTextViewHeightConstraint.constant = ceilf(sizeThatFitsTextView.height);
    [self.subjectTextView layoutIfNeeded];
}

#pragma mark - Instance Methods
#pragma mark Private
/**
 * Setup the properties that convey the details of this Group Conversation using
 * only data in local storage.
 */
- (void)setupDetails
{
    // set subject
    self.subjectTextView.text = self.conversation.subject;
    
    // setup photo if there is one, or hide imageview if there isn't.
    if ([self.conversation.photoURL length]) {
        [self.photoImageView setImageWithURL:[NSURL URLWithString:self.conversation.photoURL]];
        if (self.cachedPhotoImageViewHeightConstraint > 1.0f) {
            self.photoImageViewHeightConstraint.constant = self.cachedPhotoImageViewHeightConstraint;
        }
    } else {
        // cannot use a constant of 0 here as there is an aspect ratio constraint
        // on the photoImageView that isn't 1:1
        self.cachedPhotoImageViewHeightConstraint  = self.photoImageViewHeightConstraint.constant;
        self.photoImageViewHeightConstraint.constant = 1.0f;
    }
    
    // set expiry time
    NSString *expiryTime = [BBTUtilities timeLabelForConversationDate:[self.conversation expiryTime]];
    if (expiryTime) {
        self.expiryTimeLabel.text = [NSString stringWithFormat:@"Expires in %@", expiryTime];
    } else {
        self.expiryTimeLabel.text = @"Expired";
    }
    
    // set likes count as is now.
    [self updateLikesCountDetails];
    
    // set comments count
    [self updateCommentsCountDetails];
    
    // set location info
    [self updateLocationDetails];
}

/**
 * Setup the properties related to number of likes and if app user has liked group
 * Conversation
 */
- (void)updateLikesCountDetails
{
    [self.likesButton setTitle:[NSString stringWithFormat:@"%d", [self.conversation.likesCount intValue]]
                      forState:UIControlStateNormal];
    
    UIImage *likesImage;
    UIColor *textColor;
    if ([self.conversation.liked boolValue]) {
        likesImage = [UIImage imageNamed:@"num-likes-highlight"];
        textColor = kBBTThemeColor;
        
    } else {
        likesImage = [UIImage imageNamed:@"num-likes"];
        textColor = [UIColor lightGrayColor];
    }
    
    [self.likesButton setTitleColor:textColor forState:UIControlStateNormal];
    [self.likesButton setImage:likesImage forState:UIControlStateNormal];
}

/**
 * Set the number of comments associated with this group conversation
 */
- (void)updateCommentsCountDetails
{
    NSString *commentsCount = [NSString stringWithFormat:@"%lu",(unsigned long)[self.conversation.messages count]];
    [self.commentsButton setTitle:commentsCount forState:UIControlStateNormal];
}

/**
 * Set the location address associated with this group conversation
 */
- (void)updateLocationDetails
{
    if (self.conversation.location) {
        // there is a location, so show location icon/text
        self.locationIconImageView.hidden = NO;
        self.locationLabel.hidden = NO;
        
        // now set location address if it has been reverse-geocoded
        // if it hasn't do that and prepare to set location address after that
        if (self.conversation.locationAddress) {
            self.locationLabel.text = [self formattedLocationAddress];
            
        } else {
            // reverse-geocode the location and cache the results
            [[[CLGeocoder alloc] init] reverseGeocodeLocation:self.conversation.location completionHandler:^(NSArray *placemarks, NSError *error) {
                CLPlacemark *placemark = [placemarks lastObject];
                
                // cache location address and set it in UI
                self.conversation.locationAddress = [BBTGroupConversation addressForPlacemark:placemark];
                self.locationLabel.text = [self formattedLocationAddress];
            }];
        }
        
    } else {
        // no location hide location icon/text.
        self.locationIconImageView.hidden = YES;
        self.locationLabel.hidden = YES;
    }
}

/**
 * Disable user interaction with view controller, most likely because this room 
 * doesn't exist anymore
 */
- (void)disableUserInteraction
{
    self.commentsButton.enabled = NO;
    self.likesButton.enabled = NO;
    self.shareButton.enabled = NO;
    self.flagButton.enabled = NO;
    self.roomInteractionEnabled = NO;
}

/**
 * Enable user interaction with view controller, preferrably after confirming this
 * room still exists
 */
- (void)enableUserInteraction
{
    // only allow commenting if already joined conversation's xmpp room
    XMPPRoom *xmppRoom = [BBTXMPPManager sharedManager].xmppRoom;
    if ([self.conversation.roomName isEqualToString:[xmppRoom.roomJID user]] &&
        xmppRoom.isJoined) {
        self.commentsButton.enabled = YES;
    } else {
        self.commentsButton.enabled = NO;
    }
    
    
    // limit functionality for anonymous users
    BOOL authenticated = [BBTHTTPManager sharedManager].httpAuthenticated;
    self.likesButton.enabled = authenticated;
    self.shareButton.enabled = authenticated && [BBTXMPPManager sharedManager].xmppStream.isAuthenticated;
    self.flagButton.enabled = YES;
    self.roomInteractionEnabled = YES;
}

/**
 * Sync group conversation details with data on HTTP server.
 * If the request fails the room could possibly be deleted so freeze the UI,
 * else refresh displayed room details and enable the view controller
 */
- (void)refreshGroupConversationDetails
{
    // cache group conversation status and time since creation
    BBTGroupConversationStatus status = [self.conversation.status integerValue];
    NSTimeInterval timeSinceCreation = -1 * [self.conversation.creationDate timeIntervalSinceNow];
    
    if (!self.conversation || (status != BBTGroupConversationStatusSynced)) {
        // consider operation as failed if conversation doesn't exist or has
        // never been sync'd which implies it is still in middle of creation
        // process
        [self disableUserInteraction];
        
        if (!self.conversation) {
            // if there's no conversation then nothing else to be done.
            
        } else if (status == BBTGroupConversationStatusCreated) {
            // if conversation is in state of "created" for too long then there
            // was a failure between XMPP creation and configuration. If so,
            // delete the conversation.
            if (timeSinceCreation > kBBTGroupConversationMaxCreatedTime) {
                [self.conversation.managedObjectContext deleteObject:self.conversation];
                self.conversation = nil;
            }
        
        } else if (status == BBTGroupConversationStatusConfigured) {
            // if conversation is in state of "configured" for too long then there
            // was a failure between XMPP configuration and HTTP syncing.
            // If so, attempt the sync that xmppManager never got to do.
            if (timeSinceCreation > kBBTGroupConversationMaxConfiguredTime) {
                [[BBTXMPPManager sharedManager] syncGroupConversationAfterConfiguration:self.conversation];
            }
        }
        
    } else { // if (self.conversation && (status == BBTGroupConversationStatusSynced))
        // a conversation has been fully created and updated on HTTP server so
        // get and use details
        NSString *roomDetailURL = [BBTHTTPManager roomDetailURL:self.conversation.roomName];
        
        [[BBTHTTPManager sharedManager] request:BBTHTTPMethodGET
                                         forURL:roomDetailURL
                                     parameters:nil
                                        success:^(NSURLSessionDataTask *task, id responseObject)
         {
             [BBTGroupConversation groupConversationWithRoomInfo:responseObject
                                          inManagedObjectContext:self.conversation.managedObjectContext];
             // Now that we know the room still exists update detail view properties
             [self useRefreshedGroupConversation];
             
         }
                                        failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject)
         {
             // Room hasn't been confirmed to exist so prevent
             // further user interaction
             [self disableUserInteraction];
             
             // if you get a 404 error it means the room does not exist so delete it
             // from data storage.
             id errorResponseObj = [[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
             if (errorResponseObj && [errorResponseObj isKindOfClass:[NSHTTPURLResponse class]]) {
                 NSHTTPURLResponse *errorResponse = (NSHTTPURLResponse *)errorResponseObj;
                 if (([errorResponse statusCode] == 404) ) {
                     [self.conversation.managedObjectContext deleteObject:self.conversation];
                     self.conversation = nil;
                 }
             }
         }];
    }
}

/**
 * Use the synced group conversation to update detail view properties
 */
- (void)useRefreshedGroupConversation
{
    // update detail view properties
    [self setupDetails];
    
    if ([BBTXMPPManager sharedManager].xmppStream.isAuthenticated) {
        // join group conversation to have a real-time track of comments
        [[BBTXMPPManager sharedManager] joinGroupConversationWithJID:[self.conversation jidStr]];
    }
    
    [self enableUserInteraction];
}

/**
 * Sync app user's liking of group conversation with data on HTTP server.
 */
- (void)refreshGroupConversationLiked
{
    // if not authenticated, don't bother
    if (![BBTHTTPManager sharedManager].httpAuthenticated) {
        [self updateLikesCountDetails];
        return;
    }
    
    NSString *username = [BBTHTTPManager sharedManager].username;
    NSString *roomDetailLikeURL = [BBTHTTPManager roomDetailURL:self.conversation.roomName like:username];
    
    [[BBTHTTPManager sharedManager] request:BBTHTTPMethodGET
                                     forURL:roomDetailLikeURL
                                 parameters:nil
                                    success:^(NSURLSessionDataTask *task, id responseObject) {
                                        // update liked status
                                        self.conversation.liked = [responseObject objectForKey:kBBTRESTRoomLikeResultKey];
                                        [self updateLikesCountDetails];
                                    } failure:nil];
}

/**
 * Get formatted address of represented group conversation which is:
 * - `city, state` if both city and state exist
 * - `state` if city doesn't exist but state does.
 * - `country` if neither city nor state exist.
 * - nil if none of city, state, country exist.
 */
- (NSString *)formattedLocationAddress
{
    NSString *address = nil;
    
    NSDictionary *locationAddress = self.conversation.locationAddress;
    NSString *city = [locationAddress objectForKey:kBBTAddressCityKey];
    NSString *state = [locationAddress objectForKey:kBBTAddressStateKey];
    NSString *country = [locationAddress objectForKey:kBBTAddressCountryKey];
    
    if (city || state || country) {
        if ([city length] && [state length]) {
            address = [NSString stringWithFormat:@"%@, %@", city, state];
        } else if ([state length]) {
            address = state;
        } else if (country) {
            address = country;
        }
    }
    
    return address;
}

/**
 * Show alert on successful message flagging
 */
- (void)alertOnSuccessfulFlagging
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Thread Reported" message:@"Thank you for helping to keep Blabbit clean and fun for everyone." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}


#pragma mark - Target-Action Methods

/**
 * Submit a like request for this user on HTTP server
 */
- (IBAction)likeGroupConversation:(UIButton *)sender
{
 
    NSString *username = [BBTHTTPManager sharedManager].username;
    NSString *roomDetailLikeURL = [BBTHTTPManager roomDetailURL:self.conversation.roomName like:username];
    
    // Get like status value at the time of this request.
    // There are a number of async operations related to like happening here, so
    // want to be consistent with this.
    BOOL likeRequest = ![self.conversation.liked boolValue];
    self.likesButton.enabled = NO;
    [[BBTHTTPManager sharedManager] request:likeRequest ? BBTHTTPMethodPOST : BBTHTTPMethodDELETE
                                     forURL:roomDetailLikeURL
                                 parameters:nil
                                    success:^(NSURLSessionDataTask *task, id responseObject) {
                                        // update likes status
                                        self.conversation.liked = @(likeRequest);
                                        
                                        // update likes count
                                        NSInteger likesCountDelta = likeRequest ? 1 : -1;
                                        NSInteger newLikesCount =  [self.conversation.likesCount integerValue] + likesCountDelta;
                                        newLikesCount = MAX(0, newLikesCount);
                                        self.conversation.likesCount = @(newLikesCount);
                                        
                                        // refresh displayed properties
                                        [self updateLikesCountDetails];
                                        
                                        self.likesButton.enabled = YES;
                                    
                                    } failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                                        self.likesButton.enabled = YES;
                                    }];
}

- (IBAction)flagGroupConversation:(id)sender
{
    // show alert view
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Report Thread?"
                                                        message:@"Are you sure you want to report this Thread?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
    [alertView show];
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // if "Yes" is clicked attempt to flag group conversation
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        NSString *roomDetailFlagURL = [BBTHTTPManager roomDetailURLFlag:self.conversation.roomName];
        [[BBTHTTPManager sharedManager] request:BBTHTTPMethodPOST forURL:roomDetailFlagURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            [self alertOnSuccessfulFlagging];
        } failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
            [self alertOnSuccessfulFlagging];
        }];
    }
}


#pragma mark - Notification Observer Methods
/**
 *  Upon receiving a message for this conversation, update the comment count
 */
- (void)newMessageReceived:(NSNotification *)aNotification
{
    NSManagedObject *conversation = [[aNotification userInfo] valueForKey:@"conversation"];
    // only process this status update if it belongs in this conversation
    if ([[conversation objectID] isEqual:[((NSManagedObject *)self.conversation) objectID]]) {
        [self updateCommentsCountDetails];
    }
}


/**
 * When the conversation is deleted disable the buttons
 */
- (void)groupConversationDeleted:(NSNotification *)aNotification
{
    NSString *roomName = [[aNotification userInfo] valueForKey:@"roomName"];
    // only process this delete notification if it is for this conversation
    if ([roomName caseInsensitiveCompare:self.conversationRoomName] == NSOrderedSame) {
        self.conversation = nil;
        [self disableUserInteraction];
    }
}

/**
 * When the conversation is synced shortly after creation. This will get called
 * if we opened the converation details in the middle of the groupchat/room
 * creation process.
 */
- (void)groupConversationSynced:(NSNotification *)aNotification
{
    NSManagedObject *conversation = [[aNotification userInfo] valueForKey:@"conversation"];
    // only process this status update if it belongs to this conversation
    if ([[conversation objectID] isEqual:[((NSManagedObject *)self.conversation) objectID]]) {
        [self useRefreshedGroupConversation];
    }
}

/**
 * When the conversation's corresponding XMPP Room is finally joined.
 */
- (void)groupConversationJoined:(NSNotification *)aNotification
{
    XMPPRoom *xmppRoom = [[aNotification userInfo] valueForKey:@"room"];
    // only process this room join notification if it belongs to this conversation
    if ([self.conversation.roomName isEqualToString:[xmppRoom.roomJID user]]) {
        if ([self.conversation.status integerValue] == BBTGroupConversationStatusSynced) {
            // only allow entering groupchat if conversation has been sync'd.
            // This way we don't find ourselves in a situation where rooms are
            // still being created and we are typing away.
            self.commentsButton.enabled = YES;
        }
    }
}

/**
 *  Upon change of user authentication on XMPP stream.
 */
- (void)xmppStreamAuthenticationChange:(NSNotification *)aNotification
{
    if (self.roomInteractionEnabled) {
        // join group conversation to have a real-time track of comments
        [[BBTXMPPManager sharedManager] joinGroupConversationWithJID:[self.conversation jidStr]];
        
        // enable share button if authenticated on both HTTP and XMPP
        self.shareButton.enabled = [BBTHTTPManager sharedManager].httpAuthenticated && [BBTXMPPManager sharedManager].xmppStream.isAuthenticated;
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little
// preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    id destinationVC = segue.destinationViewController;
    
    if ([destinationVC isKindOfClass:[BBTConversationCDCVC class]]) {
        // show an already-existent conversation
        if ([segue.identifier isEqualToString:@"showConversation"]) {
            BBTConversationCDCVC *conversationVC = (BBTConversationCDCVC *)destinationVC;
            conversationVC.conversation = self.conversation;
            // a conversation VC shouldn't have to deal with tab bars. It's
            // just not the iOS way.
            conversationVC.hidesBottomBarWhenPushed = YES;
        
        }
    } else if ([destinationVC isKindOfClass:[BBTShareGroupConversationViewController class]]) {
        // share an already-existent conversation
        if ([segue.identifier isEqualToString:@"shareConversation"]) {
            BBTShareGroupConversationViewController *shareConversationVC = (BBTShareGroupConversationViewController *)destinationVC;
            shareConversationVC.conversation = self.conversation;
        }
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"showConversation"]) {
        if (![BBTXMPPManager sharedManager].xmppRoom.isJoined) {
            return NO;
        }
    }
    return YES;
}

@end
