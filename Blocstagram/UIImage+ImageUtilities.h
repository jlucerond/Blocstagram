//
//  UIImage+ImageUtilities.h
//  Blocstagram
//
//  Created by Joe Lucero on 6/3/15.
//  Copyright (c) 2015 Joe Lucero. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageUtilities)

- (UIImage *) imageWithFixedOrientation;
- (UIImage *) imageResizedToMatchAspectRatioOfSize: (CGSize)size;
- (UIImage *) imageCroppedToRect:(CGRect)cropRect;

@end
