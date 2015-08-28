//
//  Data Source.m
//  Blocstagram
//
//  Created by Joe Lucero on 5/14/15.
//  Copyright (c) 2015 Joe Lucero. All rights reserved.
//

#import "DataSource.h"
#import "User.h"
#import "Media.h"
#import "Comment.h"
#import "LoginViewController.h"
#import <UICKeyChainStore.h>
#import <AFNetworking.h>

@interface DataSource() {
    NSMutableArray *_mediaItems;
}

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSArray *mediaItems;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isLoadingOlderItems;
@property (nonatomic, assign) BOOL thereAreNoMoreOlderMessages;

@property (nonatomic, strong) AFHTTPRequestOperationManager *instagramOperationManager;

@end

@implementation DataSource

+ (instancetype) sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (NSString *) instagramClientID {
    return @"b6252ae8899f46729a82ecab577ab72e";
}

- (instancetype) init {
    self = [super init];
    
    if (self) {
        [self createOperationManager];
        self.accessToken = [UICKeyChainStore stringForKey:@"access token"];
        
        if (!self.accessToken){
            [self registerForAccessTokenNotification];
        }
        else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *fullPath = [self pathForFilename:NSStringFromSelector(@selector(mediaItems))];
                NSArray *storedMediaItems = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (storedMediaItems.count > 0) {
                        NSMutableArray *mutableMediaItems = [storedMediaItems mutableCopy];
                        
                        [self willChangeValueForKey:@"mediaItems"];
                        self.mediaItems = mutableMediaItems;
                        [self didChangeValueForKey:@"mediaItems"];
                    }
                    
                    else {
                        [self populateDataWithParameters:nil completionHandler:nil];
                    }
                });
            });
        }
    }
    
    return self;
}

- (void) registerForAccessTokenNotification {
    [[NSNotificationCenter defaultCenter] addObserverForName:LoginViewControllerDidGetAccessTokenNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.accessToken = note.object;
        [UICKeyChainStore setString:self.accessToken forKey:@"access token"];
        
        // got a token; populate the initial data
        [self populateDataWithParameters:nil completionHandler:nil];
    }];
}

- (void) deleteMediaItem:(Media *)item {
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    [mutableArrayWithKVO removeObject:item];
}

- (void) requestNewItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler{
    self.thereAreNoMoreOlderMessages = NO;
    
    if (self.isRefreshing == NO){
        self.isRefreshing = YES;
    
        NSString *minID = [[self.mediaItems firstObject] idNumber];
        NSDictionary *parameters;
        
        if (minID) {
            parameters = @{@"min_id": minID};
        }
        
        [self populateDataWithParameters:parameters completionHandler:^(NSError *error) {
            self.isRefreshing = NO;
            
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    }
}

- (void) requestOldItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler{
    if (self.isLoadingOlderItems == NO && self.thereAreNoMoreOlderMessages == NO){
        self.isLoadingOlderItems = YES;
        
//        Media *media = [[Media alloc] init];
//        media.user = [self randomUser];
//        
//        NSInteger myRandomNumber = arc4random_uniform(9)+1;
//        NSLog(@"%ld", myRandomNumber);
//        NSString *myRandomNumberString = [NSString stringWithFormat:@"%ld.jpg", myRandomNumber];
//        media.image = [UIImage imageNamed:myRandomNumberString];
//        media.caption = [self randomSentence];
//        
//        NSUInteger commentCount = arc4random_uniform(10) + 2;
//        NSMutableArray *randomComments = [NSMutableArray array];
//        
//        for (int i  = 0; i <= commentCount; i++) {
//            Comment *randomComment = [self randomComment];
//            
//            if (i == 0){
//                randomComment.topComment = TRUE;
//            }
//            
//            [randomComments addObject:randomComment];
//        }
//        
//        media.comments = randomComments;
//        
//        NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
//        [mutableArrayWithKVO addObject:media];

        NSString *maxID = [[self.mediaItems lastObject] idNumber];
        NSDictionary *parameters;
        
        if (maxID) {
            parameters = @{@"max_id": maxID};
        }
        
        [self populateDataWithParameters:parameters completionHandler:^(NSError *error) {
            self.isLoadingOlderItems = NO;
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    }
}

#pragma mark - get a feed of the user's images

- (void) populateDataWithParameters:(NSDictionary *)parameters completionHandler:(NewItemCompletionBlock)completionHandler {
    if (self.accessToken) {
        // only try to get the data if there's an access token
        
        NSMutableDictionary *mutableParameters = [@{@"access_token": self.accessToken} mutableCopy];
        
        [mutableParameters addEntriesFromDictionary:parameters];
        
        [self.instagramOperationManager GET:@"users/self/feed"
                                 parameters:mutableParameters
                                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                      if ([responseObject isKindOfClass:[NSDictionary class]]) {
                          [self parseDataFromFeedDictionary:responseObject fromRequestWithParameters:parameters];
                      }
                      
                      if (completionHandler) {
                          completionHandler(nil);
                      }
                  }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (completionHandler) {
                              completionHandler(error);
                              }
                          }];
    }
}

- (void) parseDataFromFeedDictionary:(NSDictionary *) feedDictionary fromRequestWithParameters:(NSDictionary *)parameters {
    NSArray *mediaArray = feedDictionary[@"data"];
    NSMutableArray *tmpMediaItems = [NSMutableArray array];
    
    for (NSDictionary *mediaDictionary in mediaArray){
        Media *mediaItem = [[Media alloc] initWithDictionary:mediaDictionary];
        
        if (mediaItem) {
            [tmpMediaItems addObject:mediaItem];
        }
    }
    
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    
    if (parameters[@"min_id"]) {
        // This was a pull-to-refresh request
        
        NSRange rangeOfIndexes = NSMakeRange(0, tmpMediaItems.count);
        NSIndexSet *indexSetOfNewObjects = [NSIndexSet indexSetWithIndexesInRange:rangeOfIndexes];
        
        [mutableArrayWithKVO insertObjects:tmpMediaItems atIndexes:indexSetOfNewObjects];
    }
    
    else if (parameters[@"max_id"]) {
        // This was an infinite scroll request
        
        if (tmpMediaItems.count == 0) {
            // disable infinite scroll, since there are no more older messages
            self.thereAreNoMoreOlderMessages = YES;
        }
        
        else {
            [mutableArrayWithKVO addObjectsFromArray:tmpMediaItems];
        }
    }
        
    else {
        [self willChangeValueForKey:@"mediaItems"];
        self.mediaItems = tmpMediaItems;
        [self didChangeValueForKey:@"mediaItems"];
    }
    
    [self saveImages];
}

- (void) downloadImageForMediaItem:(Media *)mediaItem {
    if (mediaItem.mediaURL && !mediaItem.image) {
        mediaItem.downloadState = MediaDownloadStateDownloadInProgress;
        [self.instagramOperationManager GET:mediaItem.mediaURL.absoluteString
                  parameters:nil
                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                      if ([responseObject isKindOfClass:[UIImage class]]) {
                          mediaItem.image = responseObject;
                          mediaItem.downloadState = MediaDownloadStateHasImage;
                          NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
                          NSUInteger index = [mutableArrayWithKVO indexOfObject:mediaItem];
                          [mutableArrayWithKVO replaceObjectAtIndex:index withObject:mediaItem];
                          [self saveImages];
                      }
                      else {
                          mediaItem.downloadState = MediaDownloadStateNonRecoverableError;
                      }
                  }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          NSLog(@"Error downloading image: %@", error);
                        mediaItem.downloadState = MediaDownloadStateNonRecoverableError;
                        
                        if ([error.domain isEqualToString:NSURLErrorDomain]){
                            // A networking problem
                            if (error.code == NSURLErrorTimedOut ||
                                error.code == NSURLErrorCancelled ||
                                error.code == NSURLErrorCannotConnectToHost ||
                                error.code == NSURLErrorNetworkConnectionLost ||
                                error.code == NSURLErrorNotConnectedToInternet ||
                                error.code == kCFURLErrorInternationalRoamingOff ||
                                error.code == kCFURLErrorCallIsActive ||
                                error.code == kCFURLErrorDataNotAllowed ||
                                error.code == kCFURLErrorRequestBodyStreamExhausted) {
                                
                                // It might work if we try again
                                mediaItem.downloadState = MediaDownloadStateNeedsImage;
                            }
                        }
                    }];
    
    }
}

#pragma mark - NSKeyedArchive

// first off we create a location to save the documents
- (NSString *) pathForFilename:(NSString *) filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:filename];
    return dataPath;
}

// then we save the data
- (void) saveImages {
    
    if (self.mediaItems.count > 0) {
        // Write the changes to disk
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSUInteger numberOfItemsToSave = MIN(self.mediaItems.count, 50);
            NSArray *mediaItemsToSave = [self.mediaItems subarrayWithRange:NSMakeRange(0, numberOfItemsToSave)];
            
            NSString *fullPath = [self pathForFilename:NSStringFromSelector(@selector(mediaItems))];
            NSData *mediaItemData = [NSKeyedArchiver archivedDataWithRootObject:mediaItemsToSave];
            
            NSError *dataError;
            BOOL wroteSuccessfully = [mediaItemData writeToFile:fullPath options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&dataError];
            
            if (!wroteSuccessfully) {
                NSLog(@"Couldn't write file: %@", dataError);
            }
        });
        
    }
}

#pragma mark - Liking Media Items

- (void) toggleLikeOnMediaItem:(Media *)mediaItem withCompletionHandler:(void (^)(void))completionHandler {
    NSString *urlString = [NSString stringWithFormat:@"media/%@/likes", mediaItem.idNumber];
    NSDictionary *parameters = @{@"access_token": self.accessToken};
    
    if (mediaItem.likeState == LikeStateNotLiked) {
        mediaItem.likeState = LikeStateLiking;
        
        [self.instagramOperationManager
                    POST:urlString
                    parameters:parameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        mediaItem.likeState = LikeStateLiked;
            
                            if (completionHandler) {
                                completionHandler();
                            }
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        mediaItem.likeState = LikeStateNotLiked;
                
                        if (completionHandler) {
                            completionHandler();
                        }
                    }];
        
        }
    
    else if (mediaItem.likeState == LikeStateLiked) {
            mediaItem.likeState = LikeStateUnliking;
        
            [self.instagramOperationManager
                DELETE:urlString
                parameters:parameters
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    mediaItem.likeState = LikeStateNotLiked;
                
                    if (completionHandler) {
                        completionHandler();
                    }
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    mediaItem.likeState = LikeStateLiked;
                    
                    if (completionHandler) {
                        completionHandler();
                    }
                }];
    }
}

#pragma mark - creating the Operation Manager

- (void) createOperationManager {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.instagram.com/v1/"];
    self.instagramOperationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    
    AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializer];
    
    AFImageResponseSerializer *imageSerializer = [AFImageResponseSerializer serializer];
    imageSerializer.imageScale = 1.0;
    
    AFCompoundResponseSerializer *serializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[jsonSerializer, imageSerializer]];
    self.instagramOperationManager.responseSerializer = serializer;
}

#pragma mark - Comments

- (void) commentOnMediaItem:(Media *)mediaItem withCommentText:(NSString *)commentText {
    if (!commentText || commentText.length == 0) {
        return;
    }

    NSString *urlString = [NSString stringWithFormat:@"media/%@/comments", mediaItem.idNumber];
    NSDictionary *parameters = @{@"access_token": self.accessToken, @"text": commentText};
   
    [self.instagramOperationManager POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        mediaItem.temporaryComment = nil;

        NSString *refreshMediaUrlString = [NSString stringWithFormat:@"media/%@", mediaItem.idNumber];
        NSDictionary *parameters = @{@"access_token": self.accessToken};
        [self.instagramOperationManager GET:refreshMediaUrlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            Media *newMediaItem = [[Media alloc] initWithDictionary:responseObject];
            NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
            NSUInteger index = [mutableArrayWithKVO indexOfObject:mediaItem];
            [mutableArrayWithKVO replaceObjectAtIndex:index withObject:newMediaItem];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self reloadMediaItem:mediaItem];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        NSLog(@"Response: %@", operation.responseString);
        [self reloadMediaItem:mediaItem];
    }];
}

- (void) reloadMediaItem:(Media *)mediaItem {
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    NSUInteger index = [mutableArrayWithKVO indexOfObject:mediaItem];
    [mutableArrayWithKVO replaceObjectAtIndex:index withObject:mediaItem];
}

//# pragma  mark - creates random data for testing purposes
//- (void) addRandomData {
//    NSMutableArray *randomMediaItems = [NSMutableArray array];
//    
//    for (int i = 1; i <= 10; i++) {
//        NSString *imageName = [NSString stringWithFormat:@"%d.jpg", i];
//        UIImage *image = [UIImage imageNamed:imageName];
//        
//        if (image) {
//            Media *media = [[Media alloc] init];
//            media.user = [self randomUser];
//            media.image = image;
//            media.caption = [self randomSentence];
//            
//            NSUInteger commentCount = arc4random_uniform(10) + 2;
//            NSMutableArray *randomComments = [NSMutableArray array];
//            
//            for (int i  = 0; i <= commentCount; i++) {
//                Comment *randomComment = [self randomComment];
//                
//                if (i == 0){
//                    randomComment.topComment = TRUE;
//                }
//                
//                [randomComments addObject:randomComment];
//            }
//            
//            media.comments = randomComments;
//            
//            [randomMediaItems addObject:media];
//        }
//    }
//    
//    self.mediaItems = randomMediaItems;
//}
//
//- (User *) randomUser {
//    User *user = [[User alloc] init];
//    
//    user.userName = [self randomStringOfLength:arc4random_uniform(10) + 2];
//    
//    NSString *firstName = [self randomStringOfLength:arc4random_uniform(7) + 2];
//    NSString *lastName = [self randomStringOfLength:arc4random_uniform(12) + 2];
//    user.fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
//    
//    return user;
//}
//
//- (Comment *) randomComment {
//    Comment *comment = [[Comment alloc] init];
//    
//    comment.from = [self randomUser];
//    
//    NSUInteger wordCount = arc4random_uniform(20) + 2;
//    
//    NSMutableString *randomSentence = [[NSMutableString alloc] init];
//    
//    for (int i  = 0; i <= wordCount; i++) {
//        NSString *randomWord = [self randomStringOfLength:arc4random_uniform(12) + 2];
//        [randomSentence appendFormat:@"%@ ", randomWord];
//    }
//    
//    comment.text = randomSentence;
//    
//    return comment;
//}
//
//- (NSString *) randomSentence {
//    NSUInteger wordCount = arc4random_uniform(20) + 2;
//    
//    NSMutableString *randomSentence = [[NSMutableString alloc] init];
//
//    for (int i  = 0; i <= wordCount; i++) {
//        NSString *randomWord = [self randomStringOfLength:arc4random_uniform(12) + 2];
//        [randomSentence appendFormat:@"%@ ", randomWord];
//    }
//
//    return randomSentence;
//}
//
//- (NSString *) randomStringOfLength:(NSUInteger) len {
//    NSString *alphabet = @"abcdefghijklmnopqrstuvwxyz";
//    
//    NSMutableString *s = [NSMutableString string];
//    for (NSUInteger i = 0U; i < len; i++) {
//        u_int32_t r = arc4random_uniform((u_int32_t)[alphabet length]);
//        unichar c = [alphabet characterAtIndex:r];
//        [s appendFormat:@"%C", c];
//    }
//    return [NSString stringWithString:s];
//}

@end
