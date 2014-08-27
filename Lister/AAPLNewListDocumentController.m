/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                   Allows users to create a new list document with a name and preferred color.
              
*/

#import "AAPLNewListDocumentController.h"
#import "AAPLListInfo.h"
@import ListerKit;

@interface AAPLNewListDocumentController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIButton *grayButton;
@property (nonatomic, weak) IBOutlet UIButton *blueButton;
@property (nonatomic, weak) IBOutlet UIButton *greenButton;
@property (nonatomic, weak) IBOutlet UIButton *yellowButton;
@property (nonatomic, weak) IBOutlet UIButton *orangeButton;
@property (nonatomic, weak) IBOutlet UIButton *redButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveButton;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@property (nonatomic, weak) UIButton *selectedButton;

@property AAPLListColor selectedColor;
@property (nonatomic, strong) NSString *selectedTitle;

@end

@implementation AAPLNewListDocumentController

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([[AAPLListCoordinator sharedListCoordinator] isValidDocumentName:textField.text]) {
        self.saveButton.enabled = YES;
        self.selectedTitle = textField.text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - IBActions

- (IBAction)pickColor:(UIButton *)sender {
    // Use the button's tag to determine the color.
    self.selectedColor = (AAPLListColor)sender.tag;

    // Clear out the previously selected button's border.
    self.selectedButton.layer.borderWidth = 0.f;

    sender.layer.borderWidth = 5.f;
    sender.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.selectedButton = sender;
    self.titleLabel.textColor = AAPLColorFromListColor(self.selectedColor);
    self.toolbar.tintColor = AAPLColorFromListColor(self.selectedColor);
}

- (IBAction)saveAction:(id)sender {
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithProvider:self.fileURL];
    listInfo.color = self.selectedColor;
    listInfo.name = self.selectedTitle;
    
    [listInfo createAndSaveWithCompletionHandler:^(BOOL success) {
        if (success) {
            [self.delegate newListViewController:self didCreateDocumentWithListInfo:listInfo];
        }
        else {
            // In your app, you should handle this error gracefully.
            NSLog(@"Unable to create new document at URL: %@", self.fileURL.absoluteString);
            abort();
        }
    }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Convenience

- (NSURL *)fileURL {
    if (self.selectedTitle) {
        return [[AAPLListCoordinator sharedListCoordinator] documentURLForName:self.selectedTitle];
    }
    
    return nil;
}

@end
