/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  Handles application configuration logic and information.
              
 */

#import "AAPLAppConfiguration.h"

NSString *const AAPLAppConfigurationFirstLaunchUserDefaultsKey = @"AAPLAppConfigurationFirstLaunchUserDefaultsKey";
NSString *const AAPLAppConfigurationStorageOptionUserDefaultsKey = @"AAPLAppConfigurationStorageOptionUserDefaultsKey";
NSString *const AAPLAppConfigurationStoredUbiquityIdentityTokenKey = @"com.example.apple-samplecode.Lister.UbiquityIdentityToken";

NSString *const AAPLAppConfigurationStorageOptionDidChangeNotification = @"AAPLAppConfigurationStorageOptionDidChangeNotification";

NSString *const AAPLAppConfigurationListerFileExtension = @"list";

#if TARGET_OS_IPHONE
NSString *const AAPLAppConfigurationWidgetBundleIdentifier = @"com.example.apple-samplecode.Lister.ListerToday";
#elif TARGET_OS_MAC
NSString *const AAPLAppConfigurationWidgetBundleIdentifier = @"com.example.apple-samplecode.ListerOSX.ListerTodayOSX";

NSString *const AAPLAppConfigurationListerOSXBundleIdentifier = @"com.example.apple-samplecode.ListerOSX";
#endif

@implementation AAPLAppConfiguration

+ (AAPLAppConfiguration *)sharedAppConfiguration {
    static AAPLAppConfiguration *sharedAppConfiguration;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAppConfiguration = [[AAPLAppConfiguration alloc] init];
    });
    
    return sharedAppConfiguration;
}

- (AAPLAppStorage)storageOption {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:AAPLAppConfigurationStorageOptionUserDefaultsKey];

    return (AAPLAppStorage)value;
}

- (void)setStorageOption:(AAPLAppStorage)storageOption {    
    [[NSUserDefaults standardUserDefaults] setInteger:storageOption forKey:AAPLAppConfigurationStorageOptionUserDefaultsKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AAPLAppConfigurationStorageOptionDidChangeNotification object:self userInfo:nil];
}

- (BOOL)isCloudAvailable {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

- (AAPLAppStorageState)storageState {

    AAPLAppStorageState storageState;
    storageState.storageOption = self.storageOption;
    storageState.accountDidChange = [self hasUbiquityIdentityChanged];
    storageState.cloudAvailable = self.isCloudAvailable;
    
    return storageState;
}

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults registerDefaults:@{
        AAPLAppConfigurationFirstLaunchUserDefaultsKey: @YES,
        AAPLAppConfigurationStorageOptionUserDefaultsKey: @(AAPLAppStorageNotSet)
    }];
    
    if ([defaults boolForKey:AAPLAppConfigurationFirstLaunchUserDefaultsKey]) {
        [defaults setBool:NO forKey:AAPLAppConfigurationFirstLaunchUserDefaultsKey];
        
        firstLaunchHandler();
    }
}

#pragma mark - Identity

- (BOOL)hasUbiquityIdentityChanged {
    if (self.storageOption != AAPLAppStorageCloud) {
        return NO;
    }
    
    BOOL hasChanged = NO;
    id <NSObject, NSCopying, NSCoding> currentToken = [NSFileManager defaultManager].ubiquityIdentityToken;
    id <NSObject, NSCopying, NSCoding> storedToken = [self storedUbiquityIdentityToken];
    
    BOOL currentTokenNilStoredNonNil = !currentToken && storedToken;
    BOOL storedTokenNilCurrentNonNil = !storedToken && currentToken;
    BOOL currentNotEqualStored = currentToken && storedToken && ![currentToken isEqual:storedToken];
    
    if (currentTokenNilStoredNonNil || storedTokenNilCurrentNonNil || currentNotEqualStored) {
        [self handleUbiquityIdentityChange];
        hasChanged = YES;
    }
    
    return hasChanged;
}

- (void)handleUbiquityIdentityChange {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id <NSObject, NSCopying, NSCoding> token = [NSFileManager defaultManager].ubiquityIdentityToken;
    if (token) {
        // the account has changed
        NSData *ubiquityIdentityTokenArchive = [NSKeyedArchiver archivedDataWithRootObject:token];
        [defaults setObject:ubiquityIdentityTokenArchive forKey:AAPLAppConfigurationStoredUbiquityIdentityTokenKey];
    }
    else {
        // the is no signed-in account
        [defaults removeObjectForKey:AAPLAppConfigurationStoredUbiquityIdentityTokenKey];
    }
    
    [defaults synchronize];
}

- (id <NSObject, NSCopying, NSCoding>)storedUbiquityIdentityToken {
    id storedToken = nil;
    
    // Determine if the iCloud account associated with this device has changed since the last time the user launched the app.
    NSData *ubiquityIdentityTokenArchive = [[NSUserDefaults standardUserDefaults] objectForKey:AAPLAppConfigurationStoredUbiquityIdentityTokenKey];
    if (ubiquityIdentityTokenArchive) {
        storedToken = [NSKeyedUnarchiver unarchiveObjectWithData:ubiquityIdentityTokenArchive];
    }
    
    return storedToken;
}

#pragma mark - Localization Support

- (NSString *)localizedTodayDocumentName {
    return NSLocalizedString(@"Today", @"");
}

- (NSString *)localizedTodayDocumentNameAndExtension {
    return [NSString stringWithFormat:@"%@.%@", self.localizedTodayDocumentName, AAPLAppConfigurationListerFileExtension];
}

- (NSString *)defaultListerDraftName {
    return NSLocalizedString(@"List", @"");
}

@end
