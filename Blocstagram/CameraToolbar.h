//
//  CameraToolbar.h
//  Blocstagram
//
//  Created by Joe Lucero on 6/2/15.
//  Copyright (c) 2015 Joe Lucero. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraToolbar;

@protocol CameraToolBarDelegate <NSObject>

- (void) leftButtonPressedOnToolbar: (CameraToolbar *)toolbar;
- (void) rightButtonPressedOnToolbar: (CameraToolbar *)toolbar;
- (void) cameraButtonPressedOnToolbar: (CameraToolbar *)toolbar;

@end

@interface CameraToolbar : UIView

- (instancetype) initWithImageNames: (NSArray *)imageNames;

@property (nonatomic, weak) NSObject <CameraToolBarDelegate> *delegate;

@end
