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
#import "WKPhotoAlbumMediaPlayer.h"

@protocol WKPhotoCameraStartButtonDelegate <NSObject>

- (void)startButtonDidTapped;

- (void)startButtonDidPressStart:(BOOL)start;

@end

@interface WKPhotoCameraStartButton: UIView

@property (nonatomic, weak) id<WKPhotoCameraStartButtonDelegate> delegate;

@property (nonatomic, assign) BOOL isCapturePhoto;

@property (nonatomic, assign) CGFloat progress;

- (void)endRecord;

@end

@implementation WKPhotoCameraStartButton {
    UIVisualEffectView *_bgEffectView;
    UIView             *_circleView;
    CAShapeLayer       *_progressLayer;
    
    UITapGestureRecognizer *_tapper;
    UILongPressGestureRecognizer *_longPresser;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self == [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    
    self.layer.cornerRadius = self.bounds.size.width * 0.5;
    self.layer.masksToBounds = YES;
    
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    _bgEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    _bgEffectView.frame = self.bounds;
    [self addSubview:_bgEffectView];
    
    _circleView = [[UIView alloc] init];
    _circleView.backgroundColor = [UIColor whiteColor];
    _circleView.frame = CGRectMake(0, 0, 55, 55);
    _circleView.layer.cornerRadius = 27.5;
    _circleView.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    [self addSubview:_circleView];
    
    _tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleViewTapped)];
    _tapper.numberOfTapsRequired = 1;
    _tapper.numberOfTouchesRequired = 1;
    [_circleView addGestureRecognizer:_tapper];
    
    _longPresser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(circleViewLongPressed:)];
    _longPresser.minimumPressDuration = 0.3;
    [_circleView addGestureRecognizer:_longPresser];
}

- (void)startProgressLayer {
    CGFloat lineWidth = 3.0;
    CGRect pathRect = CGRectMake(0, 0, self.bounds.size.width - lineWidth, self.bounds.size.height - lineWidth);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathRect cornerRadius:self.frame.size.width * 0.5];
    
    _progressLayer = [[CAShapeLayer alloc] init];
    _progressLayer.bounds = CGRectMake(0, 0, self.bounds.size.width - lineWidth, self.bounds.size.width - lineWidth);
    _progressLayer.position = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    _progressLayer.strokeColor = [WKPhotoAlbumConfig sharedConfig].selectColor.CGColor;
    _progressLayer.fillColor = [UIColor clearColor].CGColor;
    _progressLayer.lineWidth = lineWidth;
    _progressLayer.lineCap = kCALineCapRound;
    _progressLayer.path = path.CGPath;
    _progressLayer.strokeEnd = 0.0;
    [self.layer addSublayer:_progressLayer];
}

- (void)setIsCapturePhoto:(BOOL)isCapturePhoto {
    _isCapturePhoto = isCapturePhoto;
    if (isCapturePhoto) {
        _tapper.enabled = YES;
        _longPresser.enabled = NO;
    } else {
        _tapper.enabled = NO;
        _longPresser.enabled = YES;
    }
}

- (void)setProgress:(CGFloat)progress {
    if (!_isCapturePhoto) {
        _progressLayer.strokeEnd = progress;
    }
}

- (void)endRecord {
    [_progressLayer removeFromSuperlayer];
    [UIView animateWithDuration:0.5 animations:^{
        self.transform = CGAffineTransformIdentity;
        _circleView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {}];
}

#pragma mark - Action
- (void)circleViewTapped {
    if ([self.delegate respondsToSelector:@selector(startButtonDidTapped)]) {
        [self.delegate startButtonDidTapped];
    }
}

- (void)circleViewLongPressed:(UILongPressGestureRecognizer *)longPresser {
    if ([self.delegate respondsToSelector:@selector(startButtonDidPressStart:)]) {
        BOOL start = longPresser.state == UIGestureRecognizerStateBegan;
        if (start) {
            [UIView animateWithDuration:0.5 animations:^{
                self.transform = CGAffineTransformMakeScale(1.5, 1.5);
                _circleView.transform = CGAffineTransformMakeScale(0.6, 0.6);
            } completion:^(BOOL finished) {
                [self startProgressLayer];
                [self.delegate startButtonDidPressStart:YES];
            }];
            return;
        }
        BOOL end = longPresser.state == UIGestureRecognizerStateEnded;
        if (end) {
            [self.delegate startButtonDidPressStart:NO];
        }
    }
}

@end

@interface WKPhotoAlbumCameraViewController ()<AVCaptureFileOutputRecordingDelegate, WKPhotoCameraStartButtonDelegate>
//相机输入
@property (nonatomic, strong) AVCaptureDevice            *videoCaptureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput       *videoCaptureInput;
@property (nonatomic, strong) AVCaptureMetadataOutput    *videoCaptureOutput;
//麦克风输入
@property (nonatomic, strong) AVCaptureDevice            *audioCaptureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput       *audioCaptureInput;
@property (nonatomic, strong) AVCaptureMetadataOutput    *audioCaptureOutput;
//拍摄照片输出
@property (nonatomic, strong) AVCaptureStillImageOutput  *imageOutPut;
//录制视频输出
@property (nonatomic, strong) AVCaptureMovieFileOutput   *movieOutPut;

@property (nonatomic, strong) AVCaptureSession              *session;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *previewLayer;

@property (nonatomic, strong) WKPhotoAlbumAuthorizationView *authView;

@property (nonatomic, strong) WKPhotoAlbumMediaPlayer       *player;

@property (nonatomic, strong) UIImageView                   *preImageView;

@end

@implementation WKPhotoAlbumCameraViewController {
    //父视图
    UIView   *_videoPlayContanier;
    UIView   *_bottomViewContainer;
    UIView   *_naviViewContainer;
    UIView   *_preViewContainer;
    //导航按钮
    UIButton *_popButton;
    UIButton *_selectButton;
    //底部动作按钮
    WKPhotoCameraStartButton *_startCaptureButton;
    UIButton *_switchCameraButton;
    UIView   *_modeSwitchContainer;
    UIButton *_imageModelButton;
    UIButton *_videoModeButton;
    CGFloat  _transformX;
    
    NSURL   *_recordFilePath;
    BOOL     _isPhotoCapture;
    BOOL     _isPreviewMode;
    NSTimer *_recordTimer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavi];
    [self installCaptureSession];
    [self requestAuthorization];
}

- (void)setupNavi {
    self.view.backgroundColor = [UIColor whiteColor];
    
    _videoPlayContanier = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_videoPlayContanier];
    
    CGFloat y = [UIApplication sharedApplication].statusBarFrame.size.height;
    _naviViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, y, [UIScreen mainScreen].bounds.size.width, 44.0)];
    [self.view addSubview:_naviViewContainer];
    
    _popButton = [[UIButton alloc] init];
    _popButton.frame = CGRectMake(15, 0, 44, 44);
    _popButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _popButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    [_popButton setImage:[WKPhotoAlbumUtils imageName:@"wk_record_pop"] forState:UIControlStateNormal];
    [_popButton addTarget:self action:@selector(click_popButton) forControlEvents:UIControlEventTouchUpInside];
    [_popButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].naviTitleColor forState:UIControlStateNormal];
    _popButton.titleLabel.font = [WKPhotoAlbumConfig sharedConfig].naviItemFont;
    [_naviViewContainer addSubview:_popButton];
    
    _selectButton = [[UIButton alloc] init];
    _selectButton.frame = CGRectMake(self.view.frame.size.width - 59, 0, 44, 44);
    [_selectButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].naviTitleColor forState:UIControlStateNormal];
    [_selectButton setTitle:@"选择" forState:UIControlStateNormal];
    _selectButton.titleLabel.font = [WKPhotoAlbumConfig sharedConfig].naviItemFont;
    [_selectButton addTarget:self action:@selector(click_selectButton) forControlEvents:UIControlEventTouchUpInside];
    _selectButton.hidden = YES;
    [_naviViewContainer addSubview:_selectButton];
}

- (void)setupCaptureView {
    if (!_bottomViewContainer) {
        CGFloat y      = CGRectGetMaxY(_naviViewContainer.frame);
        CGFloat width  = self.view.frame.size.width;
        CGFloat height = self.view.frame.size.height - y;
        CGFloat bottom = 50;
        if (@available(iOS 11.0, *)) {
            bottom += self.view.safeAreaInsets.bottom;
        }
        
        _preViewContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.view insertSubview:_preViewContainer belowSubview:_naviViewContainer];
        
        _bottomViewContainer = [[UIView alloc] init];
        _bottomViewContainer.frame = CGRectMake(0, y, width, height);
        [self.view addSubview:_bottomViewContainer];

        _startCaptureButton = [[WKPhotoCameraStartButton alloc] initWithFrame:CGRectMake((width - 80) * 0.5, height - bottom - 80, 80, 80)];
        _startCaptureButton.delegate = self;
        [_bottomViewContainer addSubview:_startCaptureButton];
        
        _switchCameraButton = [[UIButton alloc] init];
        _switchCameraButton.frame = CGRectMake(CGRectGetMinX(_startCaptureButton.frame) - 84, CGRectGetMidY(_startCaptureButton.frame) - 22, 44, 44);
        [_switchCameraButton setImage:[WKPhotoAlbumUtils imageName:@"wk_record_switch"] forState:UIControlStateNormal];
        [_switchCameraButton addTarget:self action:@selector(click_switchCamera) forControlEvents:UIControlEventTouchUpInside];
        _switchCameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _switchCameraButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        [_bottomViewContainer addSubview:_switchCameraButton];
        
        _modeSwitchContainer = [[UIView alloc] init];
        [_bottomViewContainer addSubview:_modeSwitchContainer];
        
        CGFloat modeW = 0;
        CGFloat modeX = 0;
        CGFloat modeH = 30;
        if ([WKPhotoAlbumConfig sharedConfig].allowTakePicture) {
            _imageModelButton = [[UIButton alloc] init];
            [_imageModelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_imageModelButton setTitle:@"照片拍摄" forState:UIControlStateNormal];
            _imageModelButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
            [_imageModelButton addTarget:self action:@selector(click_switchModeButton:) forControlEvents:UIControlEventTouchUpInside];
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
            [_videoModeButton addTarget:self action:@selector(click_switchModeButton:) forControlEvents:UIControlEventTouchUpInside];
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
            [weakSelf addAudioCapture];
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

- (void)addAudioCapture {
    if (!self.audioCaptureInput && !_isPhotoCapture && self.authView.micStatus == AVAuthorizationStatusAuthorized) {
        [self.session beginConfiguration];
        self.audioCaptureDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio].firstObject;
        self.audioCaptureInput  = [[AVCaptureDeviceInput alloc] initWithDevice:self.audioCaptureDevice error:nil];
        if ([self.session canAddInput:self.audioCaptureInput]) {
            [self.session addInput:self.audioCaptureInput];
        }
        [self.session commitConfiguration];
    }
}
//切换输出源
- (void)modifyOutput {
    if (_isPhotoCapture) {
        [self.session stopRunning];
        [self.session removeOutput:_movieOutPut];
        if ([self.session canAddOutput:self.imageOutPut]) {
            [self.session addOutput:self.imageOutPut];
        }
        [self.session startRunning];
    } else {
        [self.session stopRunning];
        [self.session removeOutput:_imageOutPut];
        if ([self.session canAddOutput:self.movieOutPut]) {
            [self.session addOutput:self.movieOutPut];
        }
        [self.session startRunning];
    }
    _startCaptureButton.isCapturePhoto = _isPhotoCapture;
}

#pragma mark - action
- (void)click_popButton {
    if (!_isPreviewMode) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self backToSession];
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
    id result;
    if (_isPhotoCapture) {
        result = _preImageView.image;
    } else {
        result = _recordFilePath;
    }
    if ([self.delegate respondsToSelector:@selector(captureView:didCreateResult:)]) {
        [self.delegate captureView:self didCreateResult:result];
    }
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)click_switchModeButton:(UIButton *)sender {
    if (_transformX == 0) return;
    if ((_isPhotoCapture && sender == _imageModelButton) || (!_isPhotoCapture && sender == _videoModeButton)) return;
    _isPhotoCapture = !_isPhotoCapture;
    [self addAudioCapture];
    [self modifyOutput];
    [UIView animateWithDuration:0.6 animations:^{
        if (sender == _imageModelButton) {
            _modeSwitchContainer.transform = CGAffineTransformMakeTranslation(_transformX, 0);
            [_videoModeButton setTitleColor:[UIColor colorWithWhite:0.5 alpha:0.6] forState:UIControlStateNormal];
        } else {
            _modeSwitchContainer.transform = CGAffineTransformMakeTranslation(-_transformX, 0);
            [_imageModelButton setTitleColor:[UIColor colorWithWhite:0.5 alpha:0.6] forState:UIControlStateNormal];
        }
        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }];
}

#pragma mark - WKPhotoCameraStartButtonDelegate
- (void)startButtonDidPressStart:(BOOL)start {
    if (!_isPhotoCapture) {
        if (!start) {
            [self.movieOutPut stopRecording];
        } else {
            NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"wk_photoAlbum_record.mov"];
            _recordFilePath = [NSURL fileURLWithPath:path];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
            [self.movieOutPut startRecordingToOutputFileURL:_recordFilePath recordingDelegate:self];
            _modeSwitchContainer.hidden = YES;
            _switchCameraButton.hidden = YES;
        }
    }
}
- (void)startButtonDidTapped {
    if (_isPhotoCapture) {
        AVCaptureConnection * videoConnection = [self.imageOutPut connectionWithMediaType:AVMediaTypeVideo];
        if (videoConnection ==  nil) return;
        [self.imageOutPut captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (imageDataSampleBuffer == nil || error) return;
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            [self intoPreviewWithResult:image];
        }];
    }
}

- (void)recordTimePaste {
    CGFloat progress = CMTimeGetSeconds(self.movieOutPut.recordedDuration) / [WKPhotoAlbumConfig sharedConfig].videoMaxRecordTime;
    _startCaptureButton.progress = MIN(1.0, progress);
    if (progress >= 1.0) {
        [_recordTimer invalidate];
        _recordTimer = nil;
        [self.movieOutPut stopRecording];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    _recordTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(recordTimePaste) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_recordTimer forMode:NSRunLoopCommonModes];
}
- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    if (!error) {
        [_recordTimer invalidate];
        _recordTimer = nil;
        [self intoPreviewWithResult:outputFileURL];
        [_startCaptureButton endRecord];
        _modeSwitchContainer.hidden = NO;
        _switchCameraButton.hidden = NO;
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
- (void)intoPreviewWithResult:(id)result {
    [self.session stopRunning];
    _videoPlayContanier.hidden  = YES;
    _bottomViewContainer.hidden = YES;
    _preViewContainer.hidden    = NO;
    _selectButton.hidden        = NO;
    [_popButton setTitle:@"取消" forState:UIControlStateNormal];
    [_popButton setImage:nil forState:UIControlStateNormal];
    if ([result isKindOfClass:[NSURL class]]) {
        [self.player playInContainer:_preViewContainer withPlayerItem:[AVPlayerItem playerItemWithURL:result]];
        _player.hidden = NO;
        _preImageView.hidden = YES;
    } else {
        self.preImageView.image = result;
        self.preImageView.hidden = NO;
        _player.hidden = YES;
    }
    _isPreviewMode = YES;
}

- (void)backToSession {
    [self.session startRunning];
    _videoPlayContanier.hidden  = NO;
    _bottomViewContainer.hidden = NO;
    _preViewContainer.hidden    = YES;
    _selectButton.hidden        = YES;
    [_player stop];
    _preImageView.image = nil;
    [_popButton setTitle:nil forState:UIControlStateNormal];
    [_popButton setImage:[WKPhotoAlbumUtils imageName:@"wk_record_pop"] forState:UIControlStateNormal];
    _isPreviewMode = NO;
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
                [weakSelf addAudioCapture];
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

- (WKPhotoAlbumMediaPlayer *)player {
    if (!_player) {
        _player = [[WKPhotoAlbumMediaPlayer alloc] init];
    }
    return _player;
}

- (UIImageView *)preImageView {
    if (!_preImageView) {
        _preImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        [_preViewContainer addSubview:_preImageView];
    }
    return _preImageView;
}

@end
