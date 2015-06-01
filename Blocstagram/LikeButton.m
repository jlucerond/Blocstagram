//
//  LikeButton.m
//  Blocstagram
//
//  Created by Joe Lucero on 5/29/15.
//  Copyright (c) 2015 Joe Lucero. All rights reserved.
//

#import "LikeButton.h"
#import "CircleSpinnerView.h"

#define kLikedStateImage @"heart-full"
#define kUnlikedStateImage @"heart-empty"

@interface LikeButton ()

@property (nonatomic, strong) CircleSpinnerView *spinnerView;
@property (nonatomic, strong) NSString *numberOfLikes;

@end

@implementation LikeButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype) init {
    self = [super init];
    
    if (self) {
        self.spinnerView = [[CircleSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [self addSubview:self.spinnerView];
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
//        self.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
//        self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
//        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        
        self.likeButtonState = LikeStateNotLiked;
        
        CGFloat spacing = 10; // the amount of spacing to appear between image and title
        self.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, spacing);
        self.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.text = @"2";
    }
    
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    self.spinnerView.frame = self.imageView.frame;
}

- (void) setLikeButtonState:(LikeState)likeState {
    _likeButtonState = likeState;
    
    NSString *imageName;
    
    switch (_likeButtonState) {
        case LikeStateLiked:
        case LikeStateUnliking : imageName = kLikedStateImage;
            break;
        
        case LikeStateNotLiked:
        case LikeStateLiking: imageName = kUnlikedStateImage;
    }
    
    switch (_likeButtonState) {
        case LikeStateLiking:
        case LikeStateUnliking:
            self.spinnerView.hidden = NO;
            self.userInteractionEnabled = NO;
            break;
            
        case LikeStateLiked:
        case LikeStateNotLiked:
            self.spinnerView.hidden = YES;
            self.userInteractionEnabled = YES;
    }
    
    [self setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

@end
