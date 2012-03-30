//
//  PSCollectionView.m
//  PSKit
//
//  Created by Peter Shih on 11/24/11.
//  Copyright (c) 2011 Peter Shih. All rights reserved.
//

#import "PSCollectionView.h"
#import "UIView+PSKit.h"

#define kMargin 8.0

static inline NSString * PSCollectionKeyForIndex(NSInteger index) {
    return [NSString stringWithFormat:@"%d", index];
}

static inline NSInteger PSCollectionIndexForKey(NSString *key) {
    return [key integerValue];
}

// This is just so we know that we sent this tap gesture recognizer in the delegate
@interface PSCollectionViewTapGestureRecognizer : UITapGestureRecognizer
@end

@implementation PSCollectionViewTapGestureRecognizer
@end


@interface PSCollectionView ()

@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, assign) NSInteger numCols;
@property (nonatomic, assign) UIInterfaceOrientation orientation;

- (void)relayoutViews;

@end

@implementation PSCollectionView

@synthesize
loadingView = _loadingView,
orientation = _orientation,
headerView = _headerView,
footerView = _footerView,
emptyView = _emptyView,
reuseableViews = _reuseableViews,
visibleViews = _visibleViews,
viewKeysToRemove = _viewKeysToRemove,
indexToRectMap = _indexToRectMap,
numCols = _numCols,
numColsPortrait = _numColsPortrait,
numColsLandscape = _numColsLandscape,
colWidth = _colWidth,
collectionViewDelegate = _collectionViewDelegate,
collectionViewDataSource = _collectionViewDataSource;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.reuseableViews = [NSMutableSet set];
        self.visibleViews = [NSMutableDictionary dictionary];
        self.viewKeysToRemove = [NSMutableArray array];
        self.indexToRectMap = [NSMutableDictionary dictionary];
        self.numCols = 0;
        self.numColsPortrait = 0;
        self.numColsLandscape = 0;
        self.colWidth = 0.0;
        self.alwaysBounceVertical = YES;
        self.orientation = [UIApplication sharedApplication].statusBarOrientation;
        
//        [self addObserver:self forKeyPath:@"contentOffset" options:0 context:nil];
        self.loadingView = [UILabel labelWithText:@"Loading..." style:@"emptyLabel"];
        self.loadingView.frame = self.bounds;
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.loadingView];
    }
    return self;
}

- (void)dealloc {
//    [self removeObserver:self forKeyPath:@"contentOffset"];
    
    // clear delegates
    self.collectionViewDataSource = nil;
    self.collectionViewDelegate = nil;
    
    // release retains
    self.loadingView = nil;
    self.headerView = nil;
    self.footerView = nil;
    self.emptyView = nil;
    self.reuseableViews = nil;
    self.visibleViews = nil;
    self.viewKeysToRemove = nil;
    self.indexToRectMap = nil;
    [super dealloc];
}

#pragma mark - KVO
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if ([object isEqual:self]) {
//        [self removeAndAddCellsIfNecessary];
//    }
//}

#pragma mark - View
- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (self.orientation != orientation) {
        self.orientation = orientation;
        [self relayoutViews];
    } else {
        [self removeAndAddCellsIfNecessary];
    }
}

- (void)removeAndAddCellsIfNecessary {
    static NSInteger bufferViewFactor = 5;
    static NSInteger topIndex = 0;
    static NSInteger bottomIndex = 0;
    
    NSInteger numViews = [self.collectionViewDataSource numberOfViewsInCollectionView:self];
    
    if (numViews == 0) return;
    
    // Find out what rows are visible
    CGRect visibleRect = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.width, self.height);
    
    // Remove all rows that are not inside the visible rect
    [self.visibleViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        UIView *view = (UIView *)obj;
        CGRect viewRect = view.frame;
        if (!CGRectIntersectsRect(visibleRect, viewRect)) {
            [self enqueueReusableView:view];
            [self.viewKeysToRemove addObject:key];
        }
    }];
    
    [self.visibleViews removeObjectsForKeys:self.viewKeysToRemove];
    [self.viewKeysToRemove removeAllObjects];
    
    if ([self.visibleViews count] == 0) {
        topIndex = 0;
        bottomIndex = numViews;
    } else {
        NSArray *sortedKeys = [[self.visibleViews allKeys] sortedArrayUsingComparator:^(id obj1, id obj2) {
            if ([obj1 integerValue] < [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedAscending;
            } else if ([obj1 integerValue] > [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedDescending;
            } else {
                return (NSComparisonResult)NSOrderedSame;
            }
        }];
        topIndex = [[sortedKeys objectAtIndex:0] integerValue];
        bottomIndex = [[sortedKeys lastObject] integerValue];
        
        topIndex = MAX(0, topIndex - (bufferViewFactor * self.numCols));
        bottomIndex = MIN(numViews, bottomIndex + (bufferViewFactor * self.numCols));
    }
//    NSLog(@"topIndex: %d, bottomIndex: %d", topIndex, bottomIndex);
    
    // Add views
    for (NSInteger i = topIndex; i < bottomIndex; i++) {
        NSString *key = PSCollectionKeyForIndex(i);
        CGRect rect = CGRectFromString([self.indexToRectMap objectForKey:key]);
        
        // If view is within visible rect and is not already shown
        if (![self.visibleViews objectForKey:key] && CGRectIntersectsRect(visibleRect, rect)) {
            // Only add views if not visible
            UIView *newView = [self.collectionViewDataSource collectionView:self viewAtIndex:i];
            newView.frame = CGRectFromString([self.indexToRectMap objectForKey:key]);
            [self addSubview:newView];
            
            // Setup gesture recognizer
            if ([newView.gestureRecognizers count] == 0) {
                PSCollectionViewTapGestureRecognizer *gr = [[[PSCollectionViewTapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectView:)] autorelease];
                gr.delegate = self;
                [newView addGestureRecognizer:gr];
                newView.userInteractionEnabled = YES;
            }
            
            [self.visibleViews setObject:newView forKey:key];
        }
    }
}

- (void)relayoutViews {
    self.numCols = UIInterfaceOrientationIsPortrait(self.orientation) ? self.numColsPortrait : self.numColsLandscape;
    
    // Reset all state
    [self.visibleViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        UIView *view = (UIView *)obj;
        [self enqueueReusableView:view];
    }];
    [self.visibleViews removeAllObjects];
    [self.viewKeysToRemove removeAllObjects];
    [self.indexToRectMap removeAllObjects];
    
    if (self.emptyView) {
        [self.emptyView removeFromSuperview];
    }
    [self.loadingView removeFromSuperview];
    
    // This is where we should layout the entire grid first
    NSInteger numViews = [self.collectionViewDataSource numberOfViewsInCollectionView:self];
    
    CGFloat totalHeight = 0.0;
    CGFloat top = kMargin;
    
    // Add headerView if it exists
    if (self.headerView) {
        [self addSubview:self.headerView];
        top = self.headerView.height;
    }
    
    if (numViews > 0) {
        // This array determines the last height offset on a column
        NSMutableArray *colOffsets = [NSMutableArray arrayWithCapacity:self.numCols];
        for (int i = 0; i < self.numCols; i++) {
            [colOffsets addObject:[NSNumber numberWithFloat:top]];
        }
        
        // Calculate index to rect mapping
        self.colWidth = floorf((self.width - kMargin * (self.numCols + 1)) / self.numCols);
        for (NSInteger i = 0; i < numViews; i++) {
            NSString *key = PSCollectionKeyForIndex(i);
            
            // Find the shortest column
            NSInteger col = 0;
            CGFloat minHeight = [[colOffsets objectAtIndex:col] floatValue];
            for (int i = 1; i < [colOffsets count]; i++) {
                CGFloat colHeight = [[colOffsets objectAtIndex:i] floatValue];
                
                if (colHeight < minHeight) {
                    col = i;
                    minHeight = colHeight;
                }
            }
            
            CGFloat left = kMargin + (col * kMargin) + (col * self.colWidth);
            CGFloat top = [[colOffsets objectAtIndex:col] floatValue];
            CGFloat colHeight = [self.collectionViewDataSource heightForViewAtIndex:i];
            if (colHeight == 0) {
                colHeight = self.colWidth;
            }
            
            if (top != top) {
                NSLog(@"nan");
            }
            
            CGRect viewRect = CGRectMake(left, top, self.colWidth, colHeight);
            
            // Add to index rect map
            [self.indexToRectMap setObject:NSStringFromCGRect(viewRect) forKey:key];
            
            // Update the last height offset for this column
            CGFloat test = top + colHeight + kMargin;
            
            if (test != test) {
                NSLog(@"nan");
            }
            [colOffsets replaceObjectAtIndex:col withObject:[NSNumber numberWithFloat:test]];
        }
        
        for (NSNumber *colHeight in colOffsets) {
            totalHeight = (totalHeight < [colHeight floatValue]) ? [colHeight floatValue] : totalHeight;
        }
    } else {
        totalHeight = self.height;
        
        // If we have an empty view, show it
        if (self.emptyView) {
            self.emptyView.frame = CGRectMake(kMargin, top, self.width - kMargin * 2, self.height - kMargin * 2);
            [self addSubview:self.emptyView];
        }
    }
    
    // Add footerView if exists
    if (self.footerView) {
        self.footerView.top = totalHeight;
        [self addSubview:self.footerView];
        totalHeight += self.footerView.height;
    }
    
    self.contentSize = CGSizeMake(self.width, totalHeight);
    //    self.contentOffset = CGPointZero;
    
    [self removeAndAddCellsIfNecessary];
}

#pragma mark - DataSource
- (void)reloadViews {
    [self relayoutViews];
}

#pragma mark - Reusing Views
- (UIView *)dequeueReusableView {
    UIView *view = [self.reuseableViews anyObject];
    if (view) {
        // Found a reusable view, remove it from the set
        [view retain];
        [self.reuseableViews removeObject:view];
        [view autorelease];
    }
    
    return view;
}

- (void)enqueueReusableView:(UIView *)view {
    if ([view respondsToSelector:@selector(prepareForReuse)]) {
        [view performSelector:@selector(prepareForReuse)];
    }
    view.frame = CGRectZero;
    [self.reuseableViews addObject:view];
    [view removeFromSuperview];
}

#pragma mark - Gesture Recognizer
- (void)didSelectView:(UITapGestureRecognizer *)gestureRecognizer {    
    NSString *rectString = NSStringFromCGRect(gestureRecognizer.view.frame);
    NSArray *matchingKeys = [self.indexToRectMap allKeysForObject:rectString];
    NSString *key = [matchingKeys lastObject];
    if ([gestureRecognizer.view isMemberOfClass:[[self.visibleViews objectForKey:key] class]]) {
        if (self.collectionViewDelegate && [self.collectionViewDelegate respondsToSelector:@selector(collectionView:didSelectView:atIndex:)]) {
            NSInteger matchingIndex = PSCollectionIndexForKey([matchingKeys lastObject]);
            [self.collectionViewDelegate collectionView:self didSelectView:gestureRecognizer.view atIndex:matchingIndex];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (![gestureRecognizer isMemberOfClass:[PSCollectionViewTapGestureRecognizer class]]) return YES;
    
    NSString *rectString = NSStringFromCGRect(gestureRecognizer.view.frame);
    NSArray *matchingKeys = [self.indexToRectMap allKeysForObject:rectString];
    NSString *key = [matchingKeys lastObject];
    
    if ([touch.view isMemberOfClass:[[self.visibleViews objectForKey:key] class]]) {
        return YES;
    } else {
        return NO;
    }
}

@end
