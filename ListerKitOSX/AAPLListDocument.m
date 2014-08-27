/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                An NSDocument subclass that represents a list. It manages the serialization / deserialization of the list object, presentation of window controllers, and more.
            
*/

#import "AAPLListDocument.h"
#import "AAPLList.h"
#import "AAPlAppConfiguration.h"

@interface AAPLListDocument()

@property BOOL makesCustomWindowControllers;

@end

@implementation AAPLListDocument

#pragma mark - Initializers

- (instancetype)initWithContentsOfURL:(NSURL *)url makesCustomWindowControllers:(BOOL)makesCustomWindowControllers error:(NSError *__autoreleasing *)error {
    self = [super initWithContentsOfURL:url ofType:AAPLAppConfigurationListerFileExtension error:error];

    if (self) {
        _makesCustomWindowControllers = makesCustomWindowControllers;
    }
    
    return self;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _list = [AAPLList new];
        _makesCustomWindowControllers = YES;
    }
    
    return self;
}

#pragma mark - Auto Save and Versions

+ (BOOL)autosavesInPlace {
    return YES;
}

#pragma mark - NSDocument Overrides

// Create window controllers from a storyboard, if desired (based on `makesWindowControllers`).
// The window controller that's used is the initial controller set in the storyboard.
- (void)makeWindowControllers {
    [super makeWindowControllers];
    
    if (self.makesCustomWindowControllers) {
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Storyboard" bundle:nil];
        
        NSWindowController *windowController = [storyboard instantiateInitialController];
        
        [self addWindowController:windowController];
    }
}

- (NSString *)defaultDraftName {
    return [AAPLAppConfiguration sharedAppConfiguration].defaultListerDraftName;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError *__autoreleasing  *)outError {
    AAPLList *deserializedList = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    if (deserializedList) {
        *outError = nil;

        self.list = deserializedList;

        [self.delegate listDocumentDidChangeContents:self];

        return YES;
    }
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{
            NSLocalizedDescriptionKey: @"Could not read file.",
            NSLocalizedFailureReasonErrorKey: @"File was in an invalid format."
        }];
    }

    return NO;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    NSData *serializedList = [NSKeyedArchiver archivedDataWithRootObject:self.list];

    if (serializedList) {
        *outError = nil;

        return serializedList;
    }
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:@{
            NSLocalizedDescriptionKey: @"Could not save file.",
            NSLocalizedFailureReasonErrorKey: @"An unexpected error occured."
        }];
    }

    return nil;
}

@end
