//
//  BBTProfileSettingsViewController.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTProfileSettingsViewController.h"
#import "BBTXMPPManager.h"
#import "BBTHTTPManager.h"
#import "XMPPvCardCoreDataStorageObject.h"
#import "BBTUtilities.h"

/**
 * Constants for button indices in action sheets
 */
static const NSInteger kAddPhotoTakeButtonIndex = 0;   // Take Photo
static const NSInteger kAddPhotoChooseButtonIndex = 1; // Choose Existing

/**
 * kAvatarImageWidth is the width of avatar images (in pixels). 
 * Remember avatar images are square so no need to specify width and height.
 * Specifically using pixels as this is important to the XEP-0153 specification
 * that image height and width be between 32px and 96px
 */
static const CGFloat kAvatarImageWidth = 80.0f;

@interface BBTProfileSettingsViewController () <UIActionSheetDelegate,
                                                UINavigationControllerDelegate,
                                                UIImagePickerControllerDelegate>

@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *doneButton;

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

// cache the values that come from the server/vCard so we can easily revert
// to this when necessary
@property (strong, nonatomic) UIImage *avatar;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) NSString *email;

// keep track of the multiple actionsheets so we know which we are handling
@property (strong, nonatomic) UIActionSheet *addPhotoActionSheet;

@end

@implementation BBTProfileSettingsViewController

#pragma mark - Properties
- (UIBarButtonItem *)cancelButton
{
    // lazy instantiation
    if (!_cancelButton) {
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    }
    return _cancelButton;
}

- (UIBarButtonItem *)doneButton
{
    // lazy instantiation
    if (!_doneButton) {
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(updateUserDisplayNameAndEmail)];
    }
    return _doneButton;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // make photobutton rounded and with a border
    self.avatarButton.layer.cornerRadius = self.avatarButton.frame.size.width/2.0;
    self.avatarButton.clipsToBounds = YES;
    self.avatarButton.layer.borderWidth = kInputBorderThickness;
    self.avatarButton.layer.borderColor = kInputBorderColor.CGColor;
    
    // setup avatar, username, display name, email
    [self populateProfileDetails];
}


#pragma mark - Instance Methods
#pragma mark Private
- (void)showEditingButtons
{
    // replace back button with a Cancel button
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    self.navigationItem.hidesBackButton = YES;
    
    // show Done button
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)hideEditingButtons
{
    // replace Cancel button with the back button
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = NO;
    
    // hide Done button
    self.navigationItem.rightBarButtonItem = nil;
    
    // hide keyboard
    [self.view endEditing:YES];
}

/**
 * Setup the view controller's avatar and displayName using data from the ejabber server.
 * Also cache these values in local instance variables to use in undoing changes.
 */
- (void)populateProfileAvatarAndDisplayName
{
    // get vCard which has the data of interest.
    XMPPvCardTemp *myvCardTemp = [[BBTXMPPManager sharedManager].xmppvCardTempModule myvCardTemp];
    
    self.displayName = myvCardTemp.formattedName;
    self.displayNameTextField.text = self.displayName;
    
    self.avatar = [UIImage imageWithData:myvCardTemp.photo];
    [self.avatarButton setImage:self.avatar forState:UIControlStateNormal];
}

/**
 * Setup the View Controller's fields (avatar, username, display name, email)
 * with data from Blabbit server and ejabberd server.
 * Also cache these values in local instance variables to use in undoing changes
 * made during edit mode.
 */
- (void)populateProfileDetails
{
    [self.spinner startAnimating];
    
    // setup username that can't be edited
    self.usernameLabel.text = [BBTHTTPManager sharedManager].username;
    
    // get vcard or force a fetch if this isn't available yet for some reason.
    [self populateProfileAvatarAndDisplayName];
    
    self.emailTextField.enabled = NO;
    
    // get personal data (i.e. email from server)
    BBTHTTPManager *httpManager = [BBTHTTPManager sharedManager];
    [httpManager request:BBTHTTPMethodGET
                  forURL:kBBTRESTUser
              parameters:nil
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     
                     // only enable email field if we have this data.
                     self.emailTextField.enabled = YES;
                     
                     // set email from server
                     self.email = [responseObject objectForKey:kBBTRESTUserEmailKey];
                     self.emailTextField.text = self.email;
                     
                     // set display name and photo from vCard... it might seem odd
                     // to set this here but it's done this way to ensure we
                     // surely have vCard by now.
                     [self populateProfileAvatarAndDisplayName];
                     
                     [self.spinner stopAnimating];
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     // do nothing
                     [self.spinner stopAnimating];
                 }];
}


#pragma mark Target-Action methods
/**
 * Cancel the editing of user's profile
 */
- (void)cancelEditing
{
    [self hideEditingButtons];
    // revert changes
    self.emailTextField.text = self.email;
    self.displayNameTextField.text = self.displayName;
    [self.avatarButton setImage:self.avatar forState:UIControlStateNormal];
}

/**
 * Update the profile's display name and email on the server and in ejabberd
 * using data in View Controller
 */
- (void)updateUserDisplayNameAndEmail
{
    [self hideEditingButtons];
    
    // save changes
    
    NSString *newDisplayName = self.displayNameTextField.text;
    NSString *newEmail = self.emailTextField.text;
    
    // try saving on server first (validate before saving on vCard)
    BBTHTTPManager *httpManager = [BBTHTTPManager sharedManager];
    
    NSDictionary *parameters = @{kBBTRESTUserDisplayNameKey : newDisplayName,
                                 kBBTRESTUserEmailKey : newEmail};
    
    [httpManager request:BBTHTTPMethodPUT
                  forURL:kBBTRESTUser
              parameters:parameters
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     // if update is successful put this on vcard.
                     XMPPvCardTemp *myvCardTemp = [[BBTXMPPManager sharedManager].xmppvCardTempModule myvCardTemp];
                     if (!myvCardTemp) {
                         // possible to not have a vCard if I'm a new user with no details updated
                         myvCardTemp = [XMPPvCardTemp vCardTemp];
                      }
                     myvCardTemp.formattedName = newDisplayName;
                     [[BBTXMPPManager sharedManager].xmppvCardTempModule updateMyvCardTemp:myvCardTemp];
                     
                     // also save this in local cache
                     self.displayName = newDisplayName;
                     self.email = newEmail;
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     
                     [BBTHTTPManager alertWithFailedResponse:responseObject withAlternateTitle:@"Couldn't update profile" andMessage:@"That name and email didn't seem to work."];
                 }];
}

/**
 * Update user's avatar.
 *
 * @param image     new source image for user's avatar
 */
- (void)updateUserAvatar:(UIImage *)image
{
    // get thumbnail-sized version of image to use as avatar
    UIImage *avatarImage = [BBTUtilities imageWithImage:image
                                       scaledToFillSize:CGSizeMake(kAvatarImageWidth, kAvatarImageWidth)];
    
    // turn avatar image into JPEG data (smaller size than PNG)
    NSData *avatarImageData = UIImageJPEGRepresentation(avatarImage, 1.0);
    
    // display avatar image on profile page
    [self.avatarButton setImage:avatarImage forState:UIControlStateNormal];
    
    // update vcard with this new image.
    XMPPvCardTemp *myvCardTemp = [[BBTXMPPManager sharedManager].xmppvCardTempModule myvCardTemp];
    if (!myvCardTemp) {
        // possible to not have a vCard if I'm a new user with no details updated
        myvCardTemp = [XMPPvCardTemp vCardTemp];
    }
    myvCardTemp.photo = avatarImageData;
    [[BBTXMPPManager sharedManager].xmppvCardTempModule updateMyvCardTemp:myvCardTemp];
    
    // and finally send this to server
    if (image) {
        // if there is an image then send it to server
        [[BBTHTTPManager sharedManager] operationRequest:BBTHTTPMethodPUT
                                                  forURL:kBBTRESTUser
                                              parameters:nil
                               constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                   NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [BBTHTTPManager sharedManager].username];
                                   [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 1.0)
                                                               name:kBBTRESTUserAvatarKey
                                                           fileName:fileName
                                                           mimeType:@"image/jpeg"];
                               }
                                                 success:nil
                                                 failure:nil];
    } else {
        // delete image from server
        NSDictionary *parameters = @{kBBTRESTUserAvatarKey: @""};
        [[BBTHTTPManager sharedManager] request:BBTHTTPMethodPUT forURL:kBBTRESTUser parameters:parameters success:nil failure:nil];
    }
    
}


- (IBAction)addAvatar:(UIButton *)sender
{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:self.avatarButton.currentImage ? @"Delete" : nil
                                                    otherButtonTitles:@"Take photo", @"Choose existing", nil];
    
    // save this action sheet for future reference
    self.addPhotoActionSheet = actionSheet;
    [self.addPhotoActionSheet showInView:self.view];
}



#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [super textFieldDidBeginEditing:textField];
    [self showEditingButtons];
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.addPhotoActionSheet) {
        
        // is this a delete operation?
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            // delete photo
            [self updateUserAvatar:nil];
            return;
        }
        
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
    [self updateUserAvatar:imageToSave];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
