//
//  ImageRecordManager.m
//  Face++Demo
//
//  Created by 王茹冰 on 16/2/26.
//  Copyright © 2016年 王茹冰. All rights reserved.
//

#import "WRBImageRecordManager.h"
#import <AVFoundation/AVFoundation.h>

@interface WRBImageRecordManager ()

@property (nonatomic, strong) AVCaptureSession *captureSession;//负责输入和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;//照片输出流
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *capturePreviewLayer;//相机拍摄预览图层
@property (nonatomic, strong) UIImageView *lineView;
@property (nonatomic, strong) UIImageView *rectView;

@end

@implementation WRBImageRecordManager

@synthesize lineView, rectView;

+(instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static WRBImageRecordManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[WRBImageRecordManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self configTheAudioPlayerCloseToUser];
        self.captureSession = [[AVCaptureSession alloc] init];
        if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {//设置分辨率
            self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        }
        self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self getFrontCamera] error:nil];
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
        [self.stillImageOutput setOutputSettings:outputSettings];
        if ([self.captureSession canAddInput:self.captureDeviceInput]) {
            [self.captureSession addInput:self.captureDeviceInput];
        }
        if ([self.captureSession canAddOutput:self.stillImageOutput]) {
            [self.captureSession addOutput:self.stillImageOutput];
        }
    }
    return self;
}

#pragma mark - 获取前置摄像头
- (AVCaptureDevice *)getFrontCamera
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [devices lastObject];
    NSError *err = nil;
    BOOL lockAcquired = [device lockForConfiguration:&err];
    if (lockAcquired) {
//        if ([device hasFlash] && [device isFlashModeSupported:AVCaptureFlashModeOn] ) {
//            [device setFlashMode:AVCaptureFlashModeOn];
//        }
        if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device setFocusPointOfInterest:CGPointMake(100, 100)];
        }
        [device unlockForConfiguration];
    }
    return device;
}

#pragma mark - 设置预览图层,来显示照相机拍摄到的画面
- (void)setCameraInView:(UIView *)view
{
    if (self.capturePreviewLayer == nil) {
        self.capturePreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    }
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    CGRect bounds = [view bounds];
    [self.capturePreviewLayer setFrame:bounds];
    [self.capturePreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [viewLayer insertSublayer:self.capturePreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
}

- (void)removeCameraInView:(UIView *)view
{
    [self.capturePreviewLayer removeFromSuperlayer];
}

- (void)startScanAnimationInView:(UIView *)view
{
    rectView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
    rectView.image = [UIImage imageNamed:@"扫描框"];
    CGPoint center = view.center;
    center.y -= 100;
    rectView.center = center;
    [view addSubview:rectView];
    
    CGRect rect = rectView.bounds;
    CGRect lineFrame = rect;
    lineFrame.size.height = 2;
    lineView = [[UIImageView alloc] initWithFrame:lineFrame];
    lineView.image = [UIImage imageNamed:@"扫描线"];
    [rectView addSubview:lineView];
    lineFrame.origin.y += rect.size.height-2;
    [UIView animateWithDuration:2 delay:0 options:UIViewAnimationOptionRepeat animations:^{
        lineView.frame = lineFrame;
    } completion:nil];
}

#pragma mark - 摄像头
/**
 *  摄像头开启
 */
- (void)startCamera
{
    [self.captureSession startRunning];
}

/**
 *  摄像头关闭
 */
- (void)stopCamera
{
    [self.captureSession stopRunning];
}

#pragma mark - 拍照
- (void)takePhotoCompletion:(void (^)(UIImage *image))completion
{
    AVCaptureConnection *captureConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    //根据连接取得设备输出的数据
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer) {
            NSData *imageData=[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *sourceImage = [UIImage imageWithData:imageData];
            UIImage *imageToDisplay = [self fixOrientation:sourceImage];
//            UIImageWriteToSavedPhotosAlbum(imageToDisplay, nil, nil, nil);
            if (completion) {
                completion(imageToDisplay);
            }
        }
    }];
}

#pragma mark - 静音
- (void)configTheAudioPlayerCloseToUser
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL success;
    NSError* error;
    
    //set the audioSession category.
    //Needs to be Record or PlayAndRecord to use audioRouteOverride
    success = [audioSession setCategory:AVAudioSessionCategoryRecord
                                  error:&error];
    if (!success)  NSLog(@"AVAudioSession error setting category:%@",error);
    
    //set the audioSession override
    success = [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone
                                              error:&error];
    if (!success)  NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    //activate the audio session
    success = [audioSession setActive:YES error:&error];
    if (!success) {
        NSLog(@"AVAudioSession error activating: %@",error);
    }else {
        NSLog(@"audioSession active success");
    }
}

#pragma mark - 旋转照片
- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
