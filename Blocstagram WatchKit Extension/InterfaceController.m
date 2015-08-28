//
//  InterfaceController.m
//  Blocstagram WatchKit Extension
//
//  Created by Joe Lucero on 7/31/15.
//  Copyright (c) 2015 Joe Lucero. All rights reserved.
//

#import "InterfaceController.h"
//#import "DataSource.h"
//#import "Media.h"

@interface InterfaceController()

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)mySwitchDidActivate:(BOOL)value {
    if (value){
//        NSArray *myArrayOfMediaItems = [DataSource sharedInstance].mediaItems;
//        Media *myFirstMediaItem = myArrayOfMediaItems[0];
//        UIImage *myFirstImage = myFirstMediaItem.image;
//        
//        [self.myPicture setImage:myFirstImage];
    }
    
    else{
        NSLog(@"testing");
    }
}

@end



