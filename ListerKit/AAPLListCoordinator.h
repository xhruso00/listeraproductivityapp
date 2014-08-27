/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  The AAPLListCoordinator handles file operations and tracking based on the users storage choice (local vs. cloud).
              
 */

@import Foundation;

extern NSString *const AAPLListCoordinatorStorageChoiceDidChangeNotification;

@interface AAPLListCoordinator : NSObject

+ (AAPLListCoordinator *)sharedListCoordinator;

// Document management methods.
- (void)copyInitialDocuments; 
- (void)updateDocumentStorageContainerURL;
- (void)deleteFileAtURL:(NSURL *)fileURL;

// Document naming convenience methods.
- (NSURL *)documentURLForName:(NSString *)name;
- (BOOL)isValidDocumentName:(NSString *)name;

@property (nonatomic) NSURL *documentsDirectory;
@property (nonatomic, readonly) NSURL *todayDocumentURL;

@end
