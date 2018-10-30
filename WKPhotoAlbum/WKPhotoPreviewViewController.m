//
//  WKPhotoPreviewViewController.m
//  WKProject
//
//  Created by mac on 2018/10/11.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoPreviewViewController.h"
#import "WKPhotoPreviewTransition.h"
#import "WKPhotoAlbumConfig.h"
#import "WKPhotoAlbumUtils.h"

@interface WKPhotoPreviewViewController ()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView  *scrollView;

@property (nonatomic, strong) UIImageView   *clipMaskImageView;

@property (nonatomic, strong) UIView        *clipConfirmView;

//video
@property (nonatomic, strong) UIButton      *videoControl;

@property (nonatomic, strong) AVPlayer      *videoPlayer;

@property (nonatomic, strong) AVPlayerLayer *videoPlayerLayer;

@property (nonatomic, assign) BOOL          isPlaying;

@end

@implementation WKPhotoPreviewViewController {
    BOOL    _firstLayout;
    CGPoint _clipStartPoint;
    
    UIButton *_editAndClipBtn;
    UIButton *_cancelClipBtn;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.view.backgroundColor = [UIColor whiteColor];

    [self layoutNavigation];
    [self setupSubviews];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    if (_firstLayout) {
        _screenShotImageView.frame = self.view.bounds;
        _clipConfirmView.frame = CGRectMake(0,
                                            self.view.frame.size.height - 50,
                                            CGRectGetWidth(self.view.frame),
                                            50);
        _scrollView.frame = CGRectMake(0, 0,
                                       CGRectGetWidth(self.view.frame),
                                       self.view.frame.size.height - _clipConfirmView.frame.size.height);
        
        [self aspectFitImageViewForImage:self.coverImage];
        _videoPlayerLayer.frame = _previewImageView.bounds;
        _videoControl.frame = CGRectMake((_previewImageView.bounds.size.width - 50) * 0.5,
                                         (_previewImageView.bounds.size.height - 50) * 0.5, 50, 50);
        
        _firstLayout = NO;
    }
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self removeNotification];
}

- (void)layoutNavigation {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    
    self.navigationItem.title = @"预览";
    
    UIButton *chooseButton = [[UIButton alloc] init];
    chooseButton.frame = CGRectMake(0, 0, 50, 44);
    chooseButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    chooseButton.titleLabel.font = config.naviItemFont;
    [chooseButton setTitleColor:config.naviTitleColor forState:UIControlStateNormal];
    [chooseButton setTitle:@"选择" forState:UIControlStateNormal];
    [chooseButton addTarget:self action:@selector(click_chooseButton) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:chooseButton];
    
    UIButton *backButton = [[UIButton alloc] init];
    [backButton setImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_navigation_back.png"] forState:UIControlStateNormal];
    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [backView addSubview:backButton];
    backButton.frame = CGRectMake(0, 10, 14.4, 24);
    [backButton addTarget:self action:@selector(click_backButton) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backView];
}

- (void)setupSubviews {
    
    _firstLayout = YES;
    
    _screenShotImageView = [[UIImageView alloc] init];
    _screenShotImageView.image = _screenShotImage;
    [self.view addSubview:_screenShotImageView];
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_scrollView];

    _previewImageView = [[UIImageView alloc] init];
    _previewImageView.userInteractionEnabled = YES;
    [self.scrollView addSubview:_previewImageView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.delegate = self;
    [self.previewImageView addGestureRecognizer:panGesture];
    
    if (_previewAsset.mediaType != PHAssetMediaTypeImage) {//非图片预览模式
        _videoPlayer      = [AVPlayer playerWithPlayerItem:_playerItem];
        _videoPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:_videoPlayer];
        _videoPlayerLayer.zPosition = 0.5;
        [_previewImageView.layer addSublayer:_videoPlayerLayer];
        [_videoPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        
        _isPlaying = NO;
        _videoControl = [[UIButton alloc] init];
        [_videoControl setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
        _videoControl.layer.zPosition = 1;
        [_previewImageView addSubview:_videoControl];
        [_videoControl addTarget:self action:@selector(click_videoControl) forControlEvents:UIControlEventTouchUpInside];
        [self addNotification];
    } else {//图片预览模式
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.maximumZoomScale = 2.0;
        _scrollView.delegate = self;
        
        self.clipConfirmView.hidden = NO;
    }
}

- (void)setupClipMaskView {
    if (!_clipMaskImageView) {

        CGFloat itemW = MIN(_previewImageView.frame.size.width, _previewImageView.frame.size.height);
        
        CGSize contextSize = self.scrollView.bounds.size;
        if (self.coverImage.size.width > self.coverImage.size.height) {
            contextSize.width += (_previewImageView.frame.size.width - itemW);
        } else {
            contextSize.height += (_previewImageView.frame.size.height - itemW);
        }
        UIGraphicsBeginImageContext(contextSize);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7] set];
        CGContextAddRect(ctx, CGRectMake(0, 0, contextSize.width, contextSize.height));
        CGContextFillPath(ctx);
        
        CGContextSetBlendMode(ctx, kCGBlendModeClear);
        CGContextFillEllipseInRect(ctx, CGRectMake(contextSize.width * 0.5 - itemW * 0.5 + 10, contextSize.height * 0.5 - itemW * 0.5 + 10, itemW - 20, itemW - 20));
        CGContextFillPath(ctx);
        
        UIImage *clipImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        _clipMaskImageView = [[UIImageView alloc] initWithImage:clipImage];
        _clipMaskImageView.userInteractionEnabled = YES;
        if (_coverImage.size.width != _coverImage.size.height) {
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanClipGesture:)];
            pan.delegate = self;
            [_clipMaskImageView addGestureRecognizer:pan];
        }
        [self.scrollView addSubview:_clipMaskImageView];
    }
    
    CGPoint center = _clipMaskImageView.center;
    center.y = CGRectGetMidY(_previewImageView.frame);
    center.x = CGRectGetMidX(_previewImageView.frame);
    _clipMaskImageView.center = center;
    _clipMaskImageView.hidden = NO;
}

#pragma mark -
- (void)aspectFitImageViewForImage:(UIImage *)image {
    CGFloat scale = MIN(self.scrollView.frame.size.width / image.size.width, self.scrollView.frame.size.height / image.size.height);
    CGFloat w = scale * image.size.width;
    CGFloat h = scale * image.size.height;
    _previewImageView.frame = CGRectMake((self.scrollView.frame.size.width - w) * 0.5, (self.scrollView.frame.size.height - h) * 0.5, w, h);
}

- (CGSize)targetSize {
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeMake([UIScreen mainScreen].bounds.size.width * scale,
                      ([UIScreen mainScreen].bounds.size.height - 44.0 - [UIApplication sharedApplication].statusBarFrame.size.height) * scale);
}

- (CGRect)imageFrameToWindow {
    CGFloat naviH = 44.0;
    CGFloat statusH = [UIApplication sharedApplication].statusBarFrame.size.height;
    if (_previewAsset.mediaType == PHAssetMediaTypeImage) {
        return CGRectMake(0, naviH + statusH, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - naviH - statusH - 50.0);
    } else {
        return CGRectMake(0, naviH + statusH, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - naviH - statusH);
    }
}

- (void)clipImage {
    
    CGFloat margin = 10;
    CGFloat itemW = MIN(self.previewImageView.frame.size.width, self.previewImageView.frame.size.height);
    CGFloat delta = self.coverImage.size.width / self.previewImageView.frame.size.width;
    CGFloat cornerRadius = (itemW - 2 * margin) * 0.5;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(cornerRadius * 2 * delta, cornerRadius * 2 * delta), NO, self.coverImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, cornerRadius * 2 * delta, cornerRadius * 2 * delta) cornerRadius:cornerRadius * delta];
    CGContextAddPath(context, path.CGPath);
    CGContextClip(context);
    
    CGRect rect = CGRectMake(- (self.clipMaskImageView.center.x - self.previewImageView.frame.origin.x - cornerRadius) * delta,
                             - (self.clipMaskImageView.center.y - self.previewImageView.frame.origin.y - cornerRadius) * delta,
                             self.coverImage.size.width,
                             self.coverImage.size.height);
    [self.coverImage drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [UIView animateWithDuration:0.5 animations:^{
        self.clipConfirmView.transform = CGAffineTransformMakeTranslation(0, 50);
    }];
    self.clipMaskImageView.hidden = YES;

    self.previewImageView.image = newImage;
    self.scrollView.frame = self.view.bounds;
    [self aspectFitImageViewForImage:newImage];
}

#pragma mark - Action
- (void)handlePanGesture:(UIPanGestureRecognizer *)pan {
  
    switch (pan.state) {
        case UIGestureRecognizerStateChanged: {
            CGPoint offset = [pan translationInView:self.view];
            self.previewImageView.center = CGPointMake(self.scrollView.center.x + offset.x,
                                                       self.scrollView.center.y + offset.y);
            CGFloat maxOffsetX = self.view.frame.size.width  * 0.40;
            CGFloat maxOffsetY = self.view.frame.size.height * 0.40;
            CGFloat minScale   = 0.3;
            if (fabs(offset.x) > fabs(offset.y)) {
                CGFloat scale = 1 - (1 - minScale) / maxOffsetX * MIN(fabs(offset.x), maxOffsetX);
                CGFloat alpha = 1 - MIN(1.0, fabs(offset.x) / maxOffsetX);
                self.previewImageView.transform = CGAffineTransformMakeScale(scale, scale);
                self.scrollView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:alpha];
            } else {
                CGFloat scale = 1 - (1 - minScale) / maxOffsetY * MIN(fabs(offset.y), maxOffsetY);
                CGFloat alpha = 1 - MIN(1.0, fabs(offset.y) / maxOffsetY);
                self.previewImageView.transform = CGAffineTransformMakeScale(scale, scale);
                self.scrollView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:alpha];
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            [UIView animateWithDuration:0.2 animations:^{
                if (self.previewImageView.transform.a <= 0.6) {
                    [self.navigationController popViewControllerAnimated:YES];
                } else {
                    self.previewImageView.transform = CGAffineTransformIdentity;
                    self.previewImageView.center = self.scrollView.center;
                    self.scrollView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
                }
            }];
            break;
        }
        default:
            break;
    }
}

- (void)handlePanClipGesture:(UIPanGestureRecognizer *)pan {
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            _clipStartPoint = _clipMaskImageView.center;
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint offset = [pan translationInView:self.view];
            if (self.coverImage.size.width > self.coverImage.size.height) {
                CGFloat offsetX = offset.x;
                CGPoint center = _clipMaskImageView.center;
                center.x = _clipStartPoint.x + offsetX;
                center.x = MIN(_previewImageView.frame.size.width - _previewImageView.frame.size.height * 0.5, center.x);
                center.x = MAX(_previewImageView.frame.size.height * 0.5, center.x);
                _clipMaskImageView.center = center;
            } else {
                CGFloat offsetY = offset.y;
                CGPoint center = _clipMaskImageView.center;
                center.y = _clipStartPoint.y + offsetY;
                center.y = MIN(_previewImageView.frame.size.height - _previewImageView.frame.size.width * 0.5 + _previewImageView.frame.origin.y, center.y);
                center.y = MAX(_previewImageView.frame.size.width * 0.5 + _previewImageView.frame.origin.y, center.y);
                _clipMaskImageView.center = center;
            }
        }
            break;
        default:
            break;
    }
}

- (void)click_chooseButton {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    if (_previewAsset.mediaType == PHAssetMediaTypeImage) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.deliveryMode = config.imageDeliveryMode;
        option.synchronous = NO;
        CGFloat width = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale;
        [WKPhotoAlbumUtils readImageByAsset:_previewAsset size:CGSizeMake(width, width) deliveryMode:config.imageDeliveryMode contentModel:PHImageContentModeAspectFill synchronous:NO complete:^(UIImage * _Nullable image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self callBackWithResults:@[image]];
            });
        }];
    } else if (_previewAsset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
        option.deliveryMode = config.videoDeliveryMode;
        [[PHImageManager defaultManager] requestAVAssetForVideo:_previewAsset options:option resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL *url = [asset valueForKey:@"URL"];
                [self callBackWithResults:@[url]];
            });
        }];
    }
}

- (void)callBackWithResults:(NSArray *)results {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    
    if ([config.delegate respondsToSelector:@selector(photoAlbumDidSelectResult:)]) {
        [config.delegate photoAlbumDidSelectResult:results];
    }
    if (config.selectBlock) {
        config.selectBlock(results);
    }
    if (config.fromVC) {
        [self.navigationController popToViewController:config.fromVC animated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    [WKPhotoAlbumConfig clearReback];
}


- (void)click_editAndClipButton {
    if (_cancelClipBtn.isHidden) {
        self.scrollView.zoomScale = 1.0;
        [self aspectFitImageViewForImage:_coverImage];
        [self setupClipMaskView];
        self.clipMaskImageView.alpha = 0.0;
        self.scrollView.scrollEnabled = NO;
        
        [UIView animateWithDuration:0.5 animations:^{
            self.clipConfirmView.transform = CGAffineTransformMakeTranslation(0, 50);
        } completion:^(BOOL finished) {
            [_editAndClipBtn setTitle:@"裁剪" forState:UIControlStateNormal];
            _cancelClipBtn.hidden = NO;
            [UIView animateWithDuration:0.5 animations:^{
                self.clipMaskImageView.alpha = 1.0;
                _clipConfirmView.transform = CGAffineTransformIdentity;
            }];
        }];
    } else {
        [self clipImage];
    }
}

- (void)click_cancelClipButton {
    self.scrollView.scrollEnabled = YES;
    self.clipMaskImageView.hidden = YES;
    [UIView animateWithDuration:0.5 animations:^{
        _clipConfirmView.transform = CGAffineTransformMakeTranslation(0, 50);
    } completion:^(BOOL finished) {
        [_editAndClipBtn setTitle:@"编辑" forState:UIControlStateNormal];
        _cancelClipBtn.hidden = YES;
        [UIView animateWithDuration:0.3 animations:^{
            _clipConfirmView.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)click_videoControl {
    if (_isPlaying) {
        [_videoPlayer pause];
        [_videoControl setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
    } else {
        [_videoPlayer play];
        [_videoControl setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_pause.png"] forState:UIControlStateNormal];
    }
    _isPlaying = !_isPlaying;
}

- (void)click_backButton {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Notification
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    [_videoPlayer removeObserver:self forKeyPath:@"status"];
}

- (void)appDidEnterBackground {
    if (_isPlaying) {
        [_videoControl setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
        [_videoPlayer pause];
    }
}

- (void)appDidEnterPlayGround {
    if (_isPlaying) {
        [_videoControl setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_pause.png"] forState:UIControlStateNormal];
        [_videoPlayer play];
    }
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    _isPlaying = NO;
    [_videoControl setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
    [_videoPlayer seekToTime:CMTimeMake(0, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {}];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            [self click_videoControl];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.view == _previewImageView) {
        return YES;
    }
    CGPoint location = [gestureRecognizer locationInView:self.clipMaskImageView];
    
    CGFloat itemW = MIN(_previewImageView.frame.size.width, _previewImageView.frame.size.height);
    CGFloat cornetRaidus = (itemW - 20) * 0.5;
    CGPoint center = CGPointMake(self.clipMaskImageView.bounds.size.width * 0.5, self.clipMaskImageView.bounds.size.height * 0.5);
    CGFloat deltaX = location.x - center.x;
    CGFloat deltaY = location.y - center.y;
    return sqrt(deltaX * deltaX + deltaY * deltaY) <= cornetRaidus;
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.previewImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGRect frame = self.previewImageView.frame;
    frame.origin.y = scrollView.frame.size.height > self.previewImageView.frame.size.height ? (scrollView.frame.size.height - self.previewImageView.frame.size.height) * 0.5 : 0;
    frame.origin.x = scrollView.frame.size.width > self.previewImageView.frame.size.width ? (scrollView.frame.size.width - self.previewImageView.frame.size.width) * 0.5 : 0;
    self.previewImageView.frame = frame;
    scrollView.contentSize = CGSizeMake(frame.size.width, frame.size.height);
}

#pragma mark - UINavigationControllerDelegate
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    if (operation == UINavigationControllerOperationNone) {
        return nil;
    }
    if (fromVC == self && ![NSStringFromClass(toVC.class) isEqualToString:@"WKPhotoCollectionViewController"]) {
        return nil;
    }
    return [WKPhotoPreviewTransition animationWithAnimationControllerForOperation:operation completed:^{
        self.previewImageView.image = self.coverImage;
    }];
}

#pragma mark - Lazy load
- (UIView *)clipConfirmView {
    if (!_clipConfirmView) {
        _clipConfirmView = [[UIView alloc] init];
        _clipConfirmView.backgroundColor = [UIColor whiteColor];
        
        _editAndClipBtn = [[UIButton alloc] init];
        [_editAndClipBtn addTarget:self action:@selector(click_editAndClipButton) forControlEvents:UIControlEventTouchUpInside];
        _editAndClipBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [_editAndClipBtn setTitle:@"编辑" forState:UIControlStateNormal];
        [_editAndClipBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _editAndClipBtn.frame = CGRectMake(CGRectGetWidth(self.view.frame) - 85, 0, 65, 50);
        [_clipConfirmView addSubview:_editAndClipBtn];
        
        _cancelClipBtn = [[UIButton alloc] init];
        [_cancelClipBtn addTarget:self action:@selector(click_cancelClipButton) forControlEvents:UIControlEventTouchUpInside];
        _cancelClipBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [_cancelClipBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelClipBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _cancelClipBtn.frame = CGRectMake(20, 0, 65, 50);
        [_clipConfirmView addSubview:_cancelClipBtn];
        _cancelClipBtn.hidden = YES;
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointZero];
        [path addLineToPoint:CGPointMake(self.view.bounds.size.width, 0)];
        _clipConfirmView.layer.shadowPath = path.CGPath;
        _clipConfirmView.layer.shadowOpacity = 0.7;
        
        [self.view addSubview:_clipConfirmView];
    }
    return _clipConfirmView;
}


@end
