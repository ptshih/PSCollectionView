//
// PSCollectionView.m
//
// Copyright (c) 2012 Peter Shih (http://petershih.com)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PSCollectionView.h"

#define kMargin 8.0

static inline NSString * PSCollectionKeyForIndex(NSInteger index) {
    return [NSString stringWithFormat:@"%d", index];
}

static inline NSInteger PSCollectionIndexForKey(NSString *key) {
    return [key integerValue];
}

#pragma mark - UIView Category

@interface UIView (PSCollectionView)

@property(nonatomic, assign) CGFloat left;
@property(nonatomic, assign) CGFloat top;
@property(nonatomic, assign, readonly) CGFloat right;
@property(nonatomic, assign, readonly) CGFloat bottom;
@property(nonatomic, assign) CGFloat width;
@property(nonatomic, assign) CGFloat height;

@end

@implementation UIView (PSCollectionView)

- (CGFloat)left {
    return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)top {
    return self.frame.origin.y;
}

- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}

- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (CGFloat)width {
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)height {
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

@end

#pragma mark - Gesture Recognizer

// This is just so we know that we sent this tap gesture recognizer in the delegate
@interface PSCollectionViewTapGestureRecognizer : UITapGestureRecognizer
@end

@implementation PSCollectionViewTapGestureRecognizer
@end


@interface PSCollectionView () <UIGestureRecognizerDelegate>

@property (nonatomic, assign, readwrite) CGFloat lastOffset;
@property (nonatomic, assign, readwrite) CGFloat offsetThreshold;
@property (nonatomic, assign, readwrite) CGFloat lastWidth;
@property (nonatomic, assign, readwrite) CGFloat colWidth;
@property (nonatomic, assign, readwrite) NSInteger numCols;
@property (nonatomic, assign) UIInterfaceOrientation orientation;

@property (nonatomic, strong) NSMutableDictionary *reuseableViews;
@property (nonatomic, strong) NSMutableDictionary *visibleViews;
@property (nonatomic, strong) NSMutableArray *viewKeysToRemove;
@property (nonatomic, strong) NSMutableDictionary *indexToRectMap;


/**
 Forces a relayout of the collection grid
 */
- (void)relayoutViews;

/**
 Stores a view for later reuse
 TODO: add an identifier like UITableView
 */
- (void)enqueueReusableView:(PSCollectionViewCell *)view;

/**
 Magic!
 */
- (void)removeAndAddCellsIfNecessary;

@end

@implementation PSCollectionView

#pragma mark - Init/Memory

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.alwaysBounceVertical = YES;
        
        self.lastOffset = 0.0;
        self.offsetThreshold = floorf(self.height / 4.0);
        
        self.colWidth = 0.0;
        self.numCols = 0;
        self.numColsPortrait = 0;
        self.numColsLandscape = 0;
        self.orientation = [UIApplication sharedApplication].statusBarOrientation;
        
        self.reuseableViews = [NSMutableDictionary dictionary];
        self.visibleViews = [NSMutableDictionary dictionary];
        self.viewKeysToRemove = [NSMutableArray array];
        self.indexToRectMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    // clear delegates
    self.delegate = nil;
    self.collectionViewDataSource = nil;
    self.collectionViewDelegate = nil;
}

#pragma mark - DataSource

- (void)reloadData {
    [self relayoutViews];
}

#pragma mark - View

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (self.orientation != orientation) {
        self.orientation = orientation;
        // Recalculates layout
        [self relayoutViews];
    } else if(self.lastWidth != self.width) {
        // Recalculates layout
        [self relayoutViews];
    } else {
        // Recycles cells
        CGFloat diff = fabsf(self.lastOffset - self.contentOffset.y);
        
        if (diff > self.offsetThreshold) {
            self.lastOffset = self.contentOffset.y;
            
            [self removeAndAddCellsIfNecessary];
        }
    }
    
    self.lastWidth = self.width;
}

- (void)relayoutViews {
    self.numCols = UIInterfaceOrientationIsPortrait(self.orientation) ? self.numColsPortrait : self.numColsLandscape;
    
    // Reset all state
    [self.visibleViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        PSCollectionViewCell *view = (PSCollectionViewCell *)obj;
        [self enqueueReusableView:view];
    }];
    [self.visibleViews removeAllObjects];
    [self.viewKeysToRemove removeAllObjects];
    [self.indexToRectMap removeAllObjects];
    
    // This is where we should layout the entire grid first
    NSInteger numViews = [self.collectionViewDataSource numberOfRowsInCollectionView:self];
    
    CGFloat totalHeight = 0.0;
    CGFloat top = kMargin;
    
    // Add headerView if it exists
    if (self.headerView) {
        top = self.headerView.top;
        self.headerView.width = self.width;
        [self addSubview:self.headerView];
        top += self.headerView.height;
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
            CGFloat colHeight = [self.collectionViewDataSource collectionView:self heightForRowAtIndex:i];
            
            CGRect viewRect = CGRectMake(left, top, self.colWidth, colHeight);
            
            // Add to index rect map
            [self.indexToRectMap setObject:NSStringFromCGRect(viewRect) forKey:key];
            
            // Update the last height offset for this column
            CGFloat heightOffset = colHeight > 0 ? top + colHeight + kMargin : top;
            
            [colOffsets replaceObjectAtIndex:col withObject:[NSNumber numberWithFloat:heightOffset]];
        }
        
        for (NSNumber *colHeight in colOffsets) {
            totalHeight = (totalHeight < [colHeight floatValue]) ? [colHeight floatValue] : totalHeight;
        }
    } else {
        totalHeight = self.height;
    }
    
    // Add footerView if exists
    if (self.footerView) {
        self.footerView.top = totalHeight;
        self.footerView.width = self.width;
        [self addSubview:self.footerView];
        totalHeight += self.footerView.height;
    }
    
    self.contentSize = CGSizeMake(self.width, totalHeight);
    
    [self removeAndAddCellsIfNecessary];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPSCollectionViewDidRelayoutNotification object:self];
}

- (void)removeAndAddCellsIfNecessary {
    static NSInteger bufferViewFactor = 8;
    static NSInteger topIndex = 0;
    static NSInteger bottomIndex = 0;
    
    NSInteger numViews = [self.collectionViewDataSource numberOfRowsInCollectionView:self];
    
    if (numViews == 0) return;
    
    //    NSLog(@"diff: %f, lastOffset: %f", diff, self.lastOffset);
    
    // Find out what rows are visible
    CGRect visibleRect = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.width, self.height);
    visibleRect = CGRectInset(visibleRect, 0, -1.0 * self.offsetThreshold);
    
    // Remove all rows that are not inside the visible rect
    [self.visibleViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        PSCollectionViewCell *view = (PSCollectionViewCell *)obj;
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
            PSCollectionViewCell *newCell = [self.collectionViewDataSource collectionView:self cellForRowAtIndex:i];
            newCell.frame = CGRectFromString([self.indexToRectMap objectForKey:key]);
            [self addSubview:newCell];
            
            // Setup gesture recognizer
            if ([newCell.gestureRecognizers count] == 0) {
                PSCollectionViewTapGestureRecognizer *gr = [[PSCollectionViewTapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectView:)];
                gr.delegate = self;
                [newCell addGestureRecognizer:gr];
                newCell.userInteractionEnabled = YES;
            }
            
            [self.visibleViews setObject:newCell forKey:key];
        }
    }
}

#pragma mark - Reusing Views

- (PSCollectionViewCell *)dequeueReusableViewForClass:(Class)viewClass {
    NSString *identifier = NSStringFromClass(viewClass);
    
    PSCollectionViewCell *view = nil;
    if ([self.reuseableViews objectForKey:identifier]) {
        view = [[self.reuseableViews objectForKey:identifier] anyObject];
        
        if (view) {
            // Found a reusable view, remove it from the set
            [[self.reuseableViews objectForKey:identifier] removeObject:view];
        }
    }
    
    return view;
}

- (void)enqueueReusableView:(PSCollectionViewCell *)view {
    if ([view respondsToSelector:@selector(prepareForReuse)]) {
        [view performSelector:@selector(prepareForReuse)];
    }
    view.frame = CGRectZero;
    
    NSString *identifier = NSStringFromClass([view class]);
    if (![self.reuseableViews objectForKey:identifier]) {
        [self.reuseableViews setObject:[NSMutableSet set] forKey:identifier];
    }
    
    [[self.reuseableViews objectForKey:identifier] addObject:view];
    
    [view removeFromSuperview];
}

#pragma mark - Gesture Recognizer

- (void)didSelectView:(UITapGestureRecognizer *)gestureRecognizer {
    NSString *rectString = NSStringFromCGRect(gestureRecognizer.view.frame);
    NSArray *matchingKeys = [self.indexToRectMap allKeysForObject:rectString];
    NSString *key = [matchingKeys lastObject];
    if ([gestureRecognizer.view isMemberOfClass:[[self.visibleViews objectForKey:key] class]]) {
        if (self.collectionViewDelegate && [self.collectionViewDelegate respondsToSelector:@selector(collectionView:didSelectCell:atIndex:)]) {
            NSInteger matchingIndex = PSCollectionIndexForKey([matchingKeys lastObject]);
            [self.collectionViewDelegate collectionView:self didSelectCell:(PSCollectionViewCell *)gestureRecognizer.view atIndex:matchingIndex];
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
