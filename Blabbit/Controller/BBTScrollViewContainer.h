//
//  BBTScrollViewContainer.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/2/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * BBTScrollViewContainer is a helper class that makes it possible to setup
 * a scrollView with auto layout.
 * It stretches the  content of the scrollview in portrait and landscape
 * It also uses the UIScrollView to move input fields out of the way of the keyboard
 *
 * @see http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/
 *
 * @warning this class is not very useful if not subclassed
 */
@interface BBTScrollViewContainer : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *inputTextFieldsCollection;

@end
