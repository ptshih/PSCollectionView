//
//  ViewController.h
//  PSCollectionViewDemo
//
//  Created by Venus on 13-4-18.
//  Copyright (c) 2013年 opomelo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSCollectionView.h"
#import "AppDelegate.h"
#import "JSONKit.h"

@interface ViewController : UIViewController <UIScrollViewDelegate, PSCollectionViewDataSource, PSCollectionViewDelegate> {
    PSCollectionView *waterflowView;
}

@property (nonatomic, retain) PSCollectionView *waterflowView;

@end
