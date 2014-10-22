//
//  BBTMessage+JSQMessageData.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/22/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTMessage+JSQMessageData.h"
#import "BBTXMPPManager.h"

@implementation BBTMessage (JSQMessageData)

- (NSDate *)date
{
    return self.localTimestamp;
}

- (NSString *)sender
{
    // incoming message senders are either username's or nickname depending on
    // if we are in a chat or groupchat, respectively.
    // outgoing messages will be set to a fixed sender. This way we are not affected
    //   by an app user's username change.
    return [self.isIncoming boolValue] ? self.user : [[BBTXMPPManager sharedManager].xmppStream.myJID user];
}

- (NSString *)text
{
    // system messages don't have a body so return a blank string for them.
    return (self.body) ? (self.body) : @"";
}

@end
