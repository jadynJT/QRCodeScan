//
//  ViewController.m
//  QRCodeScan
//
//  Created by JS1-ZJT on 16/10/9.
//  Copyright © 2016年 JS1-ZJT. All rights reserved.
//

#import "QRCodeScanViewController.h"
#import "QRCodeScanView.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface QRCodeScanViewController ()

@property (nonatomic,strong)QRCodeScanView *QRCodeSV;

@end

@implementation QRCodeScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //设置导航栏
    [self configureNavigation];
    
    self.QRCodeSV = [[QRCodeScanView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.view addSubview:self.QRCodeSV];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //开始捕获
    [self.QRCodeSV.session startRunning];
    //扫描线动画
    [self.QRCodeSV.scanLineView.layer addAnimation:self.QRCodeSV.ani forKey:nil];

}

#pragma mark - 设置视图
//导航栏
- (void)configureNavigation {
    self.title = @"二维码";
    
    //打开相册按钮
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(openAlbum)];
}

//打开相册
- (void)openAlbum {
    [self.QRCodeSV QRCodeScanOpenAlbum];
}

@end
