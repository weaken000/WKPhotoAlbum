//
//  WKPhotoAlbumCameraViewController.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/23.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "WKPhotoAlbumConfig.h"
#import "WKPhotoAlbumAuthorizationView.h"
#import "WKPhotoAlbumUtils.h"

@interface WKPhotoAlbumCameraViewController ()<AVCaptureFileOutputRecordingDelegate>
//相机输入
@property (nonatomic, strong) AVCaptureDevice          *videoCaptureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput     *videoCaptureInput;
@property (nonatomic, strong) AVCaptureMetadataOutput  *videoCaptureOutput;
//麦克风输入
@property (nonatomic, strong) AVCaptureDevice          *audioCaptureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput     *audioCaptureInput;
@property (nonatomic, strong) AVCaptureMetadataOutput  *audioCaptureOutput;
//拍摄照片输出
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutPut;
//录制视频输出
@property (nonatomic, strong) AVCaptureMovieFileOutput  *movieOutPut;

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) WKPhotoAlbumAuthorizationView *authView;

@end

@implementation WKPhotoAlbumCameraViewController {
    
    UIView   *_videoPlayContanier;
    UIView   *_actionViewContainer;
    
    UIButton *_popButton;
    UIButton *_selectButton;
    UIButton *_switchCameraButton;
    UIButton *_startCaptureButton;
    
    UIView   *_modeSwitchContainer;
    UIButton *_imageModelButton;
    UIButton *_videoModeButton;
    CGFloat  _transformX;
    
    NSURL   *_recordFilePath;
    BOOL     _isPhotoCapture;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavi];
    [self installCaptureSession];
    [self requestAuthorization];
}

- (void)setupNavi {
    _videoPlayContanier = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_videoPlayContanier];
    
    CGFloat y = [UIApplication sharedApplication].statusBarFrame.size.height;
    _popButton = [[UIButton alloc] init];
    _popButton.frame = CGRectMake(15, y, 44, 44);
    _popButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _popButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    [_popButton setImage:[WKPhotoAlbumUtils imageName:@"wk_record_pop"] forState:UIControlStateNormal];
    [_popButton addTarget:self action:@selector(click_popButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_popButton];
}

- (void)setupCaptureView {
    if (!_actionViewContainer) {
        CGFloat y      = [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat width  = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        CGFloat bottom = 50;
        if (@available(iOS 11.0, *)) {
            bottom += self.view.safeAreaInsets.bottom;
        }
        
        _actionViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.view insertSubview:_actionViewContainer belowSubview:_popButton];
        
        _selectButton = [[UIButton alloc] init];
        _selectButton.frame = CGRectMake(width - 59, y, 44, 44);
        [_selectButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].naviTitleColor forState:UIControlStateNormal];
        [_selectButton setTitle:@"完成" forState:UIControlStateNormal];
        _selectButton.titleLabel.font = [WKPhotoAlbumConfig sharedConfig].naviItemFont;
        [_selectButton addTarget:self action:@selector(click_selectButton) forControlEvents:UIControlEventTouchUpInside];
        [_actionViewContainer addSubview:_selectButton];
        
        _startCaptureButton = [[UIButton alloc] init];
        [_startCaptureButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_startCaptureButton setTitle:@"开始" forState:UIControlStateNormal];
        [_startCaptureButton addTarget:self action:@selector(click_startButton) forControlEvents:UIControlEventTouchUpInside];
        _startCaptureButton.frame = CGRectMake((width - 60) * 0.5, height - bottom - 60, 60, 60);
        [_actionViewContainer addSubview:_startCaptureButton];
        
        _switchCameraButton = [[UIButton alloc] init];
        _switchCameraButton.frame = CGRectMake(CGRectGetMinX(_startCaptureButton.frame) - 84, CGRectGetMinY(_startCaptureButton.frame) + 8, 44, 44);
        [_switchCameraButton setImage:[WKPhotoAlbumUtils imageName:@"wk_record_switch"] forState:UIControlStateNormal];
        [_switchCameraButton addTarget:self action:@selector(click_switchCamera) forControlEvents:UIControlEventTouchUpInside];
        _switchCameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _switchCameraButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [_actionViewContainer addSubview:_switchCameraButton];
        
        _modeSwitchContainer = [[UIView alloc] init];
        [_actionViewContainer addSubview:_modeSwitchContainer];
        
        CGFloat modeW = 0;
        CGFloat modeX = 0;
        CGFloat modeH = 30;
        if ([WKPhotoAlbumConfig sharedConfig].allowTakePicture) {
            _imageModelButton = [[UIButton alloc] init];
            [_imageModelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_imageModelButton setTitle:@"照片拍摄" forState:UIControlStateNormal];
            _imageModelButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
            [_imageModelButton addTarget:self action:@selector(click_switchModelButton:) forControlEvents:UIControlEventTouchUpInside];
            _imageModelButton.frame = CGRectMake((width - 60) * 0.5, height - bottom - 60, 60, 60);
            [_modeSwitchContainer addSubview:_imageModelButton];
            [_imageModelButton sizeToFit];
            _imageModelButton.frame = CGRectMake(modeX, 0, _imageModelButton.frame.size.width, modeH);
            modeX += (_imageModelButton.frame.size.width + 15);
            modeW += _imageModelButton.frame.size.width;
            _isPhotoCapture = YES;
            _imageModelButton.selected = YES;
        }
        
        if ([WKPhotoAlbumConfig sharedConfig].allowTakeVideo) {
            _videoModeButton = [[UIButton alloc] init];
            [_videoModeButton setTitle:@"录制视频" forState:UIControlStateNormal];
            [_videoModeButton addTarget:self action:@selector(click_switchModelButton:) forControlEvents:UIControlEventTouchUpInside];
            _videoModeButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
            _videoModeButton.frame = CGRectMake((width - 60) * 0.5, height - bottom - 60, 60, 60);
            [_modeSwitchContainer addSubview:_videoModeButton];
            [_videoModeButton sizeToFit];
            _videoModeButton.frame = CGRectMake(modeX, 0, _imageModelButton.frame.size.width, modeH);
            modeW += _imageModelButton.frame.size.width;
            if (modeX > 0) {
                modeW += 15;
            }
            if (!_isPhotoCapture) {
                [_videoModeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            } else {
                [_videoModeButton setTitleColor:[UIColor colorWithWhite:0.5 alpha:0.6] forState:UIControlStateNormal];
            }
        }
        _modeSwitchContainer.frame = CGRectMake((width - modeW) * 0.5, height - modeH - 20, modeW, modeH);
        if ([WKPhotoAlbumConfig sharedConfig].allowTakePicture && [WKPhotoAlbumConfig sharedConfig].allowTakeVideo) {
            _transformX = modeW * 0.5 - _imageModelButton.frame.size.width * 0.5;
            _modeSwitchContainer.transform = CGAffineTransformMakeTranslation(_transformX, 0);
        }
        [self modifyOutput];
    }
}

- (void)requestAuthorization {
    __weak typeof(self) weakSelf = self;
    [self.authView requestAuthorizationForType:[WKPhotoAlbumConfig sharedConfig].allowTakeVideo ? WKAuthorizationTypeVideo : WKAuthorizationTypeImage handle:^(PHAuthorizationStatus albumStatus, AVAuthorizationStatus cameraStatus, AVAuthorizationStatus micStatus) {
        if (cameraStatus == AVAuthorizationStatusAuthorized) {
            [weakSelf addCameraCapture];
        }
        if (micStatus == AVAuthorizationStatusAuthorized) {
            [weakSelf modifyAudioCapture];
        }
    }];
}

- (void)installCaptureSession {
    if (!self.session) {
        self.session = [[AVCaptureSession alloc] init];
        if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
        }
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        self.previewLayer.frame = [UIScreen mainScreen].bounds;
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [_videoPlayContanier.layer addSublayer:self.previewLayer];
        [self.session startRunning];
    }
}

- (void)addCameraCapture {
    [self setupCaptureView];
    [self.session beginConfiguration];
    self.videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    self.videoCaptureInput  = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoCaptureDevice error:nil];
    if ([self.session canAddInput:self.videoCaptureInput]) {
        [self.session addInput:self.videoCaptureInput];
    }
    [self.session commitConfiguration];
}
//修改音频输入，拍照时不需要音频输入
- (void)modifyAudioCapture {
    if (_isPhotoCapture) {
        if (self.audioCaptureInput && [self.session.inputs containsObject:self.audioCaptureInput]) {
            [self.session beginConfiguration];
            [self.session removeInput:self.audioCaptureInput];
            [self.session commitConfiguration];
        }
    } else {
        if (!self.audioCaptureInput) {
            self.audioCaptureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio].firstObject;
            self.audioCaptureInput  = [[AVCaptureDeviceInput alloc] initWithDevice:self.audioCaptureDevice error:nil];
        }
        if (![self.session.inputs containsObject:self.audioCaptureInput]) {
            [self.session beginConfiguration];
            if ([self.session canAddInput:self.audioCaptureInput]) {
                [self.session addInput:self.audioCaptureInput];
            }
            [self.session commitConfiguration];
        }
    }
}
//切换输出源
- (void)modifyOutput {
    if (_isPhotoCapture) {
        [self.session beginConfiguration];
        [self.session removeOutput:_movieOutPut];
        if ([self.session canAddOutput:self.imageOutPut]) {
            [self.session addOutput:self.imageOutPut];
        }
        [self.session commitConfiguration];
    } else {
        [self.session beginConfiguration];
        [self.session removeOutput:_imageOutPut];
        if ([self.session canAddOutput:self.movieOutPut]) {
            [self.session addOutput:self.movieOutPut];
        }
        [self.session commitConfiguration];
    }
}

#pragma mark - action
- (void)click_popButton {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)click_startButton {
    if (_isPhotoCapture) {
        AVCaptureConnection * videoConnection = [self.imageOutPut connectionWithMediaType:AVMediaTypeVideo];
        if (videoConnection ==  nil) return;
        [self.imageOutPut captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (imageDataSampleBuffer == nil || error) return;
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            if ([self.delegate respondsToSelector:@selector(captureView:didCreateResult:)]) {
                [self.delegate captureView:self didCreateResult:image];
            }
            [self click_popButton];
        }];
    } else {
        if (self.movieOutPut.isRecording) {
            [self.movieOutPut stopRecording];
            [_startCaptureButton setTitle:@"开始" forState:UIControlStateNormal];
        } else {
            NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.photoAlbum.wk"];
            _recordFilePath = [NSURL fileURLWithPath:path];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
            [self.movieOutPut startRecordingToOutputFileURL:_recordFilePath recordingDelegate:self];
            [_startCaptureButton setTitle:@"停止" forState:UIControlStateNormal];
        }
    }
}
- (void)click_switchCamera {
    AVCaptureDevicePosition position = [self.videoCaptureDevice position];
    [self.session beginConfiguration];
    [self.session removeInput:self.videoCaptureInput];
    if (position == AVCaptureDevicePositionBack) {
        self.videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];
    } else {
        self.videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    }
    self.videoCaptureInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoCaptureDevice error:nil];
    if ([self.session canAddInput:self.videoCaptureInput]) {
        [self.session addInput:self.videoCaptureInput];
    }
    [self.session commitConfiguration];
}
- (void)click_selectButton {
    
}
- (void)click_switchModelButton:(UIButton *)sender {
    if (_transformX == 0) return;
    if ((_isPhotoCapture && sender == _imageModelButton) || (!_isPhotoCapture && sender == _videoModeButton)) return;
    [UIView animateWithDuration:0.6 animations:^{
        if (sender == _imageModelButton) {
            _modeSwitchContainer.transform = CGAffineTransformMakeTranslation(_transformX, 0);
            [_videoModeButton setTitleColor:[UIColor colorWithWhite:0.5 alpha:0.6] forState:UIControlStateNormal];
        } else {
            _modeSwitchContainer.transform = CGAffineTransformMakeTranslation(-_transformX, 0);
            [_imageModelButton setTitleColor:[UIColor colorWithWhite:0.5 alpha:0.6] forState:UIControlStateNormal];
        }
        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
        _isPhotoCapture = !_isPhotoCapture;
        [self modifyAudioCapture];
        [self modifyOutput];
    }];
    
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    
}
- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    if (!error) {
        if ([self.delegate respondsToSelector:@selector(captureView:didCreateResult:)]) {
            [self.delegate captureView:self didCreateResult:outputFileURL];
        }
        [self click_popButton];
    }
}

#pragma mark - config
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

#pragma mark - lazy load
- (WKPhotoAlbumAuthorizationView *)authView {
    if (!_authView) {
        _authView = [[WKPhotoAlbumAuthorizationView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [self.view addSubview:_authView];
        __weak typeof(self) weakSelf = self;
        _authView.authChanged = ^(PHAuthorizationStatus albumStatus, AVAuthorizationStatus cameraStatus, AVAuthorizationStatus micStatus) {
            if (cameraStatus == AVAuthorizationStatusAuthorized) {
                [weakSelf addCameraCapture];
            }
            if (micStatus == AVAuthorizationStatusAuthorized) {
                [weakSelf modifyAudioCapture];
            }
        };
    }
    return _authView;
}

- (AVCaptureMovieFileOutput *)movieOutPut {
    if (!_movieOutPut) {
        _movieOutPut = [[AVCaptureMovieFileOutput alloc] init];
    }
    return _movieOutPut;
}

- (AVCaptureStillImageOutput *)imageOutPut {
    if (!_imageOutPut) {
        _imageOutPut = [[AVCaptureStillImageOutput alloc] init];
    }
    return _imageOutPut;
}

@end
