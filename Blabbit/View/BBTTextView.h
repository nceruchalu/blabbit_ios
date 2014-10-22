//
//  BBTTextView.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/14/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * `BBTTextView` is a subclass of `UITextView` which adds placeholder support
 * just like we are used to in UITextField
 *
 * All you have to set is the placeholder property.
 *
 * @warning This does not play well with autolayout, so until that is fixed you
 *      want to place this in a view that does not get resized with autolayout.
 *
 * @ref https://github.com/soffes/SAMTextView
 */
@interface BBTTextView : UITextView

/**
 * The string that is displayed when there is no other text in the text view.
 * This property reads and writes the attributed variant.
 *
 * The default value is `nil`.
 */
@property (nonatomic, strong) NSString *placeholder;

/**
 * The attributed string that is displayed when there is no other text in the 
 * text view.
 *
 * The default value is `nil`.
 */
@property (nonatomic, strong) NSAttributedString *attributedPlaceholder;

/**
 * Returns the drawing rectangle for the text views’s placeholder text.
 *
 * @param bounds The bounding rectangle of the receiver.
 * @return The computed drawing rectangle for the placeholder text.
 */
- (CGRect)placeholderRectForBounds:(CGRect)bounds;

@end
