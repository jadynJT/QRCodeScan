# QRCodeScan
***
iOS扫码控件，可以对二维码进行扫描以及从相册选取二维码识别
***

#效果图

![](https://github.com/695331437/QRCodeScan/raw/master/picture/QRCode.gif)


***
#关键代码如下

使用iOS原生控件进行扫码

```
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

```
扫码后执行的回调方法

```
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

```

使用ZXingObjC第三方进行选取二维码识别

```
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

```
