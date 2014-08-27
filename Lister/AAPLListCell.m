/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  A custom cell used for displaying list documents.
              
 */

#import "AAPLListCell.h"

@implementation AAPLListCell

#pragma mark - Reuse

- (void)prepareForReuse {
    self.label.text = @"";
    self.listColorView.backgroundColor = [UIColor clearColor];
}

@end
