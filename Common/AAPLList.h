/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The AAPLList class manages a list of items and the color of the list.
            
*/

@import Foundation;

@class AAPLListItem;

typedef NS_ENUM(NSInteger, AAPLListColor) {
    AAPLListColorGray = 0,
    AAPLListColorBlue,
    AAPLListColorGreen,
    AAPLListColorYellow,
    AAPLListColorOrange,
    AAPLListColorRed
};

typedef struct AAPLListOperationInfo {
    NSInteger fromIndex;
    NSInteger toIndex;
} AAPLListOperationInfo;

@interface AAPLList : NSObject<NSCoding, NSCopying>

@property AAPLListColor color;

// Returns the list item at a given index.
- (AAPLListItem *)objectAtIndexedSubscript:(NSUInteger)index;
- (NSArray *)objectForKeyedSubscript:(NSIndexSet *)indexes;

- (NSInteger)indexOfItem:(AAPLListItem *)item;

@property (readonly, getter=isEmpty) BOOL empty;
@property (readonly) NSInteger count;

@property (readonly) NSInteger indexOfFirstCompletedItem;

- (BOOL)canInsertIncompleteItems:(NSArray *)incompleteItems atIndex:(NSInteger)index;
- (BOOL)canMoveItem:(AAPLListItem *)item toIndex:(NSInteger)index inclusive:(BOOL)inclusive;

- (void)removeItems:(NSArray *)items;

- (AAPLListOperationInfo)moveItem:(AAPLListItem *)item toIndex:(NSInteger)toIndex;

- (void)insertItem:(AAPLListItem *)item atIndex:(NSInteger)index;
- (NSIndexSet *)insertItems:(NSArray *)items;

- (AAPLListOperationInfo)toggleItem:(AAPLListItem *)item withPreferredDestinationIndex:(NSInteger)preferredDestinationIndex;

- (NSInteger)insertItem:(AAPLListItem *)item;

- (void)updateAllItemsToCompletionState:(BOOL)completeStatus;

@property (nonatomic, readonly, copy) NSArray *allItems;

- (BOOL)isEqualToList:(AAPLList *)list;

@end
