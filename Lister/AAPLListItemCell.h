/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  A custom cell used for displaying list items, and the row allowing for the creation of new items.
              
 */

@import UIKit;
@import ListerKit;

@interface AAPLListItemCell : UITableViewCell

@property (nonatomic, weak) IBOutlet AAPLCheckBox *checkBox;
@property (nonatomic, weak) IBOutlet UITextField *textField;

@property (nonatomic, getter=isCompleted) BOOL complete;

@end
