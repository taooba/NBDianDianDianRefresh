//
//  ViewController.m
//  NBDianDianDianRefresh
//
//  Created by taooba on 12/22/17.
//  Copyright © 2017 taooba. All rights reserved.
//

#import "ViewController.h"
#import "NBDianDianDianRefresh.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NBDianDianDianRefresh *refreshControl;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  CGRect bounds = self.scrollView.bounds;
  self.scrollView.contentSize = CGSizeMake(bounds.size.width*4, bounds.size.height*2);

  self.refreshControl = [[NBDianDianDianRefresh alloc] initInScrollView:self.scrollView];
  [self.refreshControl addTarget:self response:@selector(requestData)];
  self.refreshControl.pullDistance = self.refreshControl.itemWidth*4;

  
  // 制作一些背景视图
  CGFloat itemCount = 50;
  CGFloat itemSpacing = 4;
  CGFloat itemW = (self.scrollView.contentSize.width-itemSpacing)/itemCount-itemSpacing;
  CGFloat itemH = (self.scrollView.contentSize.height-itemSpacing)/itemCount-itemSpacing;
  for (int w=0; w<itemCount; w++) {
    for (int h=0; h<itemCount; h++) {
      UIView *view = [[UIView alloc] init];
      view.frame = CGRectMake(w*(itemW+itemSpacing)+itemSpacing, h*(itemH+itemSpacing)+itemSpacing, itemW, itemH);
      CGFloat(^randomValue)(void) = ^CGFloat(){ return arc4random_uniform(100)/(CGFloat)100; };
      view.backgroundColor = [UIColor colorWithRed:randomValue() green:randomValue() blue:randomValue() alpha:1];
      [self.scrollView addSubview:view];
    }
  }
}

- (void)requestData {
  // 延时
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.refreshControl endRefreshing];
  });
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


@end
