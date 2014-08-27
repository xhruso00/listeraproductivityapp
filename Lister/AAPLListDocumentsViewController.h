/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                 Handles displaying a list of available documents for users to open.
              
 */

@import UIKit;

@class AAPLListInfo;

@interface AAPLListDocumentsViewController : UITableViewController

- (void)selectListWithListInfo:(AAPLListInfo *)listInfo;

@end
