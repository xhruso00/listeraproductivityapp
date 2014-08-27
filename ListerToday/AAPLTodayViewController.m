/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                   Handles display of the Today view. It leverages iCloud for seamless interaction between devices.
              
 */

#import "AAPLTodayViewController.h"
#import "AAPLCheckBoxCell.h"

const CGFloat AAPLTodayRowHeight = 44.f;
const NSInteger AAPLTodayBaseRowCount = 5;

NSString *AAPLTodayViewControllerContentCellIdentifier = @"todayViewCell";
NSString *AAPLTodayViewControllerMessageCellIdentifier = @"messageCell";


@interface AAPLTodayViewController ()<NCWidgetProviding>

@property (strong) AAPLListDocument *document;
@property (nonatomic, readonly) AAPLList *list;
@property (strong) NSMetadataQuery *documentMetadataQuery;
@property (nonatomic) BOOL showingAll;
@property (nonatomic, readonly, getter=isCloudAvailable) BOOL cloudAvailable;
@property (nonatomic, readonly, getter=isTodayAvailable) BOOL todayAvailable;

@end

@implementation AAPLTodayViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    if (self.cloudAvailable) {
        [self startQuery];
    }
    
    [self resetContentSize];

    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.todayAvailable) {
        [self.document closeWithCompletionHandler:nil];
    }
}

#pragma mark - NCWidgetProviding

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsMake(defaultMarginInsets.top, 27.f, defaultMarginInsets.bottom, defaultMarginInsets.right);
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    if (completionHandler) {
        completionHandler(NCUpdateResultNewData);
    }
}

#pragma mark - Query Management

- (void)startQuery {
    if (!self.documentMetadataQuery) {
        NSMetadataQuery *metadataQuery = [[NSMetadataQuery alloc] init];
        self.documentMetadataQuery = metadataQuery;
        self.documentMetadataQuery.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];

        NSString *localizedTodayListName = [AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentNameAndExtension;
        self.documentMetadataQuery.predicate = [NSPredicate predicateWithFormat:@"(%K = %@)" argumentArray:@[NSMetadataItemFSNameKey, localizedTodayListName]];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(handleMetadataQueryUpdates:) name:NSMetadataQueryDidFinishGatheringNotification object:metadataQuery];
        [notificationCenter addObserver:self selector:@selector(handleMetadataQueryUpdates:) name:NSMetadataQueryDidUpdateNotification object:metadataQuery];
    }
    
    [self.documentMetadataQuery startQuery];
}

- (void)handleMetadataQueryUpdates:(NSNotification *)notification {
    [self.documentMetadataQuery disableUpdates];
    
    [self processMetadataItems];
    
    [self.documentMetadataQuery enableUpdates];
}

- (void)processMetadataItems {
    NSArray *metadataItems = self.documentMetadataQuery.results;

    // We only expect a single result to be returned by our NSMetadataQuery since we query for a specific file.
    if (metadataItems.count == 1) {
        NSURL *url = [metadataItems.firstObject valueForAttribute:NSMetadataItemURLKey];

        self.document = [[AAPLListDocument alloc] initWithFileURL:url];

        [self.document openWithCompletionHandler:^(BOOL success) {
            if (!success) {
                NSLog(@"Couldn't open document: %@.", self.document.fileURL.absoluteString);
                return;
            }
            
            [self resetContentSize];
            [self.tableView reloadData];
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.isTodayAvailable) {
        return 1;
    }
    
    return self.showingAll ? self.list.count : MIN(self.list.count, AAPLTodayBaseRowCount + 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.cloudAvailable) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AAPLTodayViewControllerMessageCellIdentifier forIndexPath:indexPath];

        cell.textLabel.text = NSLocalizedString(@"Today requires iCloud", nil);

        return cell;
    }

    NSInteger itemCount = self.list.count;
    
    if (itemCount > 0) {
        AAPLListItem *item = self.list[indexPath.row];
        
        if (!self.showingAll && indexPath.row == AAPLTodayBaseRowCount && itemCount != AAPLTodayBaseRowCount + 1) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AAPLTodayViewControllerMessageCellIdentifier forIndexPath:indexPath];

            cell.textLabel.text = NSLocalizedString(@"Show All...", nil);

            return cell;
        }
        else {
            AAPLCheckBoxCell *cell = [tableView dequeueReusableCellWithIdentifier:AAPLTodayViewControllerContentCellIdentifier forIndexPath:indexPath];

            [self configureListItemCell:cell usingColor:self.list.color item:item];

            return cell;
        }
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AAPLTodayViewControllerMessageCellIdentifier forIndexPath:indexPath];
    if (self.todayAvailable) {
        cell.textLabel.text = NSLocalizedString(@"No items in today's list", nil);
    }
    else {
        cell.textLabel.text = @"";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.layer.backgroundColor = [UIColor clearColor].CGColor;
}

- (void)configureListItemCell:(AAPLCheckBoxCell *)itemCell usingColor:(AAPLListColor)color item:(AAPLListItem *)item {
    itemCell.checkBox.tintColor = AAPLColorFromListColor(color);
    itemCell.checkBox.checked = item.isComplete;
    itemCell.label.text = item.text;

    itemCell.label.textColor = [UIColor whiteColor];

    // Configure a completed list item cell.
    if (item.isComplete) {
        itemCell.label.textColor = [UIColor lightGrayColor];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Show all of the cells if the user taps the "Show All..." row.
    if (self.todayAvailable && !self.showingAll && indexPath.row == AAPLTodayBaseRowCount) {
        self.showingAll = YES;
        
        [self.tableView beginUpdates];
        
        NSIndexPath *indexPathForRemoval = [NSIndexPath indexPathForRow:AAPLTodayBaseRowCount inSection:0];

        [self.tableView deleteRowsAtIndexPaths:@[indexPathForRemoval] withRowAnimation:UITableViewRowAnimationFade];
        
        NSMutableArray *inserted = [NSMutableArray array];
        
        for (NSInteger i = AAPLTodayBaseRowCount; i < self.list.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [inserted addObject:indexPath];
        }
        
        [self.tableView insertRowsAtIndexPaths:inserted withRowAnimation:UITableViewRowAnimationFade];
        
        [self.tableView endUpdates];
        
        return;
    }
    
    // Open the main app if an item is tapped.
    NSURL *url = [NSURL URLWithString:@"lister://today"];
    [self.extensionContext openURL:url completionHandler:nil];
}

#pragma mark - IBActions

- (IBAction)checkBoxTapped:(AAPLCheckBox *)sender {
    NSIndexPath *indexPath = [self indexPathForView:sender];
    
    AAPLListItem *item = self.list[indexPath.row];
    AAPLListOperationInfo info = [self.list toggleItem:item withPreferredDestinationIndex:NSNotFound];
    if (info.fromIndex == info.toIndex) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        NSInteger itemCount = self.list.count;
        
        if (!self.showingAll && itemCount != AAPLTodayBaseRowCount && info.toIndex > AAPLTodayBaseRowCount - 1) {
            // Completing has moved an item off the bottom of the short list.
            // Delete the completed row and insert a new row above "Show All...".
            NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:AAPLTodayBaseRowCount - 1 inSection:0];
            
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[targetIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        } else {
            // Need to animate the row up or down depending on its completion state.
            NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:info.toIndex inSection:0];
            
            [self.tableView beginUpdates];
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:targetIndexPath];
            [self.tableView endUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[targetIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    
    // Notify the document of a change.
    [self.document updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - Convenience

- (AAPLList *)list {
    return self.document.list;
}

- (BOOL)isCloudAvailable {
    return [AAPLAppConfiguration sharedAppConfiguration].isCloudAvailable;
}

- (BOOL)isTodayAvailable {
    return self.cloudAvailable && self.document && self.list;
}

- (void)resetContentSize {
    CGSize preferredSize = self.preferredContentSize;

    preferredSize.height = self.preferredViewHeight;

    self.preferredContentSize = preferredSize;
}
                         
- (CGFloat)preferredViewHeight {
    NSInteger itemCount = self.todayAvailable && self.list.count > 0 ? self.list.count : 1;

    NSInteger rowCount = self.showingAll ? itemCount : MIN(itemCount, AAPLTodayBaseRowCount + 1);
    
    return rowCount * AAPLTodayRowHeight;
}

- (NSIndexPath *)indexPathForView:(UIView *)view {
    CGPoint viewOrigin = view.bounds.origin;
    CGPoint viewLocation = [self.tableView convertPoint:viewOrigin fromView:view];
    
    return [self.tableView indexPathForRowAtPoint:viewLocation];
}

- (void)setShowingAll:(BOOL)showingAll {
    if (showingAll != _showingAll) {
        _showingAll = showingAll;
        
        [self resetContentSize];
    }
}

@end
