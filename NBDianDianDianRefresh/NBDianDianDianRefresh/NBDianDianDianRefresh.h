//
//  NBDianDianDianRefresh.h
//  NBDianDianDianRefresh
//
//  Created by taooba on 12/22/17.
//  Copyright © 2017 taooba. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NBDianDianDianRefresh : UIView

/** 刷新控件内圆点的个数 默认:3 */
@property (nonatomic, assign) NSInteger itemCount;
/** 刷新控件内的圆点颜色 默认:red */
@property (nonatomic, strong) UIColor *itemColor;
/** 刷新控件内的圆点宽度 默认:15 */
@property (nonatomic, assign) CGFloat itemWidth;
/** 刷新控件内的圆点之间间距 默认:12 */
@property (nonatomic, assign) CGFloat itemSpacing;
/** 刷新控件的宽度 (垂直方向为高度) 默认:itemWidth*2.5 */
@property (nonatomic, assign) CGFloat refreshControlWidth;
/** 刷新成功需要拖拽的距离 默认:itemWidth*3 */
@property (nonatomic, assign) CGFloat pullDistance;

/** 各个方向的刷新控件的位置修正，让使用者能在需要的时候在外部修改刷新控件的位置，默认都为 0 */
@property (nonatomic, assign) CGRect amendmentFrameTop;
@property (nonatomic, assign) CGRect amendmentFrameBottom;
@property (nonatomic, assign) CGRect amendmentFrameLeft;
@property (nonatomic, assign) CGRect amendmentFrameRight;

/** 各个方向的刷新控件的 contentInset 修正，让使用者能在需要的时候在外部修改 contentInset ，默认都为 0 */
@property (nonatomic, assign) UIEdgeInsets amendmentInsetTop;
@property (nonatomic, assign) UIEdgeInsets amendmentInsetBottom;
@property (nonatomic, assign) UIEdgeInsets amendmentInsetLeft;
@property (nonatomic, assign) UIEdgeInsets amendmentInsetRight;


- (instancetype)initInScrollView:(UIScrollView *)scrollView;

- (void)addTarget:(NSObject*)target response:(SEL)selector;

- (void)endRefreshing;

@end
