/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  A custom cell used for displaying list items, and the row allowing for the creation of new items.
              
 */

#import "AAPLListItemCell.h"

@implementation AAPLListItemCell

#pragma mark - Setter Overrides

- (void)setComplete:(BOOL)complete {
    _complete = complete;
    
    self.textField.enabled = !complete;
    self.checkBox.checked = complete;
    
    self.textField.textColor = complete ? [UIColor lightGrayColor] : [UIColor darkTextColor];
}

#pragma mark - Reuse

- (void)prepareForReuse {
    self.textField.text = @"";
    self.textField.textColor = [UIColor darkTextColor];
    self.textField.enabled = YES;
    self.checkBox.checked = NO;
    self.checkBox.hidden = NO;
}

@end
