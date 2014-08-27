/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Allows users to create a new list document with a name and preferred color.
            
*/

@import UIKit;

@class AAPLListInfo;
@class AAPLNewListDocumentController;

// Delegate protocol to let other objects know that a new document should be created.
@protocol AAPLNewListDocumentControllerDelegate <NSObject>
- (void)newListViewController:(AAPLNewListDocumentController *)newListViewController didCreateDocumentWithListInfo:(AAPLListInfo *)listInfo;
@end

@interface AAPLNewListDocumentController : UIViewController

@property (weak) id <AAPLNewListDocumentControllerDelegate> delegate;

@end
