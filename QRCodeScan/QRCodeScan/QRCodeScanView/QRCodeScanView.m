//
//  QRCodeScanView.m
//  QRCodeScan
//
//  Created by JS1-ZJT on 16/10/9.
//  Copyright © 2016年 JS1-ZJT. All rights reserved.
//

#import "QRCodeScanView.h"
#import "ZXingObjC.h"
#import "TZImagePickerController.h"

#define MarginLeft 50
#define ButtonWidth 26

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define IMAGE_PICKER_COLUMN_NUMBER  4   //手机相册照片选取控件中的照片显示列数

@interface QRCodeScanView ()<AVCaptureMetadataOutputObjectsDelegate, TZImagePickerControllerDelegate>

@property (nonatomic, strong) UIImageView *scanArea;

@end

@implementation QRCodeScanView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        [self scanFrame];  //扫描框
        [self scanLine];   //扫描线
        [self promptText]; //提示语
        [self mask];       //遮罩
        
        //调整扫描区域 因为背景图的原因，四个角会被完全包在遮罩层下，这里让角突出一点点
        [self bringSubviewToFront:self.scanArea];
        CGRect originFrame = self.scanArea.frame;
        self.scanArea.frame = CGRectMake(originFrame.origin.x - 1.5, originFrame.origin.y - 1.5, originFrame.size.width + 3, originFrame.size.height + 3);
        
        //初始化扫描功能
        [self initScanWithRect:self.scanArea.frame];
    }
    return self;
}

#pragma mark - 设置视图
//扫描框
- (void)scanFrame {
    //设置扫描区域视图
    UIImageView *scanArea = [[UIImageView alloc] init];
    [self addSubview:scanArea];
    self.scanArea = scanArea;
    
    UIImage *frameImg = [UIImage imageNamed:@"qr_code_frame"];
    CGFloat cap = frameImg.size.width * 0.5;
    //设置扫描边框的图片的拉伸
    frameImg = [frameImg resizableImageWithCapInsets:UIEdgeInsetsMake(cap, cap, cap, cap)];
    self.scanArea.image = frameImg;
    
    CGFloat scanWidth = SCREEN_WIDTH - MarginLeft * 2;
    self.scanArea.frame = CGRectMake((SCREEN_WIDTH - scanWidth) * 0.5, (SCREEN_HEIGHT - scanWidth) * 0.5, scanWidth, scanWidth);
}

//扫描线
- (void)scanLine {
    _scanLineView = [[UIImageView alloc] init];
    _scanLineView.frame = CGRectMake(3, 0, self.scanArea.frame.size.width - 3, 10);
    UIImage *scanLine = [UIImage imageNamed:@"qr_code_scan_line"];
    _scanLineView.image = scanLine;
    [self.scanArea addSubview:_scanLineView];
    
    _ani = [CABasicAnimation animation];
    _ani.keyPath = @"transform.translation.y";
    _ani.byValue = @(self.scanArea.frame.size.height - _scanLineView.frame.size.height);
    _ani.duration = 3.0;
    _ani.repeatCount = MAXFLOAT;
//    [_scanLineView.layer addAnimation:_ani forKey:nil];
}

//提示语
- (void)promptText {
    UILabel *promptLabel = [[UILabel alloc] init];
    promptLabel.text = @"将二维码放入框内，即可自动扫描";
    promptLabel.backgroundColor = [UIColor clearColor];
    promptLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    promptLabel.font = [UIFont systemFontOfSize:13.0];
    [promptLabel sizeToFit];
    CGPoint center = self.scanArea.center;
    center.y += CGRectGetHeight(self.scanArea.frame) / 2 + 25;
    promptLabel.center = center;
    [self addSubview:promptLabel];
}

//遮罩
- (void)mask {
    //上遮罩
    [self maskWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, CGRectGetMinY(self.scanArea.frame))];
    //左遮罩
    [self maskWithFrame:CGRectMake(0, CGRectGetMinY(self.scanArea.frame), MarginLeft, CGRectGetHeight(self.scanArea.frame))];
    //下遮罩
    [self maskWithFrame:CGRectMake(0, CGRectGetMaxY(self.scanArea.frame), SCREEN_WIDTH, SCREEN_HEIGHT - CGRectGetMaxY(self.scanArea.frame))];
    //右遮罩
    [self maskWithFrame:CGRectMake(CGRectGetMaxX(self.scanArea.frame), CGRectGetMinY(self.scanArea.frame), MarginLeft, CGRectGetHeight(self.scanArea.frame))];
}

- (void)maskWithFrame:(CGRect)frame {
    //上遮罩
    UIView *mask = [[UIView alloc] init];
    mask.frame = frame;
    mask.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [self addSubview:mask];
}

#pragma mark - 初始化扫描功能
- (void)initScanWithRect:(CGRect)rect {
    //获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //创建输出流(二维码)
    AVCaptureMetadataOutput *metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    //设置代理 在主线程里刷新
    [metaDataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    _session = [[AVCaptureSession alloc] init];
    //高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [_session addInput:input];
    [_session addOutput:metaDataOutput];
    [_session startRunning];
    
    //设置扫码支持的编码格式
    metaDataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    //设置预览层
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.layer.bounds;
    [self.layer insertSublayer:layer atIndex:0];
    
    //设置识别区域
    metaDataOutput.rectOfInterest = CGRectMake(rect.origin.y / SCREEN_HEIGHT, rect.origin.x / SCREEN_WIDTH, rect.size.height / SCREEN_HEIGHT, rect.size.width / SCREEN_WIDTH);
}

//打开相册
- (void)QRCodeScanOpenAlbum {
    TZImagePickerController *imagePickerController = [[TZImagePickerController alloc] initWithMaxImagesCount:1 columnNumber:IMAGE_PICKER_COLUMN_NUMBER delegate:self];
    imagePickerController.isSelectOriginalPhoto = NO;
    imagePickerController.allowTakePicture = NO;
    imagePickerController.allowPickingVideo = NO;
    imagePickerController.allowPickingImage = YES;
    imagePickerController.allowPickingOriginalPhoto = NO;
    imagePickerController.sortAscendingByModificationDate = YES;
    
    [self.viewController presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - AVCaptureMetadataOutputObjects delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count <= 0) {
        return;
    }
    
    NSLog(@"%@", NSStringFromCGRect([_session.outputs[0] rectOfInterest]));
    
    //获得扫描得出的字符串
    AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
    [_session stopRunning];
    
    NSLog(@"QR Code scan result: %@", metadataObject.stringValue);
    
    [self showMessage:metadataObject.stringValue withTitle:@"扫码成功"];
}

#pragma mark - TZImagePickerController Delegate
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    
    //获得所选择的图片
    UIImage *image = photos[0];
    
    __weak typeof(self) wself = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        [wself scanQRwithImage:image];
    }];
}

- (void)scanQRwithImage:(UIImage *)image {
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    
    NSError *error = nil;
    ZXResult *result = [reader decode:bitmap hints:hints error:&error];
    
    if (result) {
        NSLog(@"QR Code scan result: %@", result.text);
        [self showMessage:result.text withTitle:@"扫码成功"];
    }
    else {
        [self showMessage:@"图片内没有二维码" withTitle:@"识别失败"];
    }
}

#pragma mark - 禁止横屏
- (BOOL)shouldAutorotate {
    return NO;
}

- (void)showMessage:(NSString *)message withTitle:(NSString *)title {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}

#pragma mark----//获取当前view的superView对应的控制器
- (UIViewController *)viewController
{
    //获取当前view的superView对应的控制器
    UIResponder *next = [self nextResponder];
    do {
        if ([next isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)next;
        }
        next = [next nextResponder];
    } while (next != nil);
    return nil;
}

@end
