/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  Controls the logic for displaying the UI for creating a new list item for the table view.
              
 */

#import "AAPLAddItemViewController.h"
@import ListerKitOSX;

@implementation AAPLAddItemViewController

#pragma mark - IBActions

- (IBAction)textChanged:(NSTextField *)textField {
    NSString *cleansedString = [textField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (cleansedString.length > 0) {
        [self.delegate addItemViewController:self didCreateNewItemWithText:cleansedString];
    }

    // It's a known issue that presentingViewController currently returns nil. To work around this, you can use the escape key instead of the enter key to close the popover / create a new item.
    [self.presentingViewController dismissViewController:self];
}

@end
