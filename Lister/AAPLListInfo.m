/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  AAPLListInfo is an abstraction to contain information about list documents such as their name and color.
              
 */

#import "AAPLListInfo.h"

@implementation NSURL (AAPLListInfoProvider)

- (NSURL *)URL {
    return self;
}

@end

@implementation NSMetadataItem (AAPLListInfoProvider)

- (NSURL *)URL {
    return [self valueForAttribute:NSMetadataItemURLKey];
}

@end


@interface AAPLListInfo ()

@property (nonatomic) id <AAPLListInfoProvider> provider;

@end


@implementation AAPLListInfo

#pragma mark - Initializers

- (instancetype)initWithProvider:(id <AAPLListInfoProvider>)provider {
    self = [super init];

    if (self) {
        _provider = provider;
        _color = -1;
    }

    return self;
}

#pragma mark - Property Convenience

- (NSURL *)URL {
    return self.provider.URL;
}

- (BOOL)isLoaded {
    return self.name != nil && self.color != ((AAPLListColor)-1);
}

- (void)fetchInfoWithCompletionHandler:(void (^)())completionHandler {
    if (self.isLoaded) {
        completionHandler();
        return;
    }
    
    AAPLListDocument *document = [[AAPLListDocument alloc] initWithFileURL:self.URL];
    [document openWithCompletionHandler:^(BOOL success) {
        if (success) {
            self.color = document.list.color;
            self.name = document.localizedName;

            completionHandler();

            [document closeWithCompletionHandler:nil];
        }
        else {
            [NSException raise:@"Your attempt to open the document failed." format:nil];
        }
    }];
}

- (void)createAndSaveWithCompletionHandler:(void (^)(BOOL))completionHandler {
    AAPLList *list = [[AAPLList alloc] init];
    list.color = self.color;
    
    AAPLListDocument *document = [[AAPLListDocument alloc] initWithFileURL:self.URL];
    document.list = list;
    
    [document saveToURL:self.URL forSaveOperation:UIDocumentSaveForCreating completionHandler:completionHandler];
}

- (BOOL)isEqualToListInfo:(AAPLListInfo *)listInfo {
    if (!listInfo) {
        return NO;
    }
    
    BOOL haveEqualURLs = (!self.URL && !listInfo.URL) || [self.URL isEqual:listInfo.URL];
    
    return haveEqualURLs;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[AAPLListInfo class]]) {
        return NO;
    }
    
    return [self isEqualToListInfo:(AAPLListInfo *)object];
}

- (NSUInteger)hash {
    return [self.URL hash];
}

@end
