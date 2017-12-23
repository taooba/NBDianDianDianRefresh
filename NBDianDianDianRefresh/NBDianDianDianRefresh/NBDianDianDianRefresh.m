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

@property (nonatomic, assign) NSObject *reponseTarget;
@property (nonatomic, assign) SEL responseSelector;

@property (nonatomic, assign) BOOL isPullSuccess;
@property (nonatomic, assign) UIEdgeInsets originalInset;

@end

@implementation NBDianDianDianRefresh

- (instancetype)initInScrollView:(UIScrollView *)scrollView {
  self = [super init];

  self.scrollView = scrollView;
  [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
  [self.scrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];
  [self.scrollView.panGestureRecognizer addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
  [self.scrollView addSubview:self];

  self.itemCount = 3;
  self.itemColor = [UIColor redColor];
  self.itemWidth = 20;
  self.itemSpacing = 20;
  self.refreshControlWidth = self.itemWidth*2;
  self.pullDistance = self.itemWidth*3;
  return self;
}


- (void)addTarget:(NSObject *)target response:(SEL)selector {
  self.reponseTarget = target;
  self.responseSelector = selector;
}


- (void)endRefreshing {
  [UIView animateWithDuration:0.3 animations:^{
    [self setScrollViewContentInset:self.originalInset];
    [self setupRefreshControlFrame];
  }];
  
  self.isPullSuccess = false;
  self.direction = PullRefreshDirectionNone;
  for (UIView *item in self.itemViews) {
    [item.layer removeAllAnimations];
    item.alpha = 1;
  }
}


- (void)dealloc {
  [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
  [self.scrollView removeObserver:self forKeyPath:@"contentInset"];
  self.scrollView = nil;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  BOOL isContentOffset = [keyPath isEqualToString:@"contentOffset"];
  BOOL isState = [keyPath isEqualToString:@"state"];

  // 触摸开始时，拖拽状态重置为 none
  if (isState && !self.isPullSuccess && [change[NSKeyValueChangeNewKey] intValue] == UIGestureRecognizerStateBegan) {
    self.direction = PullRefreshDirectionNone;
    self.isPullSuccess = false;
  }
  
  // 触摸结束时, 判断拖拽刷新是否成功
  if (isState) {
    UIGestureRecognizerState state = [change[NSKeyValueChangeNewKey] intValue];
    if (state != UIGestureRecognizerStateEnded && state != UIGestureRecognizerStateFailed && state != UIGestureRecognizerStateCancelled) return;
    CGFloat progress = [self fetchRefreshControllPullProgress];
    if (progress == 1) self.isPullSuccess = true;
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
/** 获取 ScrollView 的 contentInset (兼容iOS11) */
- (UIEdgeInsets)fetchScrollViewContentInset {
  if (@available(iOS 11.0, *)) {
    return self.scrollView.adjustedContentInset;
  }
  return self.scrollView.contentInset;
}


/** 设置 ScrollView 的 contentInset (兼容iOS11) */
- (void)setScrollViewContentInset:(UIEdgeInsets)targetInset {
  UIEdgeInsets tInset = targetInset;
  if (@available(iOS 11.0, *)) {
    UIEdgeInsets cInset = self.scrollView.contentInset;
    UIEdgeInsets aInset = self.scrollView.adjustedContentInset;
    tInset = UIEdgeInsetsMake(tInset.top-(aInset.top-cInset.top), tInset.left-(aInset.left-cInset.left),
                           tInset.bottom-(aInset.bottom-cInset.bottom), tInset.right-(aInset.right-cInset.right));
  }
  self.scrollView.contentInset = tInset;
}


/** 获取 ScrollView 拖拽的方向 */
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


/** 获取刷新控件的拖拽进度 */
- (CGFloat)fetchRefreshControllPullProgress {
  CGSize cSize = self.scrollView.contentSize;
  CGRect sBounds = self.scrollView.bounds;
  UIEdgeInsets sInsets = [self fetchScrollViewContentInset];
  
  CGFloat progress = 0;
  if (self.direction == PullRefreshDirectionTop && CGRectGetMinY(sBounds) < -sInsets.top) {
    progress = fabs(CGRectGetMinY(sBounds)+sInsets.top) / self.pullDistance;
  }
  if (self.direction == PullRefreshDirectionBottom && CGRectGetMaxY(sBounds) > (cSize.height+sInsets.bottom)) {
    progress = fabs(CGRectGetMaxY(sBounds)-cSize.height-sInsets.bottom) / self.pullDistance;
  }
  if (self.direction == PullRefreshDirectionLeft && CGRectGetMinX(sBounds) < -sInsets.left) {
    progress = fabs(CGRectGetMinX(sBounds)+sInsets.left) / self.pullDistance;
  }
  if (self.direction == PullRefreshDirectionRight && CGRectGetMaxX(sBounds) > (cSize.width+sInsets.right)) {
    progress = fabs(CGRectGetMaxX(sBounds)-cSize.width-sInsets.right) /  self.pullDistance;
  }
  
  progress = MAX(0, progress);
  progress = MIN(1, progress);
  return progress;
}


/** 根据拖拽方向设置刷新控件的 frame */
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


/** 更新刷新控件的位置 */
- (void)updateRefreshControlPosition {
  if (self.direction == PullRefreshDirectionNone) return;
  CGRect frame = self.frame;
  CGPoint sOffset = self.scrollView.contentOffset;
  if (self.direction == PullRefreshDirectionTop || self.direction == PullRefreshDirectionBottom) {
    frame.origin.x = sOffset.x;
  }
  if (self.direction == PullRefreshDirectionLeft || self.direction == PullRefreshDirectionRight) {
    frame.origin.y = sOffset.y;
  }
  self.frame = frame;
}


/** 更新刷新控件的子视图属性 */
- (void)updateRefreshControlItemsProperty {
  if (self.direction == PullRefreshDirectionNone) return;
  CGFloat pullProgress = [self fetchRefreshControllPullProgress];
  if (pullProgress == 0) return;

  CGFloat itemTotalLength = (self.itemWidth+self.itemSpacing)*self.itemViews.count - self.itemSpacing;
  CGPoint start = CGPointMake((CGRectGetWidth(self.frame)-itemTotalLength)/2, (CGRectGetHeight(self.frame)-itemTotalLength)/2);
  
  for (int i=0; i<self.itemViews.count; i++) {
    UIView *item = self.itemViews[i];
    CGFloat itemProgress = ((pullProgress-0.4) - (0.6/self.itemViews.count)*i)/(0.6/self.itemViews.count);
    itemProgress = MAX(0, itemProgress);
    itemProgress = MIN(1, itemProgress);

    CGPoint fPoint = CGPointZero;
    CGPoint tPoint = CGPointZero;
    if (self.direction == PullRefreshDirectionTop || self.direction == PullRefreshDirectionBottom) {
      tPoint = CGPointMake(i*(self.itemWidth+self.itemSpacing)+start.x, (CGRectGetHeight(self.frame)-self.itemWidth)/2);
      fPoint = CGPointMake(tPoint.x, tPoint.y + CGRectGetHeight(self.frame) * (self.direction == PullRefreshDirectionTop ? -1 : 1));
    }
    if (self.direction == PullRefreshDirectionLeft || self.direction == PullRefreshDirectionRight) {
      tPoint = CGPointMake((CGRectGetWidth(self.frame)-self.itemWidth)/2, i*(self.itemWidth+self.itemSpacing)+start.y);
      fPoint = CGPointMake(tPoint.x + CGRectGetWidth(self.frame) * (self.direction == PullRefreshDirectionLeft ? -1 : 1), tPoint.y);
    }
    
    CGFloat t = itemProgress;
    CGFloat f = 1 - itemProgress;
    CGPoint origin = CGPointMake(f*fPoint.x + t*tPoint.x, f*fPoint.y + t*tPoint.y);
    CGRect frame = CGRectMake(origin.x, origin.y, self.itemWidth, self.itemWidth);
    
    item.alpha = itemProgress == 1 ? 1 : 0.5;
    item.frame = frame;
    item.layer.cornerRadius = frame.size.width/2;
  }
}


/** 执行刷新时的 loading 动画 */
- (void)runItemsAnimation {
  for (int i=0; i<self.itemViews.count; i++) {
    UIView *item = self.itemViews[i];
    [UIView animateWithDuration:0.6 delay:i*0.1 options:UIViewAnimationOptionRepeat animations:^{
      item.alpha = 0.5;
    } completion:nil];
  }
}

#pragma mark - getter && setter
- (NSMutableArray *)itemViews {
  if (_itemViews != NULL) return _itemViews;
  _itemViews = [NSMutableArray array];
  for (int i=0; i<self.itemCount; i++) {
    UIView *item = [[UIView alloc] init];
    [self addSubview:item];
    item.backgroundColor = self.itemColor;
    [_itemViews addObject:item];
  }
  return _itemViews;
}


- (void)setIsPullSuccess:(BOOL)isPullSuccess {
  if (_isPullSuccess == isPullSuccess) return;
  _isPullSuccess = isPullSuccess;
  if (_isPullSuccess == false) return;
  
  UIEdgeInsets inset = [self fetchScrollViewContentInset];
  CGFloat gap = self.refreshControlWidth * (_isPullSuccess ? 1 : -1);
  switch (self.direction) {
    case PullRefreshDirectionTop:    inset.top   += gap; break;
    case PullRefreshDirectionBottom: inset.bottom += gap; break;
    case PullRefreshDirectionLeft:   inset.left  += gap; break;
    case PullRefreshDirectionRight:  inset.right  += gap; break;
    default: break;
  }
  self.originalInset = [self fetchScrollViewContentInset];
  CGPoint offset = self.scrollView.contentOffset;
  [self setScrollViewContentInset:inset];
  self.scrollView.contentOffset = offset;
  
  if ([self.reponseTarget respondsToSelector:self.responseSelector]) {
     #pragma clang diagnostic push
     #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.reponseTarget performSelector:self.responseSelector withObject:nil];
     #pragma clang diagnostic pop
  }
  [self runItemsAnimation];
}

@end

