# Blabbit iOS App

## About Blabbit
|         |                                             |
| ------- | ------------------------------------------- |
| Author  | Nnoduka Eruchalu                            |
| Date    | 05/22/2014                                  |
| Website | [http://blabb.it](http://blabb.it)          |


## Software Description
### 3rd-party Objective-C Modules
* [AFNetworking](https://github.com/AFNetworking/AFNetworking)
* [XMPPFramework](https://github.com/robbiehanson/XMPPFramework) 
* [JSQMessagesViewController v5.2.5](https://github.com/jessesquires/JSQMessagesViewController)
* [JSQSystemSoundPlayer](https://github.com/jessesquires/JSQSystemSoundPlayer)
* [MBContactPicker](https://github.com/Citrrus/MBContactPicker)


### Core Data Design Decisions
#### Denormalization
Goal is to avoid unnecessary joins (i.e. performance optimization)
So the idea here is to store relationship meta information on source such as:
* count
* existence
* aggregate values

This drove the decision to have an `unreadMessageCount` attribute on the 
`BBTContactConversation` NSManagedObject.

#### Normalization
Goal is to prevent duplication of data.
So the idea here is to separate unlike things hence the two NSManagedObjects:
`BBTMessage` and `BBTContactConversation` linked with the following 
relationships
* message.conversation <<--> conversation.messages
* message.conversationUsingAsLastMessage <--> conversation.lastMessage

#### Fetch Batch Size
* On an iPhone only 10 rows are visible 
* So doesn't make sense to fetch every possible object
* Hence chose to use a fetch batch size of 20

#### Relationship faulting
* There are some cases where the master table shows related data, so need the related data *now*.
* In these cases prefetch to avoid faulting individually
  ** so for chat conversations tab use `[request setRelationshipKeypathsForPrefetching: @["lastMessage"]]`