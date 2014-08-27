# Lister

## Version
1.0

## Build & Runtime Requirements
1) Xcode 6
2) iOS 8.0
3) OS X 10.10
4) iCloud–enabled provisioning profile

## Configuring the project

Configuring your Xcode project and your Mac requires a few steps in the iOS and OS X Provisioning Portals, as well as in Xcode:

1) Configure your Mac:
Each Mac and iOS device you plan to test needs to have an iCloud account. This is done by creating or using an existing Apple ID account that supports iCloud. You can do this directly on the device by opening System Preferences and selecting iCloud. Each Mac or iOS device needs to be configured with this account.
 
2) Configure the Team for the targets within the project:
Navigate to the project in the project navigator within Xcode and select each of the Targets, setting the Team on the General tab to the team associated with your developer account.

3) Xcode project Entitlements:
An entitlements file in this sample project includes the key "com.apple.developer.ubiquity-container-identifiers". For your own app you will need to use a different value to match your Team ID (or company/organization ID). The following is the container identifier shard among all of the apps included in the Lister sample.

$(TeamIdentifierPrefix)com.example.apple-samplecode.Lister
 
Where $(TeamIdentifierPrefix) is the Team ID found in the Provisioning Portal, and the rest is followed by a unique identifier to be shared among all of the apps you have.  

4) Allow Xcode to generate provisioning profiles to match your needs:
Update the bundle identifier on the Target > Info tab to a suitable value for your organization. It is recommended that you take a reverse DNS approach to creating this identifier. The bundle identifier defined on your Xcode project's Target > Info tab needs to match the App ID in the iCloud provisioning profile. If you attempt to build the project and accept the 'Fix Issue' option that Xcode provides, suitable provisioning profiles will be generated. This will allow you to assign the new profile to your Debug > Code Signing Identities in your Xcode project Target > Build Settings. 
 
Note: If your provisioning profile's App ID is "<your TeamID>.com.example.apple-samplecode.Lister", then the bundle identifier of your app must be "com.example.apple-samplecode.Lister". 
5) Set your "Code Signing" identity in your Xcode project to match your particular App ID.

## Introduction
Lister is a Cocoa productivity sample code project for iOS and OS X. In this sample, the user can create lists, add items to lists, and track the progress of items in the lists. This sample is built using Objective-C, but you can also find a Swift version of Lister at https://developer.apple.com/library/ios/lister_swift or https://developer.apple.com/library/mac/lister_swift.


## Application Architecture
The Lister project includes iOS and OS X app targets, iOS and OS X app extensions, and frameworks containing shared code.

### OS X

Lister for OS X is a document-based application with a single window per document. To organize the implementation of the app, Lister takes a modular design approach. Three main controllers are each responsible for different portions of the user interface and document interaction: AAPLListWindowController manages a single window and owns the document associated with the window. The window controller also implements interactions with the window’s toolbar such as sharing. The window controller is also responsible for presenting an AAPLAddItemViewController object that allows the user to quickly add an item to the list. Finally, AAPLListViewController is responsible for displaying each item in a table view in the window.

Lister's design and controller interactions are implemented in a Mac Storyboard. This makes it easy to visualize the relationships between view controllers and lay out the user interface of the app. Lister also takes advantage of Auto Layout to fluidly resize the interface as the user resizes the window. If you're opening the project for the first time, the Storyboard.storyboard file is a good place to understand how the app works.

While much of the view layer is implemented with built in AppKit views and controls, there are several interesting custom views in Lister. The AAPLColorPaletteView class is an interface to select a list's color. When the user shows or hides the color palette, the view dynamically animates the constraints defined in Interface Builder. The AAPLListTableView and AAPLTableRowView classes are responsible for displaying list items in the table view.

Document storage in Lister is implemented in the AAPLListDocument class, a subclass of NSDocument. Documents are stored as keyed archives. AAPLListDocument reuses much of the same model code shared between the OS X and iOS apps. Additionally, the AAPLListDocument class enables Auto Save and Versions, undo management, and more. With the AAPLListFormatting class, the user can copy and paste items between Lister and other apps, and even share items.

The Lister app manages a Today list that it stores in iCloud document storage. The AAPLTodayListManager class is responsible for creating, locating, and retrieving the today AAPLListDocument object from the user's iCloud container. You can open the Today list with the Command-T key combination.

### iOS

The iOS version of Lister follows many of the same design principles as the OS X version—sharing common code. It follows the Model-View-Controller (MVC) design pattern and uses modern app development practices including Storyboards and Auto Layout. In the iOS version of Lister, the user manages multiple lists using a table view implemented in the AAPLListDocumentsViewController class. In addition to vending rows in the table view, the list documents controller observes changes to the lists, as well as the status of iCloud. Tapping on a list bring the user to the AAPLListViewController. This class displays and manages a single document. Finally, the AAPLNewListDocumentController class allows a user to create a new list.

The AAPLListCoordinator class tracks the user's storage choice—local or iCloud—and moves the user's documents between the two storage locations. The AAPLListDocument class, a subclass of UIDocument, represents an individual list document that is responsible for serialization and deserialization. 

Rather than directly manage List objects, the AAPLListDocumentsViewController class manages an array of AAPLListInfo objects. The ListInfo class abstracts the particular storage mechanism away from API that contain similar metadata-related properties required for display (a list’s name and color). To handle this, the backing metadata is provided by an object that conforms to the AAPLListInfoProvider protocol—either an NSURL object or an NSMetadataItem object. 

### Shared Code

Much of the model layer code for Lister is used throughout the entire project, across the iOS and OS X platforms. AAPLList and AAPLListItem are the two main model objects. The AAPLListItem class represents a single item in a list. It contains just three stored properties: the text of the item, whether the user has completed it, and a unique identifier. Along with these properties, the AAPLListItem class also implements the functionality required to compare, archive, and unarchive a AAPLListItem object. The AAPLList class holds an array of these AAPLListItem objects, as well as the color the desired list color. This class also supports indexed subscripting, archiving, unarchiving, and equality.

Archiving and unarchiving are specifically designed and implemented such that model objects can be unarchived regardless of the language, Swift or Objective–C, or the platform, iOS or OS X, that they were archived on.

In addition to model code, by subclassing CALayer—a class shared by iOS and OS X—Lister shares check box drawing code with both platforms. The project then includes a control class for each platform with user interface framework–specific code. These AAPLCheckBox classes use the designable and inspectable attributes so that the custom drawing code is viewable and adjustable live in Interface Builder.

## Release Notes:

On OS X, it’s a known issue that the destination view controller’s -presentingViewController: returns nil if used in a popover segue. As a workaround, you can use the escape key instead of the enter key when creating new list items in the OS X version of Lister.

===========================================================================
Copyright (C) 2014 Apple Inc. All rights reserved.
