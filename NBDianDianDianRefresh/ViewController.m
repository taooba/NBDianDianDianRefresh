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

@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  CGRect bounds = self.view.bounds;
  
  self.scrollView = [[UIScrollView alloc] initWithFrame:bounds];
  [self.view addSubview:self.scrollView];
  
  self.scrollView.contentSize = CGSizeMake(bounds.size.width*4, bounds.size.height*2);
  
  NBDianDianDianRefresh *refresh = [[NBDianDianDianRefresh alloc] initInScrollView:self.scrollView];

  CGFloat itemCount = 30;
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
  NSLog(@"end");
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


@end
