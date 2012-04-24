//
//  PSCollectionViewCell.h
//  Lunchbox
//
//  Created by Peter Shih on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PSCollectionViewCell : UIView

@property (nonatomic, retain) id object;

- (void)prepareForReuse;
- (void)fillViewWithObject:(id)object;
+ (CGFloat)heightForViewWithObject:(id)object inColumnWidth:(CGFloat)columnWidth;

@end
