//
//  BBTMessagesCollectionViewCellSystem.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/1/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTMessagesCollectionViewCellSystem.h"

@implementation BBTMessagesCollectionViewCellSystem

#pragma mark - Overrides

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([BBTMessagesCollectionViewCellSystem class])
                          bundle:[NSBundle mainBundle]];
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([BBTMessagesCollectionViewCellSystem class]);
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.messageBubbleTopLabel.textAlignment = NSTextAlignmentRight;
    self.cellBottomLabel.textAlignment = NSTextAlignmentRight;
    
    // remove all gesture recognizers
    [self removeGestureRecognizer:self.longPressGestureRecognizer];
    [self removeGestureRecognizer:self.tapGestureRecognizer];
}

@end
