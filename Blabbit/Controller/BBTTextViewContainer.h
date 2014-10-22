//
//  BBTTextViewContainer.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/4/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * BBTTextViewContainer is a helper class that makes it possible to setup
 * a textView with auto layout and keyboard management.
 * It stretches the  content of the textview in portrait and landscape
 * It also uses the UITextView to move input fields out of the way of the keyboard
 *
 * @see https://devforums.apple.com/message/918284
 *
 * @warning this class is not very useful if not subclassed
 */
@interface BBTTextViewContainer : UIViewController <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end
