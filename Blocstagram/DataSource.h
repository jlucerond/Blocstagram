//
//  DataSource.h
//  Blocstagram
//
//  Created by Joe Lucero on 5/14/15.
//  Copyright (c) 2015 Joe Lucero. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Media;

@interface DataSource : NSObject 

+(instancetype) sharedInstance;

@property (nonatomic, strong, readonly) NSArray *mediaItems;

- (void) deleteMediaItem: (Media *)item;

@end
