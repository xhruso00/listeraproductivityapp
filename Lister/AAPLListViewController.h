/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  Displays the contents of a list document, allows a user to create, update, and delete items, change the color of the list, or delete the list.
              
 */

@import UIKit;

@class AAPLListInfo;
@class AAPLListViewController;

extern NSString *const AAPLListViewControllerListDidUpdateColorNotification;
extern NSString *const AAPLListViewControllerListDidUpdateColorUserInfoKey;
extern NSString *const AAPLListViewControllerListDidUpdateURLUserInfoKey;

// Provides the ability to send a delegate a message about a list being deleted.
@protocol AAPLListViewControllerDelegate <NSObject>
- (void)listViewControllerDidDeleteList:(AAPLListViewController *)listViewController;
@end

@interface AAPLListViewController : UITableViewController

@property (nonatomic, strong, readonly) NSURL *documentURL;
@property (nonatomic, weak) id <AAPLListViewControllerDelegate> delegate;

- (void)configureWithListInfo:(AAPLListInfo *)listInfo;

@end
