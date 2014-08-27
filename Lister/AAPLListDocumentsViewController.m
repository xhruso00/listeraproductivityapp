/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  Handles displaying a list of available documents for users to open.
              
 */

@import ListerKit;

#import "AAPLListDocumentsViewController.h"
#import "AAPLNewListDocumentController.h"
#import "AAPLListViewController.h"
#import "AAPLListCell.h"
#import "AAPLListInfo.h"

// User defaults keys.
NSString *const AAPLAppDelegateStorageOptionUserDefaultsKey = @"AAPLAppDelegateStorageOptionKey";
NSString *const AAPLAppDelegateStorageOptionUserDefaultsLocal = @"AAPLAppDelegateStorageOptionLocal";
NSString *const AAPLAppDelegateStorageOptionUserDefaultsCloud = @"AAPLAppDelegateStorageOptionCloud";

// Segue identifiers.
NSString *const AAPLListDocumentsViewControllerListDocumentSegueIdentifier = @"showListDocument";
NSString *const AAPLListDocumentsViewControllerNewListDocumentSegueIdentifier = @"newListDocument";

NSString *const AAPLListDocumentsViewControllerListDocumentCellIdentifier = @"listDocumentCell";

NSString *const AAPLListDocumentsViewControllerEmptyViewControllerStoryboardIdentifier = @"emptyViewController";

@interface AAPLListDocumentsViewController ()<AAPLListViewControllerDelegate, AAPLNewListDocumentControllerDelegate>

@property (strong, nonatomic) NSMetadataQuery *documentMetadataQuery;
@property (strong, nonatomic) NSMutableArray *listInfos;

@end

@implementation AAPLListDocumentsViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.listInfos = [NSMutableArray array];
    
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName: AAPLColorFromListColor(AAPLListColorGray)
    };
    
    [[AAPLListCoordinator sharedListCoordinator] updateDocumentStorageContainerURL];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(handleListColorDidChangeNotification:) name:AAPLListViewControllerListDidUpdateColorNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(handleContentSizeCategoryDidChangeNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    // When the desired storage chages, start the query.
    [notificationCenter addObserver:self selector:@selector(startQuery) name:AAPLListCoordinatorStorageChoiceDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName: AAPLColorFromListColor(AAPLListColorGray)
    };

    self.navigationController.navigationBar.tintColor = AAPLColorFromListColor(AAPLListColorGray);
    self.navigationController.toolbar.tintColor = AAPLColorFromListColor(AAPLListColorGray);
    self.tableView.tintColor = AAPLColorFromListColor(AAPLListColorGray);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setupUserStoragePreferences];
}

#pragma mark - Lifetime

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AAPLListViewControllerListDidUpdateColorNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AAPLListCoordinatorStorageChoiceDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidUpdateNotification object:nil];
}

#pragma mark - Setup

- (void)selectListWithListInfo:(AAPLListInfo *)listInfo {
    UISplitViewController *splitViewController = self.splitViewController;
    
    void (^configureListViewController)(AAPLListViewController *listViewController) = ^(AAPLListViewController *listViewController) {
        [listViewController configureWithListInfo:listInfo];
        listViewController.delegate = self;
    };
    
    if (splitViewController.isCollapsed) {
        AAPLListViewController *listViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"listViewController"];
        configureListViewController(listViewController);
        [self showViewController:listViewController sender:self];
    }
    else {
        UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"listViewNavigationController"];
        AAPLListViewController *listViewController = (AAPLListViewController *)navigationController.topViewController;
        configureListViewController(listViewController);
        splitViewController.viewControllers = @[splitViewController.viewControllers.firstObject, [[UIViewController alloc] init]];
        [self showDetailViewController:navigationController sender:self];
    }
}

- (void)setupUserStoragePreferences {
    AAPLAppStorageState storageState = [AAPLAppConfiguration sharedAppConfiguration].storageState;
    
    if (storageState.accountDidChange) {
        [self notifyUserOfAccountChange];
    }
    
    if (storageState.cloudAvailable) {
        if (storageState.storageOption == AAPLAppStorageNotSet) {
            [self promptUserForStorageOption];
        }
        else {
            [self startQuery];
        }
    }
    else {
        [AAPLAppConfiguration sharedAppConfiguration].storageOption = AAPLAppStorageNotSet;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listInfos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLListCell *cell = [tableView dequeueReusableCellWithIdentifier:AAPLListDocumentsViewControllerListDocumentCellIdentifier forIndexPath:indexPath];
    
    AAPLListInfo *listInfo = self.listInfos[indexPath.row];
    
    // Show an empty string as the text since it may need to load.
    cell.label.text = @"";
    
    cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.label.text = listInfo.URL.lastPathComponent.stringByDeletingPathExtension;
    cell.listColorView.backgroundColor = [UIColor clearColor];
    
    // Once the list info has been loaded, update the associated cell's properties.
    void (^infoHandler)(void) = ^{
        cell.label.text = listInfo.name;
        cell.listColorView.backgroundColor = AAPLColorFromListColor(listInfo.color);
    };
    
    if (listInfo.isLoaded) {
        infoHandler();
    }
    else {
        [listInfo fetchInfoWithCompletionHandler:infoHandler];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLListInfo *listInfo = self.listInfos[indexPath.row];
    
    [self selectListWithListInfo:listInfo];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - AAPLListViewControllerDelegate

- (void)listViewControllerDidDeleteList:(AAPLListViewController *)listViewController {
    if (!self.splitViewController.isCollapsed) {
        UIViewController *emptyViewController = [self.storyboard instantiateViewControllerWithIdentifier:AAPLListDocumentsViewControllerEmptyViewControllerStoryboardIdentifier];
        [self.splitViewController showDetailViewController:emptyViewController sender:nil];
    }
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];

    [self deleteListAtURL:listViewController.documentURL];
}

#pragma mark - AAPLNewListDocumentControllerDelegate

- (void)newListViewController:(AAPLNewListDocumentController *)newListController didCreateDocumentWithListInfo:(AAPLListInfo *)listInfo {
    if ([AAPLAppConfiguration sharedAppConfiguration].storageOption != AAPLAppStorageCloud) {
        [self insertListInfo:listInfo completionHandler:^(NSUInteger index) {
            NSIndexPath *indexPathForInsertedRow = [NSIndexPath indexPathForRow:index inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[indexPathForInsertedRow] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }
}

#pragma mark - UIStoryboardSegue Handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:AAPLListDocumentsViewControllerNewListDocumentSegueIdentifier]) {
        AAPLNewListDocumentController *newListController = segue.destinationViewController;
        newListController.delegate = self;
    }
}

#pragma mark - Convenience

- (void)deleteListAtURL:(NSURL *)url {
    // Asynchonously delete the document.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[AAPLListCoordinator sharedListCoordinator] deleteFileAtURL:url];
    });
    
    // Update the document list and remove the row from the table view.
    [self removeListInfoWithProvider:url completionHandler:^(NSUInteger index) {
        NSIndexPath *indexPathForRemoval = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathForRemoval] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - List Management

- (void)startQuery {
    [self.documentMetadataQuery stopQuery];
    
    if ([AAPLAppConfiguration sharedAppConfiguration].storageOption == AAPLAppStorageCloud) {
        [self startMetadataQuery];
    }
    else {
        [self startLocalQuery];
    }
}

- (void)startLocalQuery {
    NSError *error;
    
    NSURL *documentsDirectory = [AAPLListCoordinator sharedListCoordinator].documentsDirectory;
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    // Fetch the list documents from container documents directory.
    NSArray *localDocuments = [defaultManager contentsOfDirectoryAtURL:documentsDirectory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsPackageDescendants error:&error];
    
    [self processURLs:localDocuments];
}

- (void)processURLs:(NSArray *)results {
    NSArray *previousListInfos = [self.listInfos copy];

    [self.listInfos removeAllObjects];
    
    results = [results sortedArrayUsingComparator:^NSComparisonResult(NSURL *lhs, NSURL *rhs) {
        return [lhs.lastPathComponent localizedCompare:rhs.lastPathComponent];
    }];
    
    for (NSURL *url in results) {
        if ([url.pathExtension isEqualToString:AAPLAppConfigurationListerFileExtension]) {
            [self insertListInfoWithProvider:url completionHandler:nil];
        }
    }
    
    [self processDocumentListDifferences:previousListInfos];
}

- (void)processMetadataItems {
    NSArray *previousDocumentList = [self.listInfos copy];
    
    [self.listInfos removeAllObjects];
    
    NSArray *results = [self.documentMetadataQuery.results sortedArrayUsingComparator:^NSComparisonResult(NSMetadataItem *left, NSMetadataItem *right) {
        NSString *leftName = [left valueForAttribute:NSMetadataItemFSNameKey];
        NSString *rightName = [right valueForAttribute:NSMetadataItemFSNameKey];
        
        return [leftName localizedCompare:rightName];
    }];
    
    for (NSMetadataItem *item in results) {
        [self insertListInfoWithProvider:item completionHandler:nil];
    }

    [self.listInfos sortUsingComparator:^NSComparisonResult(AAPLListInfo *left, AAPLListInfo *right) {
        return [left.URL.lastPathComponent compare:right.URL.lastPathComponent];
    }];
    
    [self processDocumentListDifferences:previousDocumentList];
}

- (void)startMetadataQuery {
    if (!self.documentMetadataQuery) {
        NSMetadataQuery *metadataQuery = [[NSMetadataQuery alloc] init];
        self.documentMetadataQuery = metadataQuery;
        self.documentMetadataQuery.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope];
        
        self.documentMetadataQuery.predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)" argumentArray:@[NSMetadataItemFSNameKey, AAPLAppConfigurationListerFileExtension]];
        
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

- (void)processDocumentListDifferences:(NSArray *)previousListInfos {
    NSMutableArray *insertionRows = [NSMutableArray array];
    NSMutableArray *deletionRows = [NSMutableArray array];
    
    [self.listInfos enumerateObjectsUsingBlock:^(AAPLListInfo *listInfo, NSUInteger idx, BOOL *stop) {
        NSUInteger oldIndex = [previousListInfos indexOfObject:listInfo];
        if (oldIndex == NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            [insertionRows addObject:indexPath];
        }
        else {
            AAPLListInfo *previousListInfo = previousListInfos[oldIndex];

            listInfo.color = previousListInfo.color;
            listInfo.name = previousListInfo.name;
        }
    }];
    
    [previousListInfos enumerateObjectsUsingBlock:^(AAPLListInfo *previousListInfo, NSUInteger idx, BOOL *stop) {
        NSUInteger oldIndex = [self.listInfos indexOfObject:previousListInfo];
        if (oldIndex == NSNotFound) {
            NSIndexPath *indexPath  = [NSIndexPath indexPathForRow:idx inSection:0];
            [deletionRows addObject:indexPath];
        }
        else {
            AAPLListInfo *listInfo = self.listInfos[oldIndex];
            
            listInfo.name = previousListInfo.name;
            listInfo.color = previousListInfo.color;
        }
    }];
    
    [self.tableView beginUpdates];
    
    [self.tableView deleteRowsAtIndexPaths:deletionRows withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView insertRowsAtIndexPaths:insertionRows withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
}

- (void)insertListInfo:(AAPLListInfo *)listInfo completionHandler:(void (^)(NSUInteger index))completionHandler {
    NSUInteger index = [self.listInfos indexOfObject:listInfo inSortedRange:NSMakeRange(0, self.listInfos.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(AAPLListInfo *left, AAPLListInfo *right) {
        return [left.name localizedCompare:right.name];
    }];

    [self.listInfos insertObject:listInfo atIndex:index];

    if (completionHandler) {
        completionHandler(index);
    }
}

- (void)removeListInfo:(AAPLListInfo *)listInfo completionHandler:(void (^)(NSUInteger index))completionHandler {
    NSUInteger index = [self.listInfos indexOfObject:listInfo];

    if (index != NSNotFound) {
        [self.listInfos removeObjectAtIndex:index];
        if (completionHandler) {
            completionHandler(index);
        }
    }
}

// AAPLListInfoProvider objects are used to allow us to interact naturally with AAPLListInfo objects that may originate from
// local URLs or NSMetadataItems representing document in the cloud.
- (void)insertListInfoWithProvider:(id <AAPLListInfoProvider>)provider completionHandler:(void (^)(NSUInteger index))completionHandler {
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithProvider:provider];

    [self insertListInfo:listInfo completionHandler:completionHandler];
}

- (void)removeListInfoWithProvider:(id <AAPLListInfoProvider>)provider completionHandler:(void (^)(NSUInteger index))completionHandler {
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithProvider:provider];

    [self removeListInfo:listInfo completionHandler:completionHandler];
}

#pragma mark - Notifications

// The color of the list was changed in the AAPLListViewController, so we need to update the color in our list of documents.
- (void)handleListColorDidChangeNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *rawColor = userInfo[AAPLListViewControllerListDidUpdateColorUserInfoKey];
    NSURL *URL = userInfo[AAPLListViewControllerListDidUpdateURLUserInfoKey];
    
    AAPLListColor color = rawColor.integerValue;
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithProvider:URL];
    
    NSInteger index = [self.listInfos indexOfObject:listInfo];
    if (index != NSNotFound) {
        AAPLListInfo *listInfo = self.listInfos[index];
        listInfo.color = color;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        AAPLListCell *cell = (AAPLListCell *)[self.tableView cellForRowAtIndexPath:indexPath];

        cell.listColorView.backgroundColor = AAPLColorFromListColor(color);
    }
}

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    [self.view setNeedsLayout];
}

#pragma mark - User Storage Preference Related Alerts

- (void)notifyUserOfAccountChange {
    NSString *title = NSLocalizedString(@"iCloud Sign Out", nil);
    NSString *message = NSLocalizedString(@"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents.", nil);
    NSString *okActionTitle = NSLocalizedString(@"OK", nil);

    UIAlertController *signedOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    [signedOutController addAction:[UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:signedOutController animated:YES completion:nil];
}

- (void)promptUserForStorageOption {
    NSString *title = NSLocalizedString(@"Choose Storage Option", nil);
    NSString *message = NSLocalizedString(@"Do you want to store documents in iCloud or only on this device?", nil);
    NSString *localOnlyActionTitle = NSLocalizedString(@"Local Only", nil);
    NSString *cloudActionTitle = NSLocalizedString(@"iCloud", nil);

    UIAlertController *storageController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *localOption = [UIAlertAction actionWithTitle:localOnlyActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [AAPLAppConfiguration sharedAppConfiguration].storageOption = AAPLAppStorageLocal;
    }];
    [storageController addAction:localOption];
    
    UIAlertAction *cloudOption = [UIAlertAction actionWithTitle:cloudActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [AAPLAppConfiguration sharedAppConfiguration].storageOption = AAPLAppStorageCloud;
    }];
    [storageController addAction:cloudOption];
    
    [self presentViewController:storageController animated:YES completion:nil];
}

@end
