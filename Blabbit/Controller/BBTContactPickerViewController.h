//
//  BBTContactPickerViewController.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/29/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BBTContactPicker.h"

/**
 * BBTContactPickerViewController is a view controller that has a BBTContactPicker
 *   view hierarchy in it.
 * This view controller can contain other views but it is only useful if at has
 *   a contact picker in it.
 */
@interface BBTContactPickerViewController : UIViewController <BBTContactPickerDelegate>

/**
 * Contacts that user can select from (input), of type (XMPPUserCoreDataStorageObject *)
 * This is auto-populated from the user's friend's list
 */
@property (strong, nonatomic, readonly) NSArray *contacts;

/**
 * Contacts that user has selected (output), of type (XMPPUserCoreDataStorageObject *) 
 */
 @property (strong, nonatomic, readonly) NSArray *selectedContacts;

@end
