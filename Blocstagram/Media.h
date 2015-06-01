//
//  Media.h
//  Blocstagram
//
//  Created by Joe Lucero on 5/14/15.
//  Copyright (c) 2015 Joe Lucero. All rights reserved.
//

#pragma mark - question for mark- why do we replace the foundation instead of also adding UIKit? Is UIKit a subclass of Foundation?

#import <UIKit/UIKit.h>
#import "LikeButton.h"

typedef NS_ENUM(NSInteger, MediaDownloadState) {
    MediaDownloadStateNeedsImage = 0,
    MediaDownloadStateDownloadInProgress = 1,
    MediaDownloadStateNonRecoverableError = 2,
    MediaDownloadStateHasImage = 3
};

@class User;

@interface Media : NSObject <NSCoding>

@property (nonatomic, strong) NSString *idNumber;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSURL *mediaURL;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) MediaDownloadState downloadState;
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSArray *comments;

@property (nonatomic, assign) LikeState likeState;

- (instancetype) initWithDictionary: (NSDictionary *) mediaDictionary;

@end
