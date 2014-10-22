//
//  BBTBubbleLabel.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/25/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTBubbleLabel.h"

@implementation BBTBubbleLabel

#pragma mark - Properties
- (void)setText:(NSString *)text
{
    [super setText:text];
    if (![text length] || [text isEqualToString:@"0"]) {
        self.hidden = YES;
    } else {
        self.hidden = NO;
    }
}

#pragma mark - Initialization
- (void)setup
{
    // rounded corners
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = self.frame.size.height/2.0;
}

- (void)awakeFromNib
{
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
