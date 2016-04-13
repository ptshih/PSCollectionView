//
//  ViewController.m
//  PSCollectionViewDemo
//
//  Created by Venus on 13-4-18.
//  Copyright (c) 2013年 opomelo. All rights reserved.
//

#import "ViewController.h"
#import "WaterflowViewCell.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *waterflowViewData;

@end

@implementation ViewController

@synthesize waterflowViewData = waterflowViewData;
@synthesize waterflowView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.waterflowView = [[PSCollectionView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.waterflowView.delegate = self; // This is for UIScrollViewDelegate
    self.waterflowView.collectionViewDelegate = self;
    self.waterflowView.collectionViewDataSource = self;
    self.waterflowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if ([[UIDevice currentDevice].model isEqualToString:@"iPhone"]) {
        self.waterflowView.numColsPortrait = 2;
        self.waterflowView.numColsLandscape = 4;
    } else {
        self.waterflowView.numColsPortrait = 2;
        self.waterflowView.numColsLandscape = 4;
    }
    
    [self.view addSubview:waterflowView];
    
    [self loadDataSource];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Request

- (void)loadDataSource {
    // Request
	
	MKNetworkOperation *op = [[AppDelegate instance].networkEngine operationWithPath:@"gallery.json"
                                                                              params:nil
                                                                          httpMethod:@"POST" ssl:NO];
    [op addCompletionHandler:^(MKNetworkOperation *operation) {
        self.waterflowViewData = [[[operation responseData] objectFromJSONData] objectForKey:@"data"];
        NSLog(@"items is %@", self.waterflowViewData);
        [self dataSourceDidLoad];
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
        [self dataSourceDidError];
    }];
    
    [[AppDelegate instance].networkEngine enqueueOperation:op];
}

- (void)dataSourceDidLoad {
    [waterflowView reloadData];
}

- (void)dataSourceDidError {
    [waterflowView reloadData];
}

#pragma mark - PSCollection Delegate and DataSource

- (NSInteger)numberOfRowsInCollectionView:(PSCollectionView *)collectionView {
    return [self.waterflowViewData count];
}

- (PSCollectionViewCell *)collectionView:(PSCollectionView *)collectionView cellForRowAtIndex:(NSInteger)index {
    WaterflowViewCell *v = (WaterflowViewCell *)[waterflowView dequeueReusableViewForClass:nil];
    if (!v) {
        v = [[WaterflowViewCell alloc] initWithFrame:CGRectZero];
    }
    
    [v collectionView:waterflowView fillCellWithObject:self.waterflowViewData atIndex:index];
    
    return v;
}

- (CGFloat)collectionView:(PSCollectionView *)collectionView heightForRowAtIndex:(NSInteger)index {
    NSDictionary *item = [self.waterflowViewData objectAtIndex:index];
    
    return [WaterflowViewCell heightForViewWithObject:item inColumnWidth:waterflowView.colWidth];
}

- (void)collectionView:(PSCollectionView *)collectionView didSelectCell:(PSCollectionViewCell *)cell atIndex:(NSInteger)index {
    
}

@end
