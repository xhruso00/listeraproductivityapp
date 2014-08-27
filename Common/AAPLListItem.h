/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The AAPLListItem class represents the text and completion state of a single item in the list.
            
*/

@import Foundation;

@interface AAPLListItem : NSObject<NSCoding, NSCopying>

- (instancetype)initWithText:(NSString *)text;

- (BOOL)isEqualToListItem:(AAPLListItem *)item;

@property (copy) NSString *text;
@property (getter=isComplete) BOOL complete;

// Reset the UUID if the object needs to be re-tracked.
- (void)refreshIdentity;

@end
