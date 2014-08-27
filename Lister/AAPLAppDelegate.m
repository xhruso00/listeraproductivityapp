/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  The application delegate.
              
 */

#import "AAPLAppDelegate.h"
#import "AAPLListDocumentsViewController.h"
#import "AAPLListInfo.h"
@import ListerKit;

NSString *const AAPLAppDelegateMainStoryboardName = @"Main";
NSString *const AAPLAppDelegateMainStoryboardEmptyViewControllerIdentifier = @"emptyViewController";

@interface AAPLAppDelegate ()<UISplitViewControllerDelegate>

// The root view controller of the window will always be a UISplitViewController. This is setup in the main storyboard.
@property (nonatomic, readonly) UISplitViewController *splitViewController;

// The primary view controller of the split view controller defined in the main storyboard.
@property (nonatomic, readonly) UINavigationController *primaryViewController;

// The view controller that displays the list of documents. If it's not visible, then this value is nil.
@property (nonatomic, readonly) AAPLListDocumentsViewController *listDocumentsViewController;

@end

@implementation AAPLAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[AAPLAppConfiguration sharedAppConfiguration] runHandlerOnFirstLaunch:^{
        [[AAPLListCoordinator sharedListCoordinator] copyInitialDocuments];
    }];
    
    // Set ourselves as the split view controller's delegate.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    splitViewController.delegate = self;
    
    return YES;
}

#pragma mark - View Controller Accessor Convenience

- (UISplitViewController *)splitViewController {
    return (UISplitViewController *)self.window.rootViewController;
}

- (UINavigationController *)primaryViewController {
    return self.splitViewController.viewControllers.firstObject;
}

- (AAPLListDocumentsViewController *)listDocumentsViewController {
    return (AAPLListDocumentsViewController *)self.primaryViewController.topViewController;
}

#pragma mark - UISplitViewControllerDelegate

- (UISplitViewControllerDisplayMode)targetDisplayModeForActionInSplitViewController:(UISplitViewController *)splitViewController {
    return UISplitViewControllerDisplayModeAllVisible;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
    
    // If there's a list that's currently selected in separated mode and we want to show it in collapsed mode, we'll transfer over the view controller's settings.
    if ([secondaryViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *secondaryNavigationController = (UINavigationController *)secondaryViewController;
        
        self.primaryViewController.navigationBar.titleTextAttributes = secondaryNavigationController.navigationBar.titleTextAttributes;
        self.primaryViewController.navigationBar.tintColor = secondaryNavigationController.navigationBar.tintColor;
        self.primaryViewController.toolbar.tintColor = secondaryNavigationController.toolbar.tintColor;

        [self.primaryViewController showDetailViewController:secondaryNavigationController.topViewController sender:nil];
    }

    return YES;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    if (self.primaryViewController.topViewController == self.primaryViewController.viewControllers.firstObject) {
        // If no list is on the stack, fill the detail area with an empty controller.
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:AAPLAppDelegateMainStoryboardName bundle:nil];
        UIViewController *emptyViewController = [storyboard instantiateViewControllerWithIdentifier:AAPLAppDelegateMainStoryboardEmptyViewControllerIdentifier];

        return emptyViewController;
    }

    NSDictionary *textAttributes = self.primaryViewController.navigationBar.titleTextAttributes;
    UIColor *tintColor = self.primaryViewController.navigationBar.tintColor;
    UIViewController *poppedViewController = [self.primaryViewController popViewControllerAnimated:NO];
    
    UINavigationController *navigationViewController = [[UINavigationController alloc] initWithRootViewController:poppedViewController];
    navigationViewController.navigationBar.titleTextAttributes = textAttributes;
    navigationViewController.navigationBar.tintColor = tintColor;
    navigationViewController.toolbar.tintColor = tintColor;

    return navigationViewController;
}

@end
