//
//  NBDianDianDianRefresh.m
//  NBDianDianDianRefresh
//
//  Created by taooba on 12/22/17.
//  Copyright © 2017 taooba. All rights reserved.
//

#import "NBDianDianDianRefresh.h"


/** 下拉刷新的方向 */
typedef NS_ENUM(NSUInteger, PullRefreshDirection) {
  PullRefreshDirectionNone = 0,
  PullRefreshDirectionLeft,
  PullRefreshDirectionRight,
  PullRefreshDirectionTop,
  PullRefreshDirectionBottom,
};


@interface NBDianDianDianRefresh ()

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *itemViews;

@property (nonatomic, assign) PullRefreshDirection direction;


@property (nonatomic, assign) CGPoint startOffset;
@property (nonatomic, assign) CGFloat refreshControlWidth;
@property (nonatomic, assign) BOOL isPullSuccess;
@end

@implementation NBDianDianDianRefresh

- (instancetype)initInScrollView:(UIScrollView *)scrollView {
  self = [super init];
  self.scrollView = scrollView;
  
  [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
  [self.scrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];
  [self.scrollView.panGestureRecognizer addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
  [self.scrollView addSubview:self];

  self.backgroundColor = [UIColor blueColor];
  
  self.itemViews = [NSMutableArray array];
  for (int i=0; i<3; i++) {
    UIView *item = [[UIView alloc] init];
    [self addSubview:item];
    item.backgroundColor = [UIColor redColor];
    [self.itemViews addObject:item];
  }
  
  self.refreshControlWidth = 60;
  return self;
}


- (void)dealloc {
  [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
  [self.scrollView removeObserver:self forKeyPath:@"contentInset"];
  self.scrollView = nil;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  BOOL isContentOffset = [keyPath isEqualToString:@"contentOffset"];
  BOOL isState = [keyPath isEqualToString:@"state"];

  // 触摸开始时，下拉状态重置为 none
  if (isState && !self.isPullSuccess && [change[NSKeyValueChangeNewKey] integerValue] == UIGestureRecognizerStateBegan) {
    self.direction = PullRefreshDirectionNone;
    self.isPullSuccess = false;
  }
  
  // 获取下拉刷新的方向
  if (isContentOffset && self.direction == PullRefreshDirectionNone && self.scrollView.isDragging) {
    self.direction = [self fetchPullRefreshDirection];
    if (self.direction != PullRefreshDirectionNone) {
      [self setupRefreshControlFrame];
    }
  }
  
  // 更新下拉刷新控件的状态 - 位置 进度
  if (isContentOffset && self.direction != PullRefreshDirectionNone) {
    [self updateRefreshControlPosition];
    if (self.isPullSuccess == false) {
      [self updateRefreshControlItemsProperty];
    }
  }
}


#pragma mark - private methods -
- (UIEdgeInsets)fetchScrollViewContentInset {
  if (@available(iOS 11.0, *)) {
    return self.scrollView.adjustedContentInset;
  }
  return self.scrollView.contentInset;
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
  UIEdgeInsets inset = contentInset;
  if (@available(iOS 11.0, *)) {
    UIEdgeInsets adjustInset = self.scrollView.adjustedContentInset;
    inset = UIEdgeInsetsMake(inset.top-adjustInset.top, inset.left-adjustInset.left, inset.bottom-adjustInset.bottom, inset.right-adjustInset.right);
  }
  self.scrollView.contentInset = inset;
}


- (PullRefreshDirection)fetchPullRefreshDirection {
  CGSize cSize = self.scrollView.contentSize;
  UIEdgeInsets cInsets = [self fetchScrollViewContentInset];
  CGRect sBounds = self.scrollView.bounds;
  if (CGRectGetMinX(sBounds) + cInsets.left  < 0) return PullRefreshDirectionLeft;
  if (CGRectGetMaxX(sBounds) + cInsets.right > cSize.width) return PullRefreshDirectionRight;
  if (CGRectGetMinY(sBounds) + cInsets.top   < 0) return PullRefreshDirectionTop;
  if (CGRectGetMaxY(sBounds) + cInsets.bottom > cSize.height) return PullRefreshDirectionBottom;
  return PullRefreshDirectionNone;
}

- (CGFloat)fetchRefreshControllPullProgress {
  CGSize cSize = self.scrollView.contentSize;
  CGRect sBounds = self.scrollView.bounds;
  UIEdgeInsets sInsets = [self fetchScrollViewContentInset];
  
  CGFloat progress = 0;
  if (self.direction == PullRefreshDirectionTop && CGRectGetMinY(sBounds) < -sInsets.top) {
    progress = fabs(CGRectGetMinY(sBounds)+sInsets.top) / self.refreshControlWidth;
  }
  if (self.direction == PullRefreshDirectionBottom && CGRectGetMaxY(sBounds) > (cSize.height+sInsets.bottom)) {
    progress = fabs(CGRectGetMaxY(sBounds)-cSize.height-sInsets.bottom) / self.refreshControlWidth;
  }
  if (self.direction == PullRefreshDirectionLeft && CGRectGetMinX(sBounds) < -sInsets.left) {
    progress = fabs(CGRectGetMinX(sBounds)+sInsets.left) / self.refreshControlWidth;
  }
  if (self.direction == PullRefreshDirectionRight && CGRectGetMaxX(sBounds) > (cSize.width+sInsets.right)) {
    progress = fabs(CGRectGetMaxX(sBounds)-cSize.width-sInsets.right) /  self.refreshControlWidth;
  }
  return progress;
}


- (void)setupRefreshControlFrame {
  CGSize sSize = self.scrollView.frame.size;
  CGSize cSize = self.scrollView.contentSize;
  CGPoint sOffset = self.scrollView.contentOffset;
  UIEdgeInsets sInset = [self fetchScrollViewContentInset];
  
  CGRect frame = CGRectZero;
  if (self.direction == PullRefreshDirectionTop || self.direction == PullRefreshDirectionBottom) {
    frame.size = CGSizeMake(sSize.width, self.refreshControlWidth);
  }
  if (self.direction == PullRefreshDirectionLeft || self.direction == PullRefreshDirectionRight) {
    frame.size = CGSizeMake(self.refreshControlWidth, sSize.height);
  }
  switch (self.direction) {
    case PullRefreshDirectionTop:   frame.origin = CGPointMake(sOffset.x, -self.refreshControlWidth - sInset.top); break;
    case PullRefreshDirectionBottom: frame.origin = CGPointMake(sOffset.x, cSize.height + sInset.bottom); break;
    case PullRefreshDirectionLeft:  frame.origin = CGPointMake(-self.refreshControlWidth - sInset.left, sOffset.y); break;
    case PullRefreshDirectionRight: frame.origin = CGPointMake(cSize.width + sInset.right, sOffset.y); break;
    default: break;
  }
  self.frame = frame;
}

- (void)updateRefreshControlPosition {
  if (self.direction == PullRefreshDirectionNone) return;
  CGRect frame = self.frame;
  CGPoint sOffset = self.scrollView.contentOffset;
  if (self.direction == PullRefreshDirectionTop || self.direction == PullRefreshDirectionBottom) {
    frame.origin.x = sOffset.x;
  }
  if (self.direction == PullRefreshDirectionLeft || self.direction == PullRefreshDirectionLeft) {
    frame.origin.y = sOffset.y;
  }
  self.frame = frame;
}

- (void)updateRefreshControlItemsProperty {
  if (self.direction == PullRefreshDirectionNone) return;
  CGFloat pullProgress = [self fetchRefreshControllPullProgress];
  if (pullProgress == 0) return;
  if (pullProgress >= 1) self.isPullSuccess = true;

  NSInteger itemTotal = 3;
  CGFloat itemWidth = 20;
  CGFloat itemSpacing = 20;
  CGFloat itemTotalLength = (itemWidth+itemSpacing)*itemTotal - itemSpacing;
  CGPoint start = CGPointMake((CGRectGetWidth(self.frame)-itemTotalLength)/2, (CGRectGetHeight(self.frame)-itemTotalLength)/2);
  
  for (int i=0; i<itemTotal; i++) {
    CGFloat itemProgress = (pullProgress - (1.0/itemTotal)*i)/(1.0/itemTotal);
    itemProgress = MAX(0, itemProgress);
    itemProgress = MIN(1, itemProgress);

    CGPoint fPoint = CGPointZero;
    CGPoint tPoint = CGPointZero;
    if (self.direction == PullRefreshDirectionTop || self.direction == PullRefreshDirectionBottom) {
      tPoint = CGPointMake(i*(itemWidth+itemSpacing)+start.x, (CGRectGetHeight(self.frame)-itemWidth)/2);
      fPoint = CGPointMake(tPoint.x, tPoint.y + CGRectGetHeight(self.frame) * (self.direction == PullRefreshDirectionTop ? -1 : 1));
    }
    if (self.direction == PullRefreshDirectionLeft || self.direction == PullRefreshDirectionRight) {
      tPoint = CGPointMake((CGRectGetWidth(self.frame)-itemWidth)/2, i*(itemWidth+itemSpacing)+start.y);
      fPoint = CGPointMake(tPoint.x + CGRectGetWidth(self.frame) * (self.direction == PullRefreshDirectionLeft ? -1 : 1), tPoint.y);
    }
    
    CGFloat t = itemProgress;
    CGFloat f = 1 - itemProgress;
    CGPoint origin = CGPointMake(f*fPoint.x + t*tPoint.x, f*fPoint.y + t*tPoint.y);
    CGRect frame = CGRectMake(origin.x, origin.y, itemWidth, itemWidth);
    [self.itemViews[i] setFrame:frame];
  }
}


- (void)runItemsAnimation {
  for (int i=0; i<self.itemViews.count; i++) {
    UIView *item = self.itemViews[i];
    [UIView animateWithDuration:0.6 delay:i*0.1 options:UIViewAnimationOptionRepeat animations:^{
      item.alpha = 0.5;
    } completion:nil];
  }
}

#pragma mark - getter && setter
- (void)setIsPullSuccess:(BOOL)isPullSuccess {
  if (isPullSuccess == _isPullSuccess) return;
  _isPullSuccess = isPullSuccess;
  UIEdgeInsets inset = [self fetchScrollViewContentInset];
  CGFloat gap = self.refreshControlWidth * (_isPullSuccess ? 1 : -1);
  switch (self.direction) {
    case PullRefreshDirectionTop:    inset.top   += gap; break;
    case PullRefreshDirectionBottom: inset.bottom += gap; break;
    case PullRefreshDirectionLeft:   inset.left  += gap; break;
    case PullRefreshDirectionRight:  inset.right  += gap; break;
    default: break;
  }
  [self setScrollViewContentInset:inset];
  if (_isPullSuccess) [self runItemsAnimation];
}
@end








