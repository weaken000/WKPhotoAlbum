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
WKPhotoCollectBottomViewDelegate,
WKPhotoAlbumPreviewCellDelegate
>

@property (nonatomic, strong) UICollectionView  *previewCollectionView;

@property (nonatomic, strong) WKPhotoCollectBottomView *actionView;

@property (nonatomic, strong) WKPhotoPreviewNavigationView *navigationView;

@property (nonatomic, strong) UIImageView   *clipMaskImageView;

//video
@property (nonatomic, strong) UIButton      *videoControl;

@property (nonatomic, strong) AVPlayer      *videoPlayer;

@property (nonatomic, strong) AVPlayerLayer *videoPlayerLayer;

@property (nonatomic, assign) BOOL          isPlaying;

@end

@implementation WKPhotoPreviewViewController {
    BOOL      _firstLayout;
    CGPoint   _clipStartPoint;

    UIPanGestureRecognizer *_dismissPanGesture;
    UITapGestureRecognizer *_hiddenTapGesture;
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
    
    _hiddenTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHiddenGesture:)];
    [self.previewCollectionView addGestureRecognizer:_hiddenTapGesture];
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
        _firstLayout = NO;
    }
}

- (void)click_naviLeft:(UIButton *)sender {
    if (self.navigationView.isInEditMode) {
        [self intoEditMode:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (void)click_naviRight:(UIButton *)sender {
    if (self.navigationView.isInEditMode) {
        [self clipImage];
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
#pragma mark - WKPhotoAlbumPreviewCellDelegate
- (void)photoPreviewCellDidPlayControl:(WKPhotoAlbumPreviewCell *)previewCell {
    [self setupPlayerForCell:previewCell];
}

- (void)setupPlayerForCell:(WKPhotoAlbumPreviewCell *)previewCell {
    WKPhotoAlbumModel *model = self.manager.allPhotoArray[self.manager.currentPreviewIndex];
    model.isPlaying = YES;
    
    previewCell.videoContentView.hidden = NO;
    previewCell.videoStartBtn.hidden = YES;

    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:model.playItem.asset];
    _videoPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    _videoPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:_videoPlayer];
  
    if (!_videoControl) {
        _videoControl = [[UIButton alloc] init];
        [_videoControl addTarget:self action:@selector(click_videoControl) forControlEvents:UIControlEventTouchUpInside];
    }
    _videoPlayerLayer.frame = previewCell.videoContentView.bounds;
    [previewCell.videoContentView.layer addSublayer:_videoPlayerLayer];
    [_videoControl setImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
    _videoControl.frame = CGRectMake((previewCell.videoContentView.bounds.size.width - 50) / 2.0,
                                     (previewCell.videoContentView.bounds.size.height - 50) / 2.0,
                                     50, 50);
    [previewCell.videoContentView addSubview:_videoControl];
    _isPlaying = NO;
    [self addNotification];
}
- (void)clearPlayerForIndexPath:(NSIndexPath *)indexPath previewCell:(WKPhotoAlbumPreviewCell *)cell {
    WKPhotoAlbumModel *model = self.manager.allPhotoArray[indexPath.row];
    if (model.isPlaying) {
        cell.albumInfo = model;
        model.isPlaying = NO;
        
        [_videoPlayer pause];
        [self removeNotification];
        _videoPlayer = nil;
        [_videoPlayerLayer removeFromSuperlayer];

        [_videoControl setImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
        [_videoControl removeFromSuperview];
        _isPlaying = NO;
    }
}

#pragma mark - WKPhotoCollectBottomViewDelegate
- (void)actionViewDidClickSelect:(WKPhotoCollectBottomView *)actionView {
    [self.manager requestSelectImage:^(NSArray * _Nullable images) {
        WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
        if ([config.delegate respondsToSelector:@selector(photoAlbumDidSelectResult:)]) {
            [config.delegate photoAlbumDidSelectResult:images];
        }
        if (config.selectBlock) {
            config.selectBlock(images);
        }
        if (config.fromVC) {
            [self.navigationController popToViewController:config.fromVC animated:YES];
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
        [WKPhotoAlbumConfig clearReback];
        [self.manager removeListener:(id<WKPhotoAlbumCollectManagerChanged>)self.actionView];
    }];
}
- (void)actionViewDidClickPreOrEditView:(WKPhotoCollectBottomView *)actionView {
    if (!self.navigationView.isInEditMode) {
        [self intoEditMode:YES];
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
    cell.delegate = self;
    WKPhotoAlbumModel *model = [self.manager.allPhotoArray objectAtIndex:indexPath.row];
    cell.albumInfo = model;
    if (model.resultImage) {
        cell.image = model.resultImage;
    } else {
        [self.manager reqeustCollectionImageForIndexPath:indexPath resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if ([cell.albumInfo.asset.localIdentifier isEqualToString:model.asset.localIdentifier] && result) {
                cell.image = result;
            } else {
                cell.image = nil;
            }
        }];
    }
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self clearPlayerForIndexPath:indexPath previewCell:(WKPhotoAlbumPreviewCell *)cell];
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
- (void)intoEditMode:(BOOL)editMode {
    [self.navigationView toEditMode:editMode];
    if (editMode) {
        self.actionView.hidden = YES;
        _hiddenTapGesture.enabled = NO;
        _dismissPanGesture.enabled = NO;
        self.previewCollectionView.scrollEnabled = NO;
        [self setupClipMaskView];
    } else {
        self.actionView.hidden = NO;
        _hiddenTapGesture.enabled = YES;
        _dismissPanGesture.enabled = YES;
        self.previewCollectionView.scrollEnabled = YES;
        _clipMaskImageView.hidden = YES;
        WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.previewCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.manager.currentPreviewIndex inSection:0]];
        [cell intoClipMode:NO];
    }
}
- (void)setupClipMaskView {
    if (!_clipMaskImageView) {
        _clipMaskImageView = [[UIImageView alloc] init];
        _clipMaskImageView.userInteractionEnabled = YES;
        [self.view insertSubview:_clipMaskImageView belowSubview:self.navigationView];
    }
    
    WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.previewCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.manager.currentPreviewIndex inSection:0]];
    [cell intoClipMode:YES];
    [self.view layoutSubviews];
    
    CGRect imageRect = [cell.imageView.superview convertRect:cell.imageView.frame toView:self.view];
    CGFloat itemW = MIN(imageRect.size.width, imageRect.size.height);
    
    CGSize contextSize = self.view.bounds.size;
    if (imageRect.size.width > imageRect.size.height) {
        contextSize.width += (imageRect.size.width - itemW);
    } else {
        contextSize.height += (imageRect.size.height - itemW);
    }
    UIGraphicsBeginImageContext(contextSize);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor colorWithRed:1 green:1 blue:1 alpha:0.3] set];
    CGContextAddRect(ctx, CGRectMake(0, 0, contextSize.width, contextSize.height));
    CGContextFillPath(ctx);
    
    CGContextSetBlendMode(ctx, kCGBlendModeClear);
    CGContextFillEllipseInRect(ctx, CGRectMake(contextSize.width * 0.5 - itemW * 0.5 + 10, contextSize.height * 0.5 - itemW * 0.5 + 10, itemW - 20, itemW - 20));
    CGContextFillPath(ctx);
    
    UIImage *clipImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    _clipMaskImageView.image = clipImage;
    _clipMaskImageView.frame = CGRectMake(0, 0, contextSize.width, contextSize.height);
    
    if (cell.imageView.frame.size.width != cell.imageView.frame.size.height && !_clipMaskImageView.gestureRecognizers.count) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanClipGesture:)];
        pan.delegate = self;
        [_clipMaskImageView addGestureRecognizer:pan];
    }
    if (cell.imageView.frame.size.width == cell.imageView.frame.size.height && _clipMaskImageView.gestureRecognizers.count > 0) {
        [_clipMaskImageView removeGestureRecognizer:_clipMaskImageView.gestureRecognizers.firstObject];
    }
    _clipMaskImageView.center = self.view.center;
    _clipMaskImageView.hidden = NO;
}

#pragma mark -
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
    WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.previewCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.manager.currentPreviewIndex inSection:0]];
    CGFloat margin = 10;
    CGFloat itemW = MIN(cell.imageView.frame.size.width, cell.imageView.frame.size.height);
    CGFloat delta = cell.image.size.width / cell.imageView.frame.size.width;
    CGFloat cornerRadius = (itemW - 2 * margin) * 0.5;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(cornerRadius * 2 * delta, cornerRadius * 2 * delta), NO, cell.image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, cornerRadius * 2 * delta, cornerRadius * 2 * delta) cornerRadius:cornerRadius * delta];
    CGContextAddPath(context, path.CGPath);
    CGContextClip(context);

    CGRect rect = CGRectMake(- (self.clipMaskImageView.center.x - cell.imageView.frame.origin.x - cornerRadius) * delta,
                             - (self.clipMaskImageView.center.y - cell.imageView.frame.origin.y - cornerRadius) * delta,
                             cell.image.size.width,
                             cell.image.size.height);
    [cell.image drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self intoEditMode:NO];
    cell.image = newImage;
    self.manager.allPhotoArray[self.manager.currentPreviewIndex].resultImage = newImage;
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

- (void)handleHiddenGesture:(UITapGestureRecognizer *)tap {
    if (self.navigationView.alpha == 0.0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenBar) object:nil];
        [self performSelector:@selector(showBar) withObject:nil afterDelay:0.5];
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showBar) object:nil];
        [self performSelector:@selector(hiddenBar) withObject:nil afterDelay:0.5];
    }
}

- (void)handlePanClipGesture:(UIPanGestureRecognizer *)pan {
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            _clipStartPoint = _clipMaskImageView.center;
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint offset = [pan translationInView:self.view];
            if (_clipMaskImageView.frame.size.width > self.view.frame.size.width) {
                CGFloat delta = (_clipMaskImageView.frame.size.width - self.view.frame.size.width) * 0.5;
                CGFloat offsetX = offset.x;
                CGPoint center = _clipMaskImageView.center;
                center.x = _clipStartPoint.x + offsetX;
                center.x = MIN(self.view.frame.size.width * 0.5 + delta, center.x);
                center.x = MAX(self.view.frame.size.width * 0.5 - delta, center.x);
                _clipMaskImageView.center = center;
            } else {
                CGFloat delta = (_clipMaskImageView.frame.size.height - self.view.frame.size.height) * 0.5;
                CGFloat offsetY = offset.y;
                CGPoint center = _clipMaskImageView.center;
                center.y = _clipStartPoint.y + offsetY;
                center.y = MIN(self.view.frame.size.height * 0.5 + delta, center.y);
                center.y = MAX(self.view.frame.size.height * 0.5 - delta, center.y);
                _clipMaskImageView.center = center;
            }
        }
            break;
        default:
            break;
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

- (void)click_videoControl {
    if (_isPlaying) {
        [_videoPlayer pause];
        [_videoControl setImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
    } else {
        [_videoPlayer play];
        [_videoControl setImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_pause.png"] forState:UIControlStateNormal];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_videoPlayer.currentItem];
    [_videoPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_videoPlayer.currentItem];
    [_videoPlayer removeObserver:self forKeyPath:@"status"];
}

- (void)appDidEnterBackground {
    if (_isPlaying) {
        [_videoControl setImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
        [_videoPlayer pause];
    }
}

- (void)appDidEnterPlayGround {
    if (_isPlaying) {
        [_videoControl setImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_pause.png"] forState:UIControlStateNormal];
        [_videoPlayer play];
    }
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    _isPlaying = NO;
    [_videoControl setImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
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
    if (gestureRecognizer.view == _clipMaskImageView) {
        return YES;
    }
    return NO;
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

    }];
}

@end
