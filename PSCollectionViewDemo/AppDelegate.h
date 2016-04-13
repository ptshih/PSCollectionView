//
//  AppDelegate.h
//  PSCollectionViewDemo
//
//  Created by Venus on 13-4-18.
//  Copyright (c) 2013年 opomelo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MKNetworkKit.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    MKNetworkEngine *networkEngine;
}

+ (AppDelegate *)instance;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@property (strong, nonatomic) MKNetworkEngine *networkEngine;

@end
