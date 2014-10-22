//
//  XMPPUserCoreDataStorageObject+BBTUserModel.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 6/6/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "XMPPUserCoreDataStorageObject+BBTUserModel.h"

@implementation XMPPUserCoreDataStorageObject (BBTUserModel)

- (NSString *)username
{
    return [self.jid user];
}

- (NSString *)formattedName
{
     // Title is either vCard's formated name or @<username>
     return self.nickname ? self.nickname : [NSString stringWithFormat:@"@%@",self.username];
}

#pragma mark - MBContactPickerModelProtocol
// will only implement the required method of the MBContactPickerModelProtocol
- (NSString *)contactTitle
{
    return [self formattedName];
}

@end
