/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                 The AAPLListCoordinator handles file operations and tracking based on the users storage choice (local vs. cloud).
              
 */

#import "AAPLListCoordinator.h"
#import "AAPLAppConfiguration.h"

NSString *const AAPLListCoordinatorStorageChoiceDidChangeNotification = @"AAPLListCoordinatorStorageChoiceDidChangeNotification";

@implementation AAPLListCoordinator

+ (AAPLListCoordinator *)sharedListCoordinator {
    static AAPLListCoordinator *sharedListCoordinator;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedListCoordinator = [[AAPLListCoordinator alloc] init];
        
        sharedListCoordinator.documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
        
        [[NSNotificationCenter defaultCenter] addObserver:sharedListCoordinator selector:@selector(updateDocumentStorageContainerURL) name:AAPLAppConfigurationStorageOptionDidChangeNotification object:nil];
    });
    
    return sharedListCoordinator;
}

#pragma mark - Properties

- (NSURL *)todayDocumentURL {
    NSString *todayFileName = [AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentNameAndExtension;

    return [self.documentsDirectory URLByAppendingPathComponent:todayFileName];
}

#pragma mark - Document Management

- (void)copyInitialDocuments {
    NSArray *defaultListURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:AAPLAppConfigurationListerFileExtension subdirectory:@""];
    
    for (NSURL *url in defaultListURLs) {
        [self copyFileToDocumentsDirectory:url];
    }
}

- (void)updateDocumentStorageContainerURL {
    NSURL *oldDocumentsDirectory = self.documentsDirectory;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([AAPLAppConfiguration sharedAppConfiguration].storageOption != AAPLAppStorageCloud) {
        self.documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AAPLListCoordinatorStorageChoiceDidChangeNotification object:self];
    }
    else {
        dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        dispatch_async(defaultQueue, ^{
            // The call to URLForUbiquityContainerIdentifier should be on a background queue.
            NSURL *cloudDirectory = [fileManager URLForUbiquityContainerIdentifier:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.documentsDirectory = [cloudDirectory URLByAppendingPathComponent:@"Documents"];
                
                NSError *error;
                NSArray *localDocuments = [fileManager contentsOfDirectoryAtURL:oldDocumentsDirectory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsPackageDescendants error:&error];
                
                for (NSURL *url in localDocuments) {
                    if ([url.pathExtension isEqualToString:AAPLAppConfigurationListerFileExtension]) {
                        [self makeItemUbiquitousAtURL:url];
                    }
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:AAPLListCoordinatorStorageChoiceDidChangeNotification object:self];
            });
        });
    }
}

- (void)makeItemUbiquitousAtURL:(NSURL *)sourceURL {
    NSString *destinationFileName = sourceURL.lastPathComponent;
    NSURL *destinationURL = [self.documentsDirectory URLByAppendingPathComponent:destinationFileName];
    
    // Upload the file to iCloud on a background queue.
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [[NSFileManager alloc] init];

        BOOL success = [fileManager setUbiquitous:YES itemAtURL:sourceURL destinationURL:destinationURL error:nil];
        
        // If the move wasn't successful, try removing the item locally since the document may already exist in the cloud.
        if (!success) {
            [fileManager removeItemAtURL:sourceURL error:nil];
        }
    });
}

#pragma mark - Convenience

- (void)copyFileToDocumentsDirectory:(NSURL *)fromURL {
    NSURL *toURL = [self.documentsDirectory URLByAppendingPathComponent:fromURL.lastPathComponent];
    
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    
    [fileCoordinator coordinateWritingItemAtURL:fromURL options:NSFileCoordinatorWritingForMoving writingItemAtURL:toURL options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *sourceURL, NSURL *destinationURL) {
        NSError *moveError;
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        BOOL success = [fileManager copyItemAtURL:sourceURL toURL:destinationURL error:&moveError];
        
        if (success) {
            [fileManager setAttributes:@{ NSFileExtensionHidden: @YES } ofItemAtPath:destinationURL.path error:nil];

            NSLog(@"Moved file: %@ to: %@.", sourceURL.absoluteString, destinationURL.absoluteString);
        }
        else {
            // In your app, handle this gracefully.
            NSLog(@"Couldn't move file: %@ to: %@. Error: %@.", sourceURL.absoluteString, destinationURL.absoluteString, moveError.description);
        }
    }];
}

- (void)deleteFileAtURL:(NSURL *)fileURL {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    __block NSError *error;
    
    [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL *writingURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        [fileManager removeItemAtURL:writingURL error:&error];
    }];
    
    if (error) {
        // In your app, handle this gracefully.
        NSLog(@"Couldn't delete file at URL %@. Error: %@.", fileURL.absoluteString, error.description);
        abort();
    }
}

#pragma mark - Document Name Helper Methods

- (NSURL *)documentURLForName:(NSString *)name {
    return [[self.documentsDirectory URLByAppendingPathComponent:name] URLByAppendingPathExtension:AAPLAppConfigurationListerFileExtension];
}

- (BOOL)isValidDocumentName:(NSString *)name {
    if (name.length <= 0) {
        return NO;
    }
    
    NSString *proposedDocumentPath = [self documentURLForName:name].path;

    return ![[NSFileManager defaultManager] fileExistsAtPath:proposedDocumentPath];
}

@end
