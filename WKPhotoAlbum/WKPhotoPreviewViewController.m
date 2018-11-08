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

#import "WKPhotoCollectBottomView.h"
#import "WKPhotoAlbumPreviewCell.h"
#import "WKPhotoPreviewNavigationView.h"
#import "WKPhotoAlbumSelectButton.h"

@interface WKPhotoPreviewViewController ()
<
UIScrollViewDelegate,
UIGestureRecognizerDelegate,
UICollectionViewDelegate,
UICollectionViewDataSource,
WKPhotoCollectBottomViewDelegate
>

@property (nonatomic, strong) UICollectionView  *previewCollectionView;

@property (nonatomic, strong) WKPhotoCollectBottomView *actionView;

@property (nonatomic, strong) WKPhotoPreviewNavigationView *navigationView;

@property (nonatomic, strong) UIImageView   *clipMaskImageView;

@property (nonatomic, strong) UIView        *clipConfirmView;

//video
@property (nonatomic, strong) UIButton      *videoControl;

@property (nonatomic, strong) AVPlayer      *videoPlayer;

@property (nonatomic, strong) AVPlayerLayer *videoPlayerLayer;

@property (nonatomic, assign) BOOL          isPlaying;

@end

@implementation WKPhotoPreviewViewController {
    BOOL      _firstLayout;
    CGPoint   _clipStartPoint;
    
    UIButton *_editAndClipBtn;
    UIButton *_cancelClipBtn;
    UIPanGestureRecognizer *_dismissPanGesture;
}

#pragma mark - life circle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.manager.reqeustImageSize = [self targetSize];
    [self setupSubviews];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutSubview];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self removeNotification];
    [self.manager removeListener:(id<WKPhotoAlbumCollectManagerChanged>)self.actionView];
}

- (void)setupSubviews {
    
    _firstLayout = YES;
    
    _screenShotImageView = [[UIImageView alloc] init];
    _screenShotImageView.image = _screenShotImage;
    [self.view addSubview:_screenShotImageView];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = [UIScreen mainScreen].bounds.size;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0.f;
    layout.minimumInteritemSpacing = 0.f;
    _previewCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _previewCollectionView.showsHorizontalScrollIndicator = NO;
    _previewCollectionView.delegate = self;
    _previewCollectionView.dataSource = self;
    _previewCollectionView.pagingEnabled = YES;
    [_previewCollectionView registerClass:[WKPhotoAlbumPreviewCell class] forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:_previewCollectionView];

    _actionView = [[WKPhotoCollectBottomView alloc] initWithFrame:CGRectZero useForCollectVC:NO];
    _actionView.delegate = self;
    _actionView.manager = self.manager;
    [self.view addSubview:_actionView];
    
    _navigationView = [[WKPhotoPreviewNavigationView alloc] initWithTarget:self leftAction:@selector(click_naviLeft:) rightAction:@selector(click_naviRight:)];
    [self.navigationView configSelectIndex:self.manager.allPhotoArray[self.manager.currentPreviewIndex].selectIndex];
    [self.view addSubview:_navigationView];
    
    _dismissPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissPanGesture:)];
    _dismissPanGesture.delegate = self;
    [self.previewCollectionView addGestureRecognizer:_dismissPanGesture];
    [_previewCollectionView.panGestureRecognizer requireGestureRecognizerToFail:_dismissPanGesture];
    
//    if (_previewAsset.mediaType != PHAssetMediaTypeImage) {//非图片预览模式
//        _videoPlayer      = [AVPlayer playerWithPlayerItem:_playerItem];
//        _videoPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:_videoPlayer];
//        _videoPlayerLayer.zPosition = 0.5;
//        [_previewImageView.layer addSublayer:_videoPlayerLayer];
//        [_videoPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//
//        _isPlaying = NO;
//        _videoControl = [[UIButton alloc] init];
//        [_videoControl setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
//        _videoControl.layer.zPosition = 1;
//        [_previewImageView addSubview:_videoControl];
//        [_videoControl addTarget:self action:@selector(click_videoControl) forControlEvents:UIControlEventTouchUpInside];
//        [self addNotification];

}

- (void)layoutSubview {
    _screenShotImageView.frame = self.view.bounds;
    _previewCollectionView.frame = self.view.bounds;
    CGFloat actionH = kActionViewPreViewHeight + kActionViewActionHeight;
    if (@available(iOS 11.0, *)) {
        actionH += self.view.safeAreaInsets.bottom;
    }
    _actionView.frame = CGRectMake(0, self.view.bounds.size.height - actionH, self.view.bounds.size.width, actionH);
    
    if (_firstLayout) {
        [self.previewCollectionView setContentOffset:CGPointMake(self.manager.currentPreviewIndex * self.view.bounds.size.width, 0) animated:NO];
        //        _clipConfirmView.frame = CGRectMake(0,
        //                                            self.view.frame.size.height - 50,
        //                                            CGRectGetWidth(self.view.frame),
        //                                            50);
        
        //        [self aspectFitImageViewForImage:self.coverImage];
        //        _videoPlayerLayer.frame = _previewImageView.bounds;
        //        _videoControl.frame = CGRectMake((_previewImageView.bounds.size.width - 50) * 0.5,
        //                                         (_previewImageView.bounds.size.height - 50) * 0.5, 50, 50);
        
        _firstLayout = NO;
    }
}

- (void)click_naviLeft:(UIButton *)sender {
    if (self.navigationView.isInEditMode) {
        [self.navigationView toEditMode:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (void)click_naviRight:(UIButton *)sender {
    if (self.navigationView.isInEditMode) {
        [self.navigationView toEditMode:NO];
    } else {
        NSInteger index = self.previewCollectionView.contentOffset.x / self.previewCollectionView.frame.size.width;
        WKPhotoAlbumModel *model = self.manager.allPhotoArray[index];
        if (model.selectIndex > 0) {
            [self.manager cancelSelectIndex:index];
            [self.navigationView configSelectIndex:model.selectIndex];
        } else {
            [self.manager addSelectWithIndex:index];
            [self.navigationView configSelectIndex:model.selectIndex];
            [(WKPhotoAlbumSelectButton *)sender showAnimation];
        }
    }
}

#pragma mark - WKPhotoCollectBottomViewDelegate
- (void)actionViewDidClickSelect:(WKPhotoCollectBottomView *)actionView {
    
}
- (void)actionViewDidClickPreOrEditView:(WKPhotoCollectBottomView *)actionView {
    if (!self.navigationView.isInEditMode) {
        [self.navigationView toEditMode:YES];
    }
}
- (void)actionViewDidClickUseOrigin:(WKPhotoCollectBottomView *)actionView useOrigin:(BOOL)useOrigin {
    self.manager.isUseOrigin = useOrigin;
}
- (void)actionView:(WKPhotoCollectBottomView *)actionView didSelectIndex:(NSInteger)index {
    [self.previewCollectionView setContentOffset:CGPointMake(index * self.previewCollectionView.frame.size.width, 0) animated:YES];
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.manager.allPhotoArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WKPhotoAlbumPreviewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.cellType = WKPhotoAlbumCellTypePreview;
    WKPhotoAlbumModel *model = [self.manager.allPhotoArray objectAtIndex:indexPath.row];
    cell.assetIdentifier = model.asset.localIdentifier;
    [self.manager reqeustCollectionImageForIndexPath:indexPath resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if ([cell.assetIdentifier isEqualToString:model.asset.localIdentifier] && result) {
            cell.image = result;
        } else {
            cell.image = nil;
        }
    }];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationView.alpha == 0.0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenBar) object:nil];
        [self performSelector:@selector(showBar) withObject:nil afterDelay:0.5];
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showBar) object:nil];
        [self performSelector:@selector(hiddenBar) withObject:nil afterDelay:0.5];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)setNavigationBarSelectIndex {
    if (self.previewCollectionView.bounds.size.width == 0) return;
    NSInteger index = self.previewCollectionView.contentOffset.x / self.previewCollectionView.bounds.size.width;
    self.manager.currentPreviewIndex = index;
    [self.navigationView configSelectIndex:self.manager.allPhotoArray[index].selectIndex];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.manager updateCacheForCollectionView:self.previewCollectionView
                                    withOffset:CGPointMake(-self.previewCollectionView.frame.size.width, 0)];
    
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self setNavigationBarSelectIndex];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self setNavigationBarSelectIndex];
}

#pragma mark - Config
- (void)showBar {
    [UIView animateWithDuration:0.6 animations:^{
        self.navigationView.alpha = 1.0;
        self.actionView.alpha = 1.0;
    }];
}
- (void)hiddenBar {
    [UIView animateWithDuration:0.6 animations:^{
        self.navigationView.alpha = 0.0;
        self.actionView.alpha = 0.0;
    }];
}


- (void)setupClipMaskView {
//    if (!_clipMaskImageView) {
//
//        CGFloat itemW = MIN(_previewImageView.frame.size.width, _previewImageView.frame.size.height);
//
//        CGSize contextSize = self.scrollView.bounds.size;
//        if (self.coverImage.size.width > self.coverImage.size.height) {
//            contextSize.width += (_previewImageView.frame.size.width - itemW);
//        } else {
//            contextSize.height += (_previewImageView.frame.size.height - itemW);
//        }
//        UIGraphicsBeginImageContext(contextSize);
//        CGContextRef ctx = UIGraphicsGetCurrentContext();
//        [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7] set];
//        CGContextAddRect(ctx, CGRectMake(0, 0, contextSize.width, contextSize.height));
//        CGContextFillPath(ctx);
//
//        CGContextSetBlendMode(ctx, kCGBlendModeClear);
//        CGContextFillEllipseInRect(ctx, CGRectMake(contextSize.width * 0.5 - itemW * 0.5 + 10, contextSize.height * 0.5 - itemW * 0.5 + 10, itemW - 20, itemW - 20));
//        CGContextFillPath(ctx);
//
//        UIImage *clipImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//
//        _clipMaskImageView = [[UIImageView alloc] initWithImage:clipImage];
//        _clipMaskImageView.userInteractionEnabled = YES;
//        if (_coverImage.size.width != _coverImage.size.height) {
//            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanClipGesture:)];
//            pan.delegate = self;
//            [_clipMaskImageView addGestureRecognizer:pan];
//        }
//        [self.scrollView addSubview:_clipMaskImageView];
//    }
//
//    CGPoint center = _clipMaskImageView.center;
//    center.y = CGRectGetMidY(_previewImageView.frame);
//    center.x = CGRectGetMidX(_previewImageView.frame);
//    _clipMaskImageView.center = center;
//    _clipMaskImageView.hidden = NO;
}

#pragma mark -
- (void)aspectFitImageViewForImage:(UIImage *)image {
//    CGFloat scale = MIN(self.scrollView.frame.size.width / image.size.width, self.scrollView.frame.size.height / image.size.height);
//    CGFloat w = scale * image.size.width;
//    CGFloat h = scale * image.size.height;
//    _previewImageView.frame = CGRectMake((self.scrollView.frame.size.width - w) * 0.5, (self.scrollView.frame.size.height - h) * 0.5, w, h);
}

- (CGSize)targetSize {
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeMake([UIScreen mainScreen].bounds.size.width * scale,
                      ([UIScreen mainScreen].bounds.size.height * scale));
}

- (CGRect)dismissRect {
    if (_dismissPreViewImageView && !_dismissPreViewImageView.isHidden) {
        return [_dismissPreViewImageView.superview convertRect:_dismissPreViewImageView.frame toView:self.view];
    } else {
        WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.previewCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.manager.currentPreviewIndex inSection:0]];
        return [cell.imageView.superview convertRect:cell.imageView.frame toView:self.view];
    }
}



- (void)clipImage {
    
//    CGFloat margin = 10;
//    CGFloat itemW = MIN(self.previewImageView.frame.size.width, self.previewImageView.frame.size.height);
//    CGFloat delta = self.coverImage.size.width / self.previewImageView.frame.size.width;
//    CGFloat cornerRadius = (itemW - 2 * margin) * 0.5;
//
//    UIGraphicsBeginImageContextWithOptions(CGSizeMake(cornerRadius * 2 * delta, cornerRadius * 2 * delta), NO, self.coverImage.scale);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, cornerRadius * 2 * delta, cornerRadius * 2 * delta) cornerRadius:cornerRadius * delta];
//    CGContextAddPath(context, path.CGPath);
//    CGContextClip(context);
//
//    CGRect rect = CGRectMake(- (self.clipMaskImageView.center.x - self.previewImageView.frame.origin.x - cornerRadius) * delta,
//                             - (self.clipMaskImageView.center.y - self.previewImageView.frame.origin.y - cornerRadius) * delta,
//                             self.coverImage.size.width,
//                             self.coverImage.size.height);
//    [self.coverImage drawInRect:rect];
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    [UIView animateWithDuration:0.5 animations:^{
//        self.clipConfirmView.transform = CGAffineTransformMakeTranslation(0, 50);
//    }];
//    self.clipMaskImageView.hidden = YES;
//
//    self.previewImageView.image = newImage;
//    self.scrollView.frame = self.view.bounds;
//    [self aspectFitImageViewForImage:newImage];
}

#pragma mark - Action
- (void)handleDismissPanGesture:(UIPanGestureRecognizer *)pan {
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.previewCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.manager.currentPreviewIndex inSection:0]];
            if (!cell) return;
            
            if (!_dismissPreViewImageView) {
                _dismissPreViewImageView = [[UIImageView alloc] init];
                [self.view insertSubview:_dismissPreViewImageView belowSubview:self.navigationView];
            }
            _dismissPreViewImageView.image = cell.image;
            CGRect imageFrame = [cell.imageView.superview convertRect:cell.imageView.frame toView:self.view];
            _dismissPreViewImageView.frame = imageFrame;
            _dismissPreViewImageView.hidden = NO;
            cell.hidden = YES;
            
            [UIView animateWithDuration:0.6 animations:^{
                self.navigationView.alpha = 0.0;
                self.actionView.alpha = 0.0;
            }];
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (!_dismissPreViewImageView) return;
            CGPoint offset = [pan translationInView:self.view];
            self.dismissPreViewImageView.center = CGPointMake(self.view.center.x + offset.x,
                                                              self.view.center.y + offset.y);
            CGFloat maxOffsetX = self.view.frame.size.width  * 0.40;
            CGFloat maxOffsetY = self.view.frame.size.height * 0.40;
            CGFloat minScale   = 0.3;
            if (fabs(offset.x) > fabs(offset.y)) {
                CGFloat scale = 1 - (1 - minScale) / maxOffsetX * MIN(fabs(offset.x), maxOffsetX);
                CGFloat alpha = 1 - MIN(1.0, fabs(offset.x) / maxOffsetX);
                self.dismissPreViewImageView.transform = CGAffineTransformMakeScale(scale, scale);
                self.previewCollectionView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
            } else {
                CGFloat scale = 1 - (1 - minScale) / maxOffsetY * MIN(fabs(offset.y), maxOffsetY);
                CGFloat alpha = 1 - MIN(1.0, fabs(offset.y) / maxOffsetY);
                self.dismissPreViewImageView.transform = CGAffineTransformMakeScale(scale, scale);
                self.previewCollectionView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (self.dismissPreViewImageView.transform.a <= 0.6) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [UIView animateWithDuration:0.2 animations:^{
                    self.dismissPreViewImageView.transform = CGAffineTransformIdentity;
                    self.dismissPreViewImageView.center = self.view.center;
                    self.previewCollectionView.backgroundColor = [UIColor blackColor];
                    self.navigationView.alpha = 1.0;
                    self.actionView.alpha = 1.0;
                } completion:^(BOOL finished) {
                    WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.previewCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.manager.currentPreviewIndex inSection:0]];
                    cell.hidden = NO;
                    self.dismissPreViewImageView.hidden = YES;
                }];
            }
            break;
        }
        default:
            break;
    }
}

- (void)handlePanClipGesture:(UIPanGestureRecognizer *)pan {
    
//    switch (pan.state) {
//        case UIGestureRecognizerStateBegan:
//            _clipStartPoint = _clipMaskImageView.center;
//            break;
//        case UIGestureRecognizerStateChanged: {
//            CGPoint offset = [pan translationInView:self.view];
//            if (self.coverImage.size.width > self.coverImage.size.height) {
//                CGFloat offsetX = offset.x;
//                CGPoint center = _clipMaskImageView.center;
//                center.x = _clipStartPoint.x + offsetX;
//                center.x = MIN(_previewImageView.frame.size.width - _previewImageView.frame.size.height * 0.5, center.x);
//                center.x = MAX(_previewImageView.frame.size.height * 0.5, center.x);
//                _clipMaskImageView.center = center;
//            } else {
//                CGFloat offsetY = offset.y;
//                CGPoint center = _clipMaskImageView.center;
//                center.y = _clipStartPoint.y + offsetY;
//                center.y = MIN(_previewImageView.frame.size.height - _previewImageView.frame.size.width * 0.5 + _previewImageView.frame.origin.y, center.y);
//                center.y = MAX(_previewImageView.frame.size.width * 0.5 + _previewImageView.frame.origin.y, center.y);
//                _clipMaskImageView.center = center;
//            }
//        }
//            break;
//        default:
//            break;
//    }
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
//    if (_cancelClipBtn.isHidden) {
//        self.scrollView.zoomScale = 1.0;
//        [self aspectFitImageViewForImage:_coverImage];
//        [self setupClipMaskView];
//        self.clipMaskImageView.alpha = 0.0;
//        self.scrollView.scrollEnabled = NO;
//
//        [UIView animateWithDuration:0.5 animations:^{
//            self.clipConfirmView.transform = CGAffineTransformMakeTranslation(0, 50);
//        } completion:^(BOOL finished) {
//            [_editAndClipBtn setTitle:@"裁剪" forState:UIControlStateNormal];
//            _cancelClipBtn.hidden = NO;
//            [UIView animateWithDuration:0.5 animations:^{
//                self.clipMaskImageView.alpha = 1.0;
//                _clipConfirmView.transform = CGAffineTransformIdentity;
//            }];
//        }];
//    } else {
//        [self clipImage];
//    }
}

- (void)click_cancelClipButton {
//    self.scrollView.scrollEnabled = YES;
//    self.clipMaskImageView.hidden = YES;
//    [UIView animateWithDuration:0.5 animations:^{
//        _clipConfirmView.transform = CGAffineTransformMakeTranslation(0, 50);
//    } completion:^(BOOL finished) {
//        [_editAndClipBtn setTitle:@"编辑" forState:UIControlStateNormal];
//        _cancelClipBtn.hidden = YES;
//        [UIView animateWithDuration:0.3 animations:^{
//            _clipConfirmView.transform = CGAffineTransformIdentity;
//        }];
//    }];
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
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

- (void)removeNotification {
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
//    [_videoPlayer removeObserver:self forKeyPath:@"status"];
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
    if (gestureRecognizer == _dismissPanGesture) {
        CGPoint offset = [_dismissPanGesture translationInView:_dismissPanGesture.view];
        return fabs(offset.y) > fabs(offset.x) * 2;
    }
    return NO;
//    if (gestureRecognizer.view == _previewImageView) {
//        return YES;
//    }
//    CGPoint location = [gestureRecognizer locationInView:self.clipMaskImageView];
//
//    CGFloat itemW = MIN(_previewImageView.frame.size.width, _previewImageView.frame.size.height);
//    CGFloat cornetRaidus = (itemW - 20) * 0.5;
//    CGPoint center = CGPointMake(self.clipMaskImageView.bounds.size.width * 0.5, self.clipMaskImageView.bounds.size.height * 0.5);
//    CGFloat deltaX = location.x - center.x;
//    CGFloat deltaY = location.y - center.y;
//    return sqrt(deltaX * deltaX + deltaY * deltaY) <= cornetRaidus;
//    return YES;
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
//        self.previewImageView.image = self.coverImage;
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
