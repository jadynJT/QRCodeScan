//
//  QRCodeScanView.h
//  QRCodeScan
//
//  Created by JS1-ZJT on 16/10/9.
//  Copyright © 2016年 JS1-ZJT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QRCodeScanView : UIView

@property (nonatomic, strong)AVCaptureSession *session;
@property (nonatomic, strong)UIImageView *scanLineView;
@property (nonatomic, strong)CABasicAnimation *ani;

//打开相册
- (void)QRCodeScanOpenAlbum;

@end
