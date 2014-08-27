/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                 A custom check box for use in the lists, it supports designing live in IB.
            
*/

@import UIKit;

IB_DESIGNABLE
@interface AAPLCheckBox : UIControl

@property (nonatomic, getter=isChecked) IBInspectable BOOL checked;

@property (nonatomic) IBInspectable CGFloat strokeFactor;
@property (nonatomic) IBInspectable CGFloat insetFactor;
@property (nonatomic) IBInspectable CGFloat markInsetFactor;

@end
