//
//  NBDianDianDianRefresh.h
//  NBDianDianDianRefresh
//
//  Created by taooba on 12/22/17.
//  Copyright © 2017 taooba. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NBDianDianDianRefresh : UIView

@property (nonatomic, assign) NSInteger itemCount;
@property (nonatomic, strong) UIColor *itemColor;
@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGFloat refreshControlWidth;
@property (nonatomic, assign) CGFloat pullDistance;

- (instancetype)initInScrollView:(UIScrollView *)scrollView;
- (void)addTarget:(NSObject*)target response:(SEL)selector;

- (void)endRefreshing;

@end
