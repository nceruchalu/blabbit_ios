//
//  BBTMessage+JSQMessageData.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/22/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTMessage.h"
#import "JSQMessageData.h"

/**
 * This JSQMessageData category ensures BBTMessage implements the JSQMessageData
 * protocol so it can be used in JSQMessagesViewController
 */
@interface BBTMessage (JSQMessageData) <JSQMessageData>

@end
