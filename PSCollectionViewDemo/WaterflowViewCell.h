//
//  WaterflowViewCell.h
//  PSCollectionViewDemo
//
//  Created by Venus on 13-4-18.
//  Copyright (c) 2013年 opomelo. All rights reserved.
//

#import "PSCollectionViewCell.h"

@interface WaterflowViewCell : PSCollectionViewCell {
    UIImageView *funnyImage;
    UILabel *funnyDescriptions;
}

+ (CGFloat)heightForViewWithObject:(id)object inColumnWidth:(CGFloat)columnWidth;

@end
