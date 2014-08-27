/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  Displays the contents of a list document, allows a user to create, update, and delete items, change the color of the list, or delete the list.
              
 */

@import NotificationCenter;
@import ListerKit;

#import "AAPLListViewController.h"
#import "AAPLListItemCell.h"
#import "AAPLListColorCell.h"
#import "AAPLListInfo.h"

// Notifications
NSString *const AAPLListViewControllerListDidUpdateColorNotification = @"AAPLListViewControllerListDidUpdateColorNotification";

// Notification User Info Keys
NSString *const AAPLListViewControllerListDidUpdateColorUserInfoKey = @"AAPLListViewControllerListDidUpdateColorUserInfoKey";
NSString *const AAPLListViewControllerListDidUpdateURLUserInfoKey = @"AAPLListViewControllerListDidUPdateURLUserInfoKey";

// UITableViewCell Identifiers
NSString *const AAPLListViewControllerListItemCellIdentifier = @"listItemCell";
NSString *const AAPLListViewControllerListColorCellIdentifier = @"listColorCell";

@interface AAPLListViewController ()<UITextFieldDelegate, AAPLListColorCellDelegate, AAPLListDocumentDelegate>

@property (nonatomic, strong) AAPLListDocument *document;
@property (nonatomic, readonly) AAPLList *list;

@property (nonatomic, copy) NSDictionary *textAttributes;

@end

@implementation AAPLListViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateInterfaceWIthTextAttributes];
    
    // Use the edit button item provided by the table view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.document openWithCompletionHandler:^(BOOL success) {
        if (!success) {
            // In your app you should handle this gracefully.
            NSLog(@"Couldn't open document: %@.", self.documentURL.absoluteString);
            abort();
        }
        
        [self.tableView reloadData];

        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentStateChangedNotification:) name:UIDocumentStateChangedNotification object:self.document];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.document closeWithCompletionHandler:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDocumentStateChangedNotification object:self.document];
    
    // Hide the toolbar so the list can't be edited.
    [self.navigationController setToolbarHidden:YES animated:animated];
}

#pragma mark - Setup

- (void)configureWithListInfo:(AAPLListInfo *)listInfo {
    [listInfo fetchInfoWithCompletionHandler:^{
        self.document = [[AAPLListDocument alloc] initWithFileURL:listInfo.URL];
        self.document.delegate = self;
        
        self.navigationItem.title = listInfo.name;
        
        self.textAttributes = @{
            NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
            NSForegroundColorAttributeName: AAPLColorFromListColor(listInfo.color)
        };
    }];
}

#pragma mark - Notifications

- (void)handleDocumentStateChangedNotification:(NSNotification *)notification {
    UIDocumentState state = self.document.documentState;
    
    if (state & UIDocumentStateInConflict) {
        [self resolveConflicts];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - UIViewController Overrides

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    // Prevent navigating back in edit mode.
    [self.navigationItem setHidesBackButton:editing animated:animated];
    
    // Reload the first row to switch from "Add Item" to "Change Color"
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    // If moving out of edit mode, notify observers about the list color and trigger a save.
    if (!editing) {
        // Notify the document of a change.
        [self.document updateChangeCount:UIDocumentChangeDone];

        [[NSNotificationCenter defaultCenter] postNotificationName:AAPLListViewControllerListDidUpdateColorNotification object:nil userInfo:@{
            AAPLListViewControllerListDidUpdateColorUserInfoKey: @(self.list.color),
            AAPLListViewControllerListDidUpdateURLUserInfoKey: self.documentURL
        }];
        
        [self triggerNewDataForWidget];
    }

    [self.navigationController setToolbarHidden:!editing animated:animated];
    [self.navigationController.toolbar setItems:self.listToolbarItems animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.document) {
        // Don't show anything if the document hasn't been loaded.
        return 0;
    }

    // We show the items in a list, plus a separate row that lets users enter a new item.
    return self.list.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing && indexPath.row == 0) {
        AAPLListColorCell *colorCell = [tableView dequeueReusableCellWithIdentifier:AAPLListViewControllerListColorCellIdentifier forIndexPath:indexPath];
        
        [colorCell configure];
        colorCell.delegate = self;
        
        return colorCell;
    } else {
        AAPLListItemCell *itemCell = [tableView dequeueReusableCellWithIdentifier:AAPLListViewControllerListItemCellIdentifier forIndexPath:indexPath];

        [self configureListItemCell:itemCell usingColor:self.list.color forRow:indexPath.row];
        
        return itemCell;
    }
}

- (void)configureListItemCell:(AAPLListItemCell *)itemCell usingColor:(AAPLListColor)color forRow:(NSInteger)row {
    itemCell.textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    itemCell.textField.delegate = self;
    
    if (row == 0) {
        // Configure an "Add Item" list item cell.
        itemCell.textField.placeholder = NSLocalizedString(@"Add Item", nil);
        itemCell.checkBox.hidden = NO;
    }
    else {
        AAPLListItem *item = self.list[row - 1];
        
        itemCell.complete = item.isComplete;
        itemCell.textField.text = item.text;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // The initial row is reserved for adding new items so it can't be deleted or edited.
    if (indexPath.row == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // The initial row is reserved for adding new items so it can't be moved.
    if (indexPath.row == 0) {
        return NO;
    }
    
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }

    AAPLListItem *item = self.list[indexPath.row - 1];
    [self.list removeItems:@[item]];
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self triggerNewDataForWidget];
    
    // Notify the document of a change.
    [self.document updateChangeCount:UIDocumentChangeDone];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    AAPLListItem *item = self.list[fromIndexPath.row - 1];
    [self.list moveItem:item toIndex:toIndexPath.row - 1];
    
    // Notify the document of a change.
    [self.document updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    // When the user swipes to show the delete confirmation, don't enter editing mode.
    // UITableViewController enters editing mode by default so we override without calling super.
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    // When the user swipes to hide the delete confirmation, no need to exit edit mode because we didn't enter it.
    // UITableViewController enters editing mode by default so we override without calling super.
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath {
    AAPLListItem *item = self.list[fromIndexPath.row - 1];
    
    if (proposedIndexPath.row == 0) {
        NSInteger row = item.isComplete ? self.list.indexOfFirstCompletedItem + 1 : 1;

        return [NSIndexPath indexPathForRow:row inSection:0];
    }
    else if ([self.list canMoveItem:item toIndex:proposedIndexPath.row - 1 inclusive:NO]) {
        return proposedIndexPath;
    }
    else if (item.isComplete) {
        return [NSIndexPath indexPathForRow:self.list.indexOfFirstCompletedItem + 1 inSection:0];
    }
    else {
        return [NSIndexPath indexPathForRow:self.list.indexOfFirstCompletedItem inSection:0];
    }
    
    return proposedIndexPath;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [self indexPathForView:textField];
    
    if (indexPath.row > 0) {
        // Edit the item in place.
        AAPLListItem *item = self.list[indexPath.row - 1];
        
        // If the contents of the text field at the end of editing is the same as it started, don't trigger an update.
        if (![item.text isEqualToString:textField.text]) {
            item.text = textField.text;
            
            [self triggerNewDataForWidget];
            
            // Notify the document of a change.
            [self.document updateChangeCount:UIDocumentChangeDone];
        }
    } else if (textField.text.length > 0) {
        // Adds the item to the top of the list.
        AAPLListItem *item = [[AAPLListItem alloc] initWithText:textField.text];
        NSInteger insertedIndex = [self.list insertItem:item];
        
        // Update the edit row to show the check box.
        AAPLListItemCell *itemCell = (AAPLListItemCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        itemCell.checkBox.hidden = NO;
        
        // Insert a new add item row into the table view.
        [self.tableView beginUpdates];
        
        NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:insertedIndex inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[targetIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        [self triggerNewDataForWidget];
        
        // Notify the document of a change.
        [self.document updateChangeCount:UIDocumentChangeDone];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSIndexPath *indexPath = [self indexPathForView:textField];
    
    // An item must have text to dismiss the keyboard.
    if (textField.text.length > 0 || indexPath.row == 0) {
        [textField resignFirstResponder];
        return YES;
    }
    
    return NO;
}

#pragma mark - AAPLListColorCellDelegate

- (void)listColorCellDidChangeSelectedColor:(AAPLListColorCell *)listColorCell {
    self.list.color = listColorCell.selectedColor;
    
    self.textAttributes = @{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName: AAPLColorFromListColor(self.list.color)
    };
    
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

# pragma mark - IBActions

- (void)deleteList:(id)sender {
    [self.delegate listViewControllerDidDeleteList:self];
    
    if (self.splitViewController.isCollapsed) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)checkBoxTapped:(AAPLCheckBox *)sender {
    NSIndexPath *indexPath = [self indexPathForView:sender];
   
    if (indexPath.row >= 1 && indexPath.row <= self.list.count) {
        AAPLListItem *item = self.list[indexPath.row - 1];
        AAPLListOperationInfo info = [self.list toggleItem:item withPreferredDestinationIndex:NSNotFound];
        
        if (info.fromIndex == info.toIndex) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else {
            // Animate the row up or down depending on whether it was complete/incomplete.
            NSIndexPath *target = [NSIndexPath indexPathForRow:info.toIndex + 1 inSection:0];
            
            [self.tableView beginUpdates];
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:target];
            [self.tableView endUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[target] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        [self triggerNewDataForWidget];
        
        // notify the document that we've made a change
        [self.document updateChangeCount:UIDocumentChangeDone];
    }
}

#pragma mark - AAPLListDocumentDelegate

- (void)listDocumentWasDeleted:(AAPLListDocument *)document {
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Convenience

- (NSURL *)documentURL {
    return self.document.fileURL;
}

- (AAPLList *)list {
    return self.document.list;
}

- (void)setTextAttributes:(NSDictionary *)textAttributes {
    _textAttributes = [textAttributes copy];

    if (self.isViewLoaded) {
        [self updateInterfaceWIthTextAttributes];
    }
}

- (NSArray *)listToolbarItems {
    static NSArray *_listToolbarItems = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *title = NSLocalizedString(@"Delete List", nil);
        UIBarButtonItem *deleteList = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(deleteList:)];

        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

        _listToolbarItems = @[flexibleSpace, deleteList, flexibleSpace];
    });
    
    return _listToolbarItems;
}

- (void)triggerNewDataForWidget {
    NSString *localizedTodayDocumentName = [AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentName;
    
    if ([self.document.localizedName isEqualToString:localizedTodayDocumentName]) {
        [[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:AAPLAppConfigurationWidgetBundleIdentifier];
    }
}

- (void)updateInterfaceWIthTextAttributes {
    self.navigationController.navigationBar.titleTextAttributes = self.textAttributes;
    self.navigationController.navigationBar.tintColor = self.textAttributes[NSForegroundColorAttributeName];
    self.navigationController.toolbar.tintColor = self.textAttributes[NSForegroundColorAttributeName];
    self.tableView.tintColor = self.textAttributes[NSForegroundColorAttributeName];
}

- (void)resolveConflicts {
    // Any automatic merging logic or presentation of conflict resolution UI should go here.
    // For this sample, just pick the current version and mark the conflict versions as resolved.
    [NSFileVersion removeOtherVersionsOfItemAtURL:self.documentURL error:nil];

    NSArray *conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.documentURL];
    for (NSFileVersion *fileVersion in conflictVersions) {
        fileVersion.resolved = YES;
    }
}

- (NSIndexPath *)indexPathForView:(UIView *)view {
    CGPoint viewOrigin = view.bounds.origin;

    CGPoint viewLocation = [self.tableView convertPoint:viewOrigin fromView:view];
    
    return [self.tableView indexPathForRowAtPoint:viewLocation];
}

@end
