//
//  BBTManagedDocument.h
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 7/7/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * BBTManagedDocument is a concrete subclass of UIManagedDocument that customizes
 * the creation of the managed object model to only use the Blabbit model.
 * 
 * This is important because the default UIManagedDocument model is the union of
 * all models in the main bundle. This causes a problem given that there are a
 * number of XMPP Core Data models. We don't want them merged in here so the
 * managedObjectModel property is overriden.
 */
@interface BBTManagedDocument : UIManagedDocument

@end
