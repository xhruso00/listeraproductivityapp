/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  AAPLListInfo is an abstraction to contain information about list documents such as their name and color.
              
 */

@import Foundation;
@import ListerKit;

@protocol AAPLListInfoProvider <NSObject>
@property (readonly) NSURL *URL;
@end

// Make NSURL an AAPLListInfoProvider, since it's by default an NSURL.
@interface NSURL (AAPLListInfoProvider)<AAPLListInfoProvider>
@end

// Make NSMetadataItem an AAPLListInfoProvider and return its value for the NSMetadataItemURLKey attribute.
@interface NSMetadataItem (AAPLListInfoProvider)<AAPLListInfoProvider>
@end


@interface AAPLListInfo : NSObject

@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, getter=isLoaded) BOOL loaded;

@property AAPLListColor color;

// Typically just the NSURL would be enough as a backing object to our table view. However,
// using a generic object to describe the file offers us the flexibility to easily add properties.
- (instancetype)initWithProvider:(id <AAPLListInfoProvider>)provider;

- (void)fetchInfoWithCompletionHandler:(void (^)())completionHandler;
- (void)createAndSaveWithCompletionHandler:(void (^)(BOOL))completionHandler;

@end
