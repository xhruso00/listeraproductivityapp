/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                 A UIDocument subclass that represents a list. It mainly manages the serialization / deserialization of the list object.
             
 */

#import "AAPLListDocument.h"

@implementation AAPLListDocument

#pragma mark - Serialization / Deserialization

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * __autoreleasing*)outError {
    AAPLList *deserializedList = [NSKeyedUnarchiver unarchiveObjectWithData:contents];
    if (deserializedList) {
        self.list = deserializedList;
        return YES;
    }
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Could not read file", @"Read error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"File was in an invalid format", @"Read failure reason")
        }];
        
    }
    
    return NO;
}

- (id)contentsForType:(NSString *)typeName error:(NSError * __autoreleasing*)outError {
    NSData *serializedList = [NSKeyedArchiver archivedDataWithRootObject:self.list];

    if (serializedList) {
        return serializedList;
    }
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:@{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Could not save file", @"Write error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"An unexpected error occured", @"Write failure reason")
        }];
    }

    return nil;
}

#pragma mark - Deletion

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler {
    [super accommodatePresentedItemDeletionWithCompletionHandler:completionHandler];

    [self.delegate listDocumentWasDeleted:self];
}

@end
