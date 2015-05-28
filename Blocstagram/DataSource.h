//
//  DataSource.h
//  Blocstagram
//
//  Created by Joe Lucero on 5/14/15.
//  Copyright (c) 2015 Joe Lucero. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Media;

typedef void (^NewItemCompletionBlock)(NSError *error);

@interface DataSource : NSObject 

+ (instancetype) sharedInstance;

+ (NSString *) instagramClientID;

@property (nonatomic, strong, readonly) NSString *accessToken;
@property (nonatomic, strong, readonly) NSArray *mediaItems;

- (void) deleteMediaItem: (Media *)item;

- (void) requestNewItemsWithCompletionHandler: (NewItemCompletionBlock) completionHandler;
- (void) requestOldItemsWithCompletionHandler: (NewItemCompletionBlock) completionHandler;

- (void) downloadImageForMediaItem:(Media *) mediaItem;

@end
