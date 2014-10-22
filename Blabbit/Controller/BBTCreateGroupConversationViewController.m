//
//  BBTCreateGroupConversationViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/30/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTCreateGroupConversationViewController.h"
#import "BBTXMPPManager.h"
#import "BBTGroupConversation+CLLocation.h"
#import "BBTModelManager.h"
#import "BBTTextView.h"
#import "BBTLocationManager.h"
#import <CoreLocation/CoreLocation.h>

/**
 * Constants
 */
static NSString *const kUnwindSegueIdentifier = @"DoCreateGroupConversation";

// text view margin on all 4 sides
static const CGFloat textViewMargin = 10.0f;

// maximum number of characters in groupchat subject
static const NSUInteger kMaxSubjectLength = 200;

// how many points the photo button will be offset from the image (top and right)
static const CGFloat deletePhotoButtonOffset = 4.0f;

// Constants for button indices in action sheets
static const NSInteger kAddPhotoTakeButtonIndex = 0;   // Take Photo
static const NSInteger kAddPhotoChooseButtonIndex = 1; // Choose Existing

@interface BBTCreateGroupConversationViewController () <UITextViewDelegate,
                                                        UIActionSheetDelegate,
                                                        UINavigationControllerDelegate,
                                                        UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *createButton;
@property (weak, nonatomic) IBOutlet BBTTextView *subjectTextView;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIButton *deletePhotoButton;

// Toolbar with attachment buttons (camera, addLocation)
@property (weak, nonatomic) IBOutlet UIToolbar *attachmentsToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addLocationButton;

// Location info
@property (weak, nonatomic) IBOutlet UIImageView *locationIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

// view placed on top of keyboard
@property (weak, nonatomic) IBOutlet UIToolbar *accessoryView;


// make readwrite internally so it can be modified
@property (strong, nonatomic, readwrite) BBTGroupConversation *createdConversation;

// groupchat photo image
@property (strong, nonatomic) UIImage *groupConversationPhoto;

// constraints for deletePhotoButton
@property (strong, nonatomic) NSLayoutConstraint *topPhotoConstraint;
@property (strong, nonatomic) NSLayoutConstraint *rightPhotoConstraint;

@property (strong, nonatomic) CLLocation *location;             // cached location
@property (strong, nonatomic) NSDictionary *locationAddress;    // reverse-geocoded address

@end

@implementation BBTCreateGroupConversationViewController

#pragma mark - Properties
- (void)setGroupConversationPhoto:(UIImage *)groupConversationPhoto
{
    _groupConversationPhoto = groupConversationPhoto;
    self.photoImageView.image = groupConversationPhoto;
    
    // setup delete photo button
    self.deletePhotoButton.hidden = (groupConversationPhoto == nil);
    
    if (!self.deletePhotoButton.isHidden) {
        // get image frame... this logic assumes UIViewContentModeScaleAspectFit
        UIImageView *iv = self.photoImageView;
        CGSize imageSize = self.photoImageView.image.size;
        CGFloat imageScale = fminf(CGRectGetWidth(iv.bounds)/imageSize.width, CGRectGetHeight(iv.bounds)/imageSize.height);
        CGSize scaledImageSize = CGSizeMake(imageSize.width*imageScale, imageSize.height*imageScale);
        CGRect imageBounds = CGRectMake(roundf(0.5f*(CGRectGetWidth(iv.bounds)-scaledImageSize.width)), roundf(0.5f*(CGRectGetHeight(iv.bounds)-scaledImageSize.height)), roundf(scaledImageSize.width), roundf(scaledImageSize.height));
        CGRect imageFrame = [iv convertRect:imageBounds toView:self.view];
        
        // put button at the top right of the image frame using constraints

        // first reset constraints
        [self.view removeConstraint:self.topPhotoConstraint];
        [self.view removeConstraint:self.rightPhotoConstraint];
        
        CGFloat vOffset = (imageFrame.origin.y - iv.frame.origin.y) - deletePhotoButtonOffset;
        self.topPhotoConstraint = [NSLayoutConstraint constraintWithItem:self.deletePhotoButton
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:0
                                                             toItem:self.photoImageView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:vOffset];
        [self.view addConstraint:self.topPhotoConstraint];
        
        CGFloat hOffset = (imageFrame.size.width - iv.frame.size.width)/2.0f + deletePhotoButtonOffset;
        self.rightPhotoConstraint = [NSLayoutConstraint constraintWithItem:self.deletePhotoButton
                                                            attribute:NSLayoutAttributeTrailing
                                                            relatedBy:0
                                                               toItem:self.photoImageView
                                                            attribute:NSLayoutAttributeRight
                                                           multiplier:1.0
                                                             constant:hOffset];
        [self.view addConstraint:self.rightPhotoConstraint];
    }
}


#pragma mark - Class Methods
#pragma mark Private
/**
 * Create Full Address given an address dictionary
 */
+ (NSString *)addressFromDictionary:(NSDictionary *)addressDictionary
{
    NSString *address = nil;
    
    NSString *city = [addressDictionary objectForKey:kBBTAddressCityKey];
    NSString *state = [addressDictionary objectForKey:kBBTAddressStateKey];
    NSString *country = [addressDictionary objectForKey:kBBTAddressCountryKey];
    
    if (city || state || country) {
        NSMutableString *formattedAddress = [[NSMutableString alloc] initWithString:@""];
        BOOL firstComponent = YES; // are we on first component?
        if (city) {
            [formattedAddress appendString:city];
            firstComponent = NO;
        }
        
        if (state) {
            if (!firstComponent) [formattedAddress appendString:@", "];
            [formattedAddress appendString:state];
            firstComponent = NO;
        }
        
        if (country) {
            if (!firstComponent) [formattedAddress appendString:@", "];
            [formattedAddress appendString:country];
            firstComponent = NO;
        }
        
        address = [formattedAddress copy];
    }
    
    return address;
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // start view out with create button disabled
    self.createButton.enabled = NO;
    
    // setup text view
    self.subjectTextView.placeholder = @"Topic (ex: I run for chocolate...)";
    self.subjectTextView.textContainerInset = UIEdgeInsetsMake(textViewMargin, textViewMargin, textViewMargin, textViewMargin);
    self.subjectTextView.inputAccessoryView = self.accessoryView;
    self.subjectTextView.delegate = self;
    
    self.subjectTextView.layer.borderColor = kBBTLightGrayBorderColor.CGColor;
    self.subjectTextView.layer.borderWidth = 1.0;
    
    // no photo yet so hide delete photo button
    self.deletePhotoButton.hidden = YES;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // First check if the hardware you are on/user supports location updating
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    BOOL locationEnabled = [CLLocationManager locationServicesEnabled];
    
    if (locationEnabled && authStatus==kCLAuthorizationStatusAuthorized) {
        
        // hide add-location button and show user's current location
        [self hideAddLocationButton:NO];
        [self showLocationInfo];
        
        // Next, get current location
        [self updateCurrentLocation];
        
    } else {
        // show add-location button and hide user's current location
        [self showAddLocationButton:NO];
        [self hideLocationInfo];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}



#pragma mark - Instance Methods (private)
/**
 * Create conversation from values of elements in View Controller and save in CoreData
 * Point to this conversation from the createdConversation property.
 *
 * This expects the managedObjectContext to be ready else it won't create a conversation.
 * So ensure the context is ready before calling this function.
 *
 * @see shouldPerformSegueWithIdentifier:sender:
 */
- (void)createConversation
{
    // If the shared managed object context has already been setup use it
    // Notice we don't try to asynchronously setup the managedObjectContext
    //   as the conversation creation should be blocked until the context is ready.
    if ([BBTModelManager sharedManager].managedObjectContext) {
        self.createdConversation = [[BBTXMPPManager sharedManager] createGroupConversationWithSubject:self.subjectTextView.text photo:self.groupConversationPhoto location:self.location address:self.locationAddress invitees:self.selectedContacts];
    }
}

/**
 * Request current location from location manager
 */
- (void)updateCurrentLocation
{
    // since we are getting location, prevent future input till this is done.
    [self hideAddLocationButton:YES];
    [self showLocationInfo];
    [self.spinner startAnimating];
    
    [[BBTLocationManager sharedManager] updateCurrentLocation:^(CLLocation *location, NSError *error) {
        
        if (location) {
            // cache location and get placemark
            self.location = location;
            [[[CLGeocoder alloc] init] reverseGeocodeLocation:self.location completionHandler:^(NSArray *placemarks, NSError *error) {
                [self.spinner stopAnimating];
                
                CLPlacemark *placemark = [placemarks lastObject];
                
                // cache location address and set it in UI
                self.locationAddress = [BBTGroupConversation addressForPlacemark:placemark];
                self.locationLabel.text = [BBTCreateGroupConversationViewController addressFromDictionary:self.locationAddress];
            }];
            
            // hide add-location button and show user's current location
            [self hideAddLocationButton:YES];
            [self showLocationInfo];
            
        } else {
            [self.spinner stopAnimating];
            
            // Show add-location button and hide user's current location. While
            // it might seem odd to show this even for errors like timeout while
            // "still getting location" it makes more sense than not showing
            // anything to the user when we clearly haven't derived a location yet.
            [self showAddLocationButton:YES];
            [self hideLocationInfo];
        }
        
    } failure:^{
        [self.spinner stopAnimating];
        [self showAddLocationButton:YES];
        [self hideLocationInfo];
    }];
}

- (void)showAddLocationButton:(BOOL)animated
{
    // Get a reference to the current toolbar buttons
    NSMutableArray *toolbarButtons = [self.attachmentsToolbar.items mutableCopy];
    
    if (![toolbarButtons containsObject:self.addLocationButton]) {
        // the following line adds the object to the end of the array.
        // If you want to add the button somewhere else, use the `insertObject:atIndex`
        // method instead of the `addObject` method.
        [toolbarButtons addObject:self.addLocationButton];
        [self.attachmentsToolbar setItems:toolbarButtons animated:animated];
    }
}

- (void)hideAddLocationButton:(BOOL)animated
{
    // Get a reference to the current toolbar buttons
    NSMutableArray *toolbarButtons = [self.attachmentsToolbar.items mutableCopy];
    
    [toolbarButtons removeObject:self.addLocationButton];
    [self.attachmentsToolbar setItems:toolbarButtons animated:animated];
}

- (void)showLocationInfo
{
    self.locationIconImageView.hidden = NO;
    self.locationLabel.hidden = NO;
}

- (void)hideLocationInfo
{
    self.locationIconImageView.hidden = YES;
    self.locationLabel.hidden = YES;
}

/**
 * show error message indicating location is disabled for app.
 */
- (void)showLocationDisabledErrorAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops. That didn't work!" message:kBBTErrorMsgLocationDisabled delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Create the group conversation!
    if ([segue.identifier isEqualToString:kUnwindSegueIdentifier]) {
        [self createConversation];
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // Can only unwind and create a group if there is a groupchat subject and the
    // managedObjectContext is ready
    if ([identifier isEqualToString:kUnwindSegueIdentifier]) {
        if (!([self.subjectTextView.text length] &&
              [BBTModelManager sharedManager].managedObjectContext)) {
            return NO;
        }
    }
    return YES;
}


#pragma mark - Target-Action Methods
- (IBAction)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)addPhoto:(UIBarButtonItem *)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Take photo", @"Choose existing", nil];
    
    [actionSheet showInView:self.view];
}

- (IBAction)hideKeyboard:(id)sender
{
    // force view to resignFirstResponder status
    [self.view endEditing:YES];
}

- (IBAction)deletePhoto:(id)sender
{
    self.groupConversationPhoto = nil;
}

- (IBAction)addLocation:(id)sender
{
    // User wants to add Location but only do so if possible
    [self updateCurrentLocation];
}


#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    // can only create a groupchat if you indeed have a subject
    self.createButton.enabled = ([textView.text length] > 0);
}

// enforce a maxlength
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if([newText length] <= kMaxSubjectLength) {
        return YES;
        
    } else {
        // text is too long so truncate
        textView.text = [newText substringToIndex:kMaxSubjectLength];
        return NO;
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // add a photo by taking a new one or choosing existing.
    switch (buttonIndex-actionSheet.firstOtherButtonIndex) {
        case kAddPhotoTakeButtonIndex:
            [self startCameraController:UIImagePickerControllerSourceTypeCamera];
            break;
            
        case kAddPhotoChooseButtonIndex:
            [self startCameraController:UIImagePickerControllerSourceTypePhotoLibrary];
            break;
            
        default:
            break;
    }
}

#pragma mark Photo Upload Helpers

/**
 * take photo or choose existing from photo library
 *
 * @param sourceType    UIImagePickerControllerSourceType
 */
- (void)startCameraController:(UIImagePickerControllerSourceType)sourceType
{
    // quit if camera or photo library is not available
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return;
    }
    
    // camera/photo library available so set it up.
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = sourceType;
    
    // Show the controls for moving & scaling pictures
    cameraUI.allowsEditing = YES;
    
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate
// For responding to the user tapping Cancel
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// For responding to the user accepting a newly captured picture.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // get picked image from info dictionary
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    
    UIImage *imageToSave = editedImage ? editedImage : originalImage;
    
    // Save a new image to the camera roll
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
    }
    
    // Now work with this new image
    self.groupConversationPhoto = imageToSave;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
