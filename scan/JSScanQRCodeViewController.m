//
//  QRCodeViewController.m
//  JeeSea
//
//  Created by 高健大人辛苦了 on 15/9/8.
//  Copyright (c) 2015年 范茂羽. All rights reserved.
//

#import "JSScanQRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>

#define Duration 2.0

@interface JSScanQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) UIImageView *overlay;
@property (nonatomic, strong) UIImageView *line;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *layer;
@end

@implementation JSScanQRCodeViewController

{
    float naviBarAndStatusHeight;
}

- (id)init {
    self = [super init];
    if (self) {
        self.overlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"qrcode_scanner_border"]];
        self.overlay.contentMode = UIViewContentModeScaleAspectFill;
        
        self.line = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"qrcode_scanner_line"]];
        
        self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        self.session = [[AVCaptureSession alloc] init];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    naviBarAndStatusHeight = 20;
    if (self.navigationController.navigationBar != nil) {
        naviBarAndStatusHeight = self.navigationController.navigationBar.height + 20;
    }
    
    self.line.width = 0.84 * ScreenWidth;
    self.line.height = self.line.width;
    self.line.bottom = 0.18 * (ScreenHeight - naviBarAndStatusHeight);
    self.line.centerX = ScreenWidth / 2;
    
    [self.view addSubview:self.overlay];
    [self.view addSubview:self.line];
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.title = @"扫一扫";
    // Do any additional setup after loading the view.
    

}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:Duration target:self selector:@selector(moveScanLine) userInfo:nil repeats:true];
    [self moveScanLine];
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied) {
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"提示" message:@"" delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil];
        [av show];
        [self.timer invalidate];
    }else {
        [self setupCamera];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.session stopRunning];
    [self.timer invalidate];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.layer != nil) {
        self.layer.frame = self.view.bounds;//CGRectMake(50,65 + 64,WINSIZE().width - 100,WINSIZE().width - 100)
    }
    
    self.overlay.frame = self.view.bounds;
}

//配置摄像头
- (void)setupCamera {
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    if (error != nil) {
        NSLog(@"error===%@",[error description]);
        return;
    }
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    self.layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:self.layer atIndex:0];
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    float naviBarHeight = 0;
    if (self.navigationController.navigationBar != nil) {
        naviBarHeight = self.navigationController.navigationBar.height;
    }
    CGRect cropRect = CGRectMake(0.08 * ScreenWidth, 0.18 * (ScreenHeight - naviBarAndStatusHeight), 0.84 * ScreenWidth, 0.84 * ScreenWidth);
    output.rectOfInterest = CGRectMake(cropRect.origin.y / self.view.height, cropRect.origin.x / self.view.width, cropRect.size.height / ScreenHeight, cropRect.size.width / ScreenWidth);
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
        output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
    [self.session startRunning];
}

//
- (void)reStarting {
    [self moveScanLine];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:Duration target:self selector:@selector(moveScanLine) userInfo:nil repeats:true];
    [self.session startRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    [self.timer invalidate];
    [self.session stopRunning];
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *meta = (AVMetadataMachineReadableCodeObject *)metadataObjects[0];
        if ([meta.stringValue integerValue] > 0) {
            [self sendSignInRequestWithUserid:meta.stringValue];
        }else {
            [self reStarting];
        }
    }
}

#pragma mark - 扫码得到userid后发送签到请求
- (void)sendSignInRequestWithUserid:(NSString*)userid
{
}

//扫描线动画
- (void)moveScanLine {
    self.line.bottom = 0.18 * (ScreenHeight - naviBarAndStatusHeight);
    self.line.alpha = 0.0;
    [UIView animateWithDuration:Duration - 0.3 animations:^{
        self.line.alpha = 0.55;
        self.line.bottom = 0.675 * (ScreenHeight - naviBarAndStatusHeight);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
