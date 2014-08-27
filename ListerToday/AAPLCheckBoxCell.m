/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                   A check box cell for the Today view.
              
 */

#import "AAPLCheckboxCell.h"

@implementation AAPLCheckBoxCell

- (void)prepareForReuse {
    self.textLabel.text = @"";
    self.textLabel.textColor = [UIColor whiteColor];
    self.checkBox.checked = NO;
    self.checkBox.hidden = NO;
    self.checkBox.tintColor = [UIColor clearColor];
}

@end
