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
#import "PSCollectionViewCell.h"

#define kDefaultMargin 8.0
#define kAnimationDuration 0.3f

static inline NSNumber * PSCollectionKeyForIndex(NSInteger index) {
	return [NSNumber numberWithInteger:index];
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

@property (nonatomic, assign, readwrite) CGFloat colWidth;
@property (nonatomic, assign, readwrite) NSInteger numCols;
@property (nonatomic, assign) UIInterfaceOrientation orientation;

@property (nonatomic, strong) NSMutableSet *reuseableViews;
@property (nonatomic, strong) NSMutableDictionary *visibleViews;
@property (nonatomic, strong) NSMutableArray *viewKeysToRemove;
@property (nonatomic, strong) NSMutableDictionary *indexToRectMap;
@property (nonatomic, strong) NSMutableArray *colOffsets;
@property (nonatomic, strong) NSMutableIndexSet *loadedIndices;

@property (nonatomic, assign, readwrite) CGFloat headerViewHeight;

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

@implementation PSCollectionView {
	BOOL _resetLoadedIndices;
}

// Public Views
@synthesize
headerView = _headerView,
footerView = _footerView,
emptyView = _emptyView,
loadingView = _loadingView;

// Public
@synthesize
margin = _margin,
colWidth = _colWidth,
numCols = _numCols,
numColsLandscape = _numColsLandscape,
numColsPortrait = _numColsPortrait,
animateFirstCellAppearance = _animateFirstCellAppearance,
collectionViewDelegate = _collectionViewDelegate,
collectionViewDataSource = _collectionViewDataSource;

// Private
@synthesize
orientation = _orientation,
reuseableViews = _reuseableViews,
visibleViews = _visibleViews,
viewKeysToRemove = _viewKeysToRemove,
indexToRectMap = _indexToRectMap,
colOffsets = _colOffsets,
loadedIndices = _loadedIndices,
headerViewHeight = _headerViewHeight;

#pragma mark - Init/Memory

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.alwaysBounceVertical = YES;
		
		self.margin = kDefaultMargin;
        
        self.colWidth = 0.0;
        self.numCols = 0;
        self.numColsPortrait = 0;
        self.numColsLandscape = 0;
        self.orientation = [UIApplication sharedApplication].statusBarOrientation;
        
        self.reuseableViews = [NSMutableSet set];
        self.visibleViews = [NSMutableDictionary dictionary];
        self.viewKeysToRemove = [NSMutableArray array];
        self.indexToRectMap = [NSMutableDictionary dictionary];
		self.loadedIndices = [NSMutableIndexSet indexSet];
		self.animateFirstCellAppearance = YES;
		self.headerViewHeight = 0.0f;
    }
    return self;
}

- (void)dealloc {
    // clear delegates
    self.delegate = nil;
    self.collectionViewDataSource = nil;
    self.collectionViewDelegate = nil;
}

#pragma mark - Setters

- (void)setLoadingView:(UIView *)loadingView {
    if (_loadingView && [_loadingView respondsToSelector:@selector(removeFromSuperview)]) {
        [_loadingView removeFromSuperview];
    }
    _loadingView = loadingView;
    
    [self addSubview:_loadingView];
}

#pragma mark - DataSource

- (void)reloadData {
	_resetLoadedIndices = YES;
    [self relayoutViews];
}

#pragma mark - View

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (self.orientation != orientation) {
        self.orientation = orientation;
        [self relayoutViews];
	} else {
		//determine if the header has changed height
		CGSize headerSize = [self.headerView sizeThatFits:CGSizeMake(self.width, CGFLOAT_MAX)];
		if (self.headerViewHeight != headerSize.height) {
			//need to adjust all the cells and column heights to reflect the new header height
			CGFloat delta = headerSize.height - self.headerViewHeight;
			
			self.headerView.height = headerSize.height;
			self.headerViewHeight = headerSize.height;
			
			[self adjustYOffsetsWithDelta:delta];
		} else {
			[self removeAndAddCellsIfNecessary];
		}
	}
}

- (void)adjustYOffsetsWithDelta:(CGFloat)delta
{
	//adjust the column heights
	for (int i = 0; i < self.numCols; i++) {
		CGFloat colHeight = [[_colOffsets objectAtIndex:i] floatValue];
		NSNumber *newOffset = [NSNumber numberWithFloat:colHeight + delta];
		[_colOffsets replaceObjectAtIndex:i withObject:newOffset];
	}
	
	//adjust all the cell positions
	NSArray *visibleViewValues = _visibleViews.allValues;
	for (UIView *visibleView in visibleViewValues) {
		CGRect newFrame = CGRectOffset(visibleView.frame, 0, delta);
		visibleView.frame = newFrame;
	}
}

- (void)buildColumnOffsetsFromTop:(CGFloat) top
{
	self.colOffsets = [NSMutableArray arrayWithCapacity:self.numCols];
	for (int i = 0; i < self.numCols; i++) {
		[_colOffsets addObject:[NSNumber numberWithFloat:top]];
	}
}

- (NSInteger)findShortestColumn
{
	NSInteger col = 0;
	CGFloat minHeight = [[_colOffsets objectAtIndex:col] floatValue];
	for (int i = 1; i < [_colOffsets count]; i++) {
		CGFloat colHeight = [[_colOffsets objectAtIndex:i] floatValue];
		
		if (colHeight < minHeight) {
			col = i;
			minHeight = colHeight;
		}
	}
	return col;
}

- (void)insertViewRectForIndex:(int)index forKey:(id <NSCopying>)key inColumn:(NSInteger)col
{
	CGFloat left = self.margin + (col * self.margin) + (col * self.colWidth);
	CGFloat top = [[_colOffsets objectAtIndex:col] floatValue];
	CGFloat colHeight = [self.collectionViewDataSource heightForViewAtIndex:index];
	if (colHeight == 0) {
		colHeight = self.colWidth;
	}
	
	if (top != top) {
		// NaN
	}
	
	CGRect viewRect = CGRectMake(left, top, self.colWidth, colHeight);
	
	// Add to index rect map
	[self.indexToRectMap setObject:[NSValue valueWithCGRect:viewRect] forKey:key];
	
	// Update the last height offset for this column
	CGFloat test = top + colHeight + self.margin;
	
	if (test != test) {
		// NaN
	}
	[_colOffsets replaceObjectAtIndex:col withObject:[NSNumber numberWithFloat:test]];
}

- (CGFloat)updateFooterViewWithTotalHeight:(CGFloat)totalHeight
{
	// Add footerView if exists
    if (self.footerView) {
        self.footerView.width = self.width;
        self.footerView.top = totalHeight;
        [self addSubview:self.footerView];
		
		CGSize footerSize = [self.footerView sizeThatFits:CGSizeMake(self.width, CGFLOAT_MAX)];
		self.footerView.height = footerSize.height;
        totalHeight += self.footerView.height;
    }
	return totalHeight;
}

- (CGFloat)totalHeightFromColOffsetsWithTotalHeight:(CGFloat)totalHeight
{
	for (NSNumber *colHeight in _colOffsets) {
		totalHeight = (totalHeight < [colHeight floatValue]) ? [colHeight floatValue] : totalHeight;
	}
	return totalHeight;
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
	if (_resetLoadedIndices) {
		self.loadedIndices = [NSMutableIndexSet indexSet];
		_resetLoadedIndices = NO;
	}
	
    if (self.emptyView) {
        [self.emptyView removeFromSuperview];
    }
    [self.loadingView removeFromSuperview];
    
    // This is where we should layout the entire grid first
    NSInteger numViews = [self.collectionViewDataSource numberOfViewsInCollectionView:self];
    
    CGFloat totalHeight = 0.0;
    CGFloat top = self.margin;
    
    // Add headerView if it exists
    if (self.headerView) {
        self.headerView.width = self.width;
		
        top = self.headerView.top;
        [self addSubview:self.headerView];
		
		CGSize headerSize = [self.headerView sizeThatFits:CGSizeMake(self.width, CGFLOAT_MAX)];
		self.headerView.height = headerSize.height;
		self.headerViewHeight = headerSize.height;
        top += self.headerView.height;
    }
    
    if (numViews > 0) {
        // This array determines the last height offset on a column
        [self buildColumnOffsetsFromTop:top];
        
        // Calculate index to rect mapping
        self.colWidth = floorf((self.width - self.margin * (self.numCols + 1)) / self.numCols);
        for (NSInteger i = 0; i < numViews; i++) {
            NSNumber *key = PSCollectionKeyForIndex(i);
            
            // Find the shortest column
            NSInteger col = [self findShortestColumn];
			[self insertViewRectForIndex:i forKey:key inColumn:col];
        }
		
		totalHeight = [self totalHeightFromColOffsetsWithTotalHeight:(CGFloat)totalHeight];
    } else {
        totalHeight = self.height;
        
        // If we have an empty view, show it
        if (self.emptyView) {
            self.emptyView.frame = CGRectMake(self.margin, top, self.width - self.margin * 2, self.height - top - self.margin);
            [self addSubview:self.emptyView];
        }
    }
    
    totalHeight = [self updateFooterViewWithTotalHeight:totalHeight];
    
    self.contentSize = CGSizeMake(self.width, totalHeight);
    
    [self removeAndAddCellsIfNecessary];
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
        NSNumber *key = PSCollectionKeyForIndex(i);
		CGRect rect = [[self.indexToRectMap objectForKey:key] CGRectValue];
        
        // If view is within visible rect and is not already shown
        if (![self.visibleViews objectForKey:key] && CGRectIntersectsRect(visibleRect, rect)) {
            // Only add views if not visible
            PSCollectionViewCell *newView = [self.collectionViewDataSource collectionView:self viewAtIndex:i];
            newView.frame = [[self.indexToRectMap objectForKey:key] CGRectValue];
			if ([self.loadedIndices containsIndex:i]) {
				[self addSubview:newView];
			} else { //animate it in, add it to the set
				[self.loadedIndices addIndex:i];
				[self addSubview:newView];
				if (self.animateFirstCellAppearance) {
					newView.alpha = 0.0f;
					[UIView animateWithDuration:kAnimationDuration animations:^{
						newView.alpha = 1.0f;
					}];
				}
			}
        
            // Setup gesture recognizer
            if ([newView.gestureRecognizers count] == 0) {
                PSCollectionViewTapGestureRecognizer *gr = [[PSCollectionViewTapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectView:)];
                gr.delegate = self;
                [newView addGestureRecognizer:gr];
                newView.userInteractionEnabled = YES;
            }
            
            [self.visibleViews setObject:newView forKey:key];
        }
    }
}

- (void)appendView
{
	NSInteger numViews = [self.collectionViewDataSource numberOfViewsInCollectionView:self];
	if ([self.indexToRectMap count] == 0 || numViews == 1) {
		//just build via a reload
		[self reloadData];
	} else {
		NSNumber *key = PSCollectionKeyForIndex(numViews-1);
		
		// Find the shortest column
		NSInteger col = [self findShortestColumn];
		[self insertViewRectForIndex:numViews-1 forKey:key inColumn:col];
		CGFloat totalHeight = [self totalHeightFromColOffsetsWithTotalHeight:0.0f];
		
		totalHeight = [self updateFooterViewWithTotalHeight:totalHeight];
		
		self.contentSize = CGSizeMake(self.width, totalHeight);
		[self removeAndAddCellsIfNecessary];
	}
}

#pragma mark - Reusing Views

- (PSCollectionViewCell *)dequeueReusableView {
    PSCollectionViewCell *view = [self.reuseableViews anyObject];
    if (view) {
        // Found a reusable view, remove it from the set
        [self.reuseableViews removeObject:view];
    }
    
    return view;
}

- (void)enqueueReusableView:(PSCollectionViewCell *)view {
    if ([view respondsToSelector:@selector(prepareForReuse)]) {
        [view performSelector:@selector(prepareForReuse)];
    }
    view.frame = CGRectZero;
	view.alpha = 1.0f;
    [self.reuseableViews addObject:view];
    [view removeFromSuperview];
}

#pragma mark - Gesture Recognizer

- (void)didSelectView:(UITapGestureRecognizer *)gestureRecognizer {
	NSValue *rectValue = [NSValue valueWithCGRect:gestureRecognizer.view.frame];
    NSArray *matchingKeys = [self.indexToRectMap allKeysForObject:rectValue];
    NSString *key = [matchingKeys lastObject];
    if ([gestureRecognizer.view isMemberOfClass:[[self.visibleViews objectForKey:key] class]]) {
        if (self.collectionViewDelegate && [self.collectionViewDelegate respondsToSelector:@selector(collectionView:didSelectView:atIndex:)]) {
            NSInteger matchingIndex = PSCollectionIndexForKey([matchingKeys lastObject]);
            [self.collectionViewDelegate collectionView:self didSelectView:(PSCollectionViewCell *)gestureRecognizer.view atIndex:matchingIndex];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (![gestureRecognizer isMemberOfClass:[PSCollectionViewTapGestureRecognizer class]]) return YES;
    
    NSValue *rectValue = [NSValue valueWithCGRect:gestureRecognizer.view.frame];
    NSArray *matchingKeys = [self.indexToRectMap allKeysForObject:rectValue];
    NSString *key = [matchingKeys lastObject];
    
    if ([touch.view isMemberOfClass:[[self.visibleViews objectForKey:key] class]]) {
        return YES;
    } else {
        return NO;
    }
}

@end
