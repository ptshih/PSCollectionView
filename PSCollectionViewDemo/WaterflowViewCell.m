//
//  WaterflowViewCell.m
//  PSCollectionViewDemo
//
//  Created by Venus on 13-4-18.
//  Copyright (c) 2013年 opomelo. All rights reserved.
//

#import "WaterflowViewCell.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>

#define MARGIN 8.0

@implementation WaterflowViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        funnyImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        funnyDescriptions = [[UILabel alloc] initWithFrame:CGRectZero];
        
        funnyDescriptions.font = [UIFont boldSystemFontOfSize:14.0];
        funnyDescriptions.numberOfLines = 0;
        funnyDescriptions.backgroundColor = [UIColor clearColor];
        
        [self addSubview:funnyImage];
        [self addSubview:funnyDescriptions];
        
        self.backgroundColor = [UIColor colorWithRed:236.0f/255.0f green:236.0f/255.0f blue:236.0f/255.0f alpha:1.0];
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.0f;
        self.layer.cornerRadius = 10.0f;
        self.layer.borderColor= [[UIColor colorWithRed:207.0f/255.0f green:207.0f/255.0f blue:207.0f/255.0f alpha:1] CGColor];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)prepareForReuse {
    [super prepareForReuse];
    
    funnyImage.image = nil;
    funnyDescriptions.text = nil;
}

- (void)layoutSubviews {
    // NSLog(@"object is %@", self.object);
    [super layoutSubviews];
    
    CGFloat width = self.frame.size.width - MARGIN * 2;
    CGFloat top = MARGIN;
    CGFloat left = MARGIN;
    
    // Image
    CGFloat objectWidth, objectHeight;
    if ([[self.object objectForKey:@"width"] floatValue] == 0) {
        objectWidth = 200.0f;
    } else {
        objectWidth = [[self.object objectForKey:@"width"] floatValue];
    }
    if ([[self.object objectForKey:@"height"] floatValue] == 0) {
        objectHeight = 200.0f;
    } else {
        objectHeight = [[self.object objectForKey:@"height"] floatValue];
    }
    CGFloat scaledHeight = floorf(objectHeight / (objectWidth / width));
    funnyImage.frame = CGRectMake(left, top, width, scaledHeight);
    
    // Label
    CGSize labelSize = CGSizeZero;
    labelSize = [funnyDescriptions.text sizeWithFont:funnyDescriptions.font constrainedToSize:CGSizeMake(width, INT_MAX) lineBreakMode:funnyDescriptions.lineBreakMode];
    
    funnyDescriptions.frame = CGRectMake(left, funnyImage.frame.origin.y + funnyImage.frame.size.height + MARGIN, labelSize.width, labelSize.height);
}

+ (CGFloat)heightForViewWithObject:(id)object inColumnWidth:(CGFloat)columnWidth {
    CGFloat height = 0.0;
    CGFloat width = columnWidth - MARGIN * 2;
    
    height += MARGIN;
    
    // Image
    CGFloat objectWidth = [[object objectForKey:@"width"] floatValue];
    CGFloat objectHeight = [[object objectForKey:@"height"] floatValue];
    CGFloat scaledHeight = floorf(objectHeight / (objectWidth / width));
    height += scaledHeight;
    
    // Label
    NSString *caption = [object objectForKey:@"title"];
    CGSize labelSize = CGSizeZero;
    UIFont *labelFont = [UIFont boldSystemFontOfSize:14.0];
    labelSize = [caption sizeWithFont:labelFont constrainedToSize:CGSizeMake(width, INT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    height += labelSize.height;
    
    height += MARGIN;
    
    return height;
}

- (void)collectionView:(PSCollectionView *)collectionView fillCellWithObject:(id)object atIndex:(NSInteger)index {
    [super collectionView:collectionView fillCellWithObject:object atIndex:index];
    
    NSURL *showPicURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://imgur.com/%@%@", [[object objectAtIndex:index] objectForKey:@"hash"], [[object objectAtIndex:index] objectForKey:@"ext"]]];
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadWithURL:showPicURL
                     options:0
                    progress:^(NSUInteger receivedSize, long long expectedSize) {
                        // progression tracking code
                        // DLog(@"receivedSize is %u, expectedSize is %lld", receivedSize, expectedSize);
                    }
                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                       if (image && finished) {
                           
                           funnyImage.image = image;
                       }
                       
                       NSLog(@"cache Type is %i", cacheType);
                   }];
    
    funnyDescriptions.text = [[object objectAtIndex:index] objectForKey:@"title"];
}

@end
