//
//  Comment.h
//  Blocstagram
//
//  Created by Joe Lucero on 5/14/15.
//  Copyright (c) 2015 Joe Lucero. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  User;

@interface Comment : NSObject <NSCoding>

@property (nonatomic, strong) NSString *idNumber;
@property (nonatomic, strong) User *from;
@property (nonatomic, strong) NSString *text;
@property BOOL topComment;

- (instancetype) initWithDictionary: (NSDictionary *) commentDictionary;

@end
