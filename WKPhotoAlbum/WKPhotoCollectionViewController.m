//
//  WKPhotoCollectionViewController.m
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoCollectionViewController.h"
#import "WKPhotoPreviewViewController.h"
#import "WKPhotoAlbumViewController.h"

#import "WKPhotoCollectionCell.h"
#import "WKPhotoAlbumUtils.h"

#import "WKPhotoAlbumConfig.h"


@interface WKPhotoAlbumAuthorizationView : UIView

@property (nonatomic, copy, nullable) void (^ jumpToSetting)(void);

@property (nonatomic, copy, nullable) void (^ requestBlock)(void);

- (void)configAuthStatus:(PHAuthorizationStatus)authStatus;

@end

@implementation WKPhotoAlbumAuthorizationView {
    UIButton    *_requestAuthBtn;
    UIButton    *_jumpToSettingBtn;
    UILabel     *_deniedTipLabel;
    UIImageView *_deniedTipImageView;
}

- (void)configAuthStatus:(PHAuthorizationStatus)authStatus {
    if (authStatus == PHAuthorizationStatusAuthorized) {
        self.hidden = YES;
    } else if (authStatus == PHAuthorizationStatusDenied || authStatus == PHAuthorizationStatusRestricted) {
        _requestAuthBtn.hidden = YES;
        if (!_jumpToSettingBtn) {
            _deniedTipLabel = [[UILabel alloc] init];
            _deniedTipLabel.textAlignment = NSTextAlignmentCenter;
            _deniedTipLabel.numberOfLines = 0;
            _deniedTipLabel.font = [UIFont systemFontOfSize:18];
            _deniedTipLabel.textColor = [UIColor blackColor];
            _deniedTipLabel.text = @"获取相册被拒绝，请在iPhone的\"设置-隐私-照片\"中允许访问照片";
            [self addSubview:_deniedTipLabel];
            
            _deniedTipImageView = [[UIImageView alloc] init];
            _deniedTipImageView.image = [UIImage imageNamed:@""];
            [self addSubview:_deniedTipImageView];
            
            _jumpToSettingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            _jumpToSettingBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
            [_jumpToSettingBtn setTitle:@"前往设置" forState:UIControlStateNormal];
            [_jumpToSettingBtn addTarget:self action:@selector(click_jumpToSetting) forControlEvents:UIControlEventTouchUpInside];
            [_jumpToSettingBtn sizeToFit];
            [self addSubview:_jumpToSettingBtn];
            
            _deniedTipImageView.frame = CGRectMake(0, 0, 120, 120);
            _deniedTipImageView.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 60);
            _jumpToSettingBtn.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(_deniedTipImageView.frame) + 30);
            CGSize labelSize = [_deniedTipLabel sizeThatFits:CGSizeMake(self.frame.size.width - 60, CGFLOAT_MAX)];
            _deniedTipLabel.frame = CGRectMake((self.frame.size.width - labelSize.width) * 0.5, CGRectGetMinY(_deniedTipImageView.frame) - 20 - labelSize.height, labelSize.width, labelSize.height);
        
        }
        _jumpToSettingBtn.hidden = NO;
        _deniedTipLabel.hidden = NO;
        _deniedTipImageView.hidden = NO;
        self.hidden = NO;
    } else {
        _jumpToSettingBtn.hidden = YES;
        _deniedTipLabel.hidden = YES;
        _deniedTipImageView.hidden = YES;
        if (!_requestAuthBtn) {
            _requestAuthBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            _requestAuthBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
            [_requestAuthBtn setTitle:@"开启相册权限" forState:UIControlStateNormal];
            [_requestAuthBtn addTarget:self action:@selector(click_requestAuthBtn) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_requestAuthBtn];
            [_requestAuthBtn sizeToFit];
            _requestAuthBtn.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        }
        _requestAuthBtn.hidden = NO;
        self.hidden = NO;
    }
}

- (void)click_requestAuthBtn {
    if (_requestBlock) {
        _requestBlock();
    }
}

- (void)click_jumpToSetting {
    if (_jumpToSetting) {
        _jumpToSetting();
    }
}

@end


@interface WKPhotoCollectionViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, WKPhotoCollectionCellDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
//图片缓存
@property (nonatomic, strong) PHCachingImageManager *imageManager;

@property (nonatomic, strong) WKPhotoAlbumAuthorizationView *authorizationView;

@end

@implementation WKPhotoCollectionViewController {
    NSMutableArray<PHAsset *> *_asset;
    PHImageRequestOptions     *_reqeustOptions;
    CGRect                    _previousPreheatRect;
    CGSize                    _thumSize;
    
    NSMutableArray            *_selectIndexArr;
    UIButton                  *_rightNaviItem;
    NSInteger                 _maxCount;
    PHAuthorizationStatus     _photoAuthorization;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self installNavi];
    [self setupFromVC];
    [self requestAuthorization];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _collectionView.frame = self.view.bounds;
}

#pragma mark -
- (void)requestAuthorization {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    _photoAuthorization = status;
    if (status == PHAuthorizationStatusAuthorized) {//已获得权限
        [self installProperty];
        [self insertPhotoAlbumVC];
        [self setupManager];
        [self setupSubviews];
    } else {
        [self.authorizationView configAuthStatus:status];
    }
}

- (void)setupFromVC {
    NSArray *tmp = [[self.navigationController.childViewControllers reverseObjectEnumerator] allObjects];
    for (UIViewController *vc in tmp) {
        if ([vc isKindOfClass:[WKPhotoAlbumViewController class]]) {
            return;
        }
    }
    [WKPhotoAlbumConfig sharedConfig].fromVC = self.navigationController.childViewControllers[self.navigationController.childViewControllers.count - 2];
}

- (void)installNavi {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    UIButton *backButton = [[UIButton alloc] init];
    backButton.frame = CGRectMake(0, 0, 50, 44);
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [backButton setImage:[UIImage imageNamed:@"login_icon_back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(click_backButton) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    _rightNaviItem = [[UIButton alloc] init];
    _rightNaviItem.frame = CGRectMake(0, 0, 50, 44);
    _rightNaviItem.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_rightNaviItem setTitle:@"选择" forState:UIControlStateNormal];
    [_rightNaviItem setTitleColor:config.naviTitleColor forState:UIControlStateNormal];
    _rightNaviItem.titleLabel.font = config.naviItemFont;
    [_rightNaviItem addTarget:self action:@selector(click_naviRight) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_rightNaviItem];
    _rightNaviItem.hidden = YES;
}

#pragma mark -
- (void)insertPhotoAlbumVC {
    NSArray *tmp = [[self.navigationController.childViewControllers reverseObjectEnumerator] allObjects];
    for (UIViewController *vc in tmp) {
        if ([vc isKindOfClass:[WKPhotoAlbumViewController class]]) {
            return;
        }
    }
    NSMutableArray *childVCs = [self.navigationController.childViewControllers mutableCopy];
    WKPhotoAlbumViewController *vc = [[WKPhotoAlbumViewController alloc] init];
    [childVCs insertObject:vc atIndex:childVCs.count - 1];
    [self.navigationController setViewControllers:childVCs];
    [WKPhotoAlbumConfig sharedConfig].fromVC = childVCs[childVCs.count - 3];
}

- (void)installProperty {
    
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    //获取资源
    if (self.assetDict) {
        PHAssetCollection *collection = self.assetDict[@"collection"];
        self.navigationItem.title = collection.localizedTitle?:@"";
        _asset = self.assetDict[@"asset"];
    } else {
        self.navigationItem.title = @"所有照片";
        //相机胶卷
        _asset = [WKPhotoAlbumUtils readSmartAlbumInConfig];
    }
    _selectIndexArr = [NSMutableArray array];
    _maxCount = config.maxSelectCount;
}

- (void)setupManager {
    _previousPreheatRect = CGRectZero;
    
    _imageManager = [[PHCachingImageManager alloc] init];
    [_imageManager stopCachingImagesForAllAssets];
    
    _reqeustOptions = [[PHImageRequestOptions alloc] init];
    _reqeustOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    _reqeustOptions.synchronous = NO;
}

- (void)setupSubviews {
    CGFloat numberOfLine = 4;
    CGFloat itemMargin = 1.0;
    CGFloat itemW = (self.view.bounds.size.width - (numberOfLine + 1) * itemMargin - 1) / numberOfLine;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.itemSize = CGSizeMake(itemW, itemW);
    layout.minimumLineSpacing = itemMargin;
    layout.minimumInteritemSpacing = itemMargin;
    
    _thumSize = CGSizeMake(itemW * [UIScreen mainScreen].scale, itemW * [UIScreen mainScreen].scale);
    
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[WKPhotoCollectionCell class] forCellWithReuseIdentifier:@"photoCell"];
    _collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_collectionView];
}

- (void)click_naviRight {

    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:_selectIndexArr.count];
    
    __block NSInteger totalCount = _selectIndexArr.count;
    __block NSInteger successCount = 0;
    
    for (NSNumber *index in _selectIndexArr) {
        PHAsset *asset = _asset[index.integerValue];
        if (asset.mediaType == PHAssetMediaTypeImage) {
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            option.deliveryMode = config.imageDeliveryMode;
            option.synchronous = NO;
            CGFloat width = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale;
            [_imageManager requestImageForAsset:asset targetSize:CGSizeMake(width, width) contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (result) {
                        successCount += 1;
                        [results addObject:result];
                    } else {
                        totalCount -= 1;
                    }
                    if (successCount == totalCount) {
                        [self callBackWithResults:results];
                    }
                });
            }];
        } else if (asset.mediaType == PHAssetMediaTypeVideo) {
            PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
            option.deliveryMode = config.videoDeliveryMode;
            [_imageManager requestAVAssetForVideo:asset options:option resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSURL *url = [asset valueForKey:@"URL"];
                    if (url) {
                        successCount += 1;
                        [results addObject:url];
                    } else {
                        totalCount -= 1;
                    }
                    if (successCount == totalCount) {
                        [self callBackWithResults:results];
                    }
                });
            }];
        }
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

- (void)click_backButton {
    if (_photoAuthorization != PHAuthorizationStatusAuthorized) {
        WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
        if ([config.delegate respondsToSelector:@selector(photoAlbumCancelSelect)]) {
            [config.delegate photoAlbumCancelSelect];
        }
        if (config.cancelBlock) {
            config.cancelBlock();
        }
        if (config.fromVC) {
            [self.navigationController popToViewController:config.fromVC animated:YES];
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
        [WKPhotoAlbumConfig clearReback];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _asset.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WKPhotoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoCell" forIndexPath:indexPath];
    PHAsset *asset = [_asset objectAtIndex:indexPath.row];
    cell.assetIdentifier = asset.localIdentifier;
    cell.delegate = self;
    cell.photoSelect = [_selectIndexArr containsObject:@(indexPath.row)];
    
    [_imageManager requestImageForAsset:asset targetSize:_thumSize contentMode:PHImageContentModeAspectFit options:_reqeustOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                if ([cell.assetIdentifier isEqualToString:asset.localIdentifier]) {
                    cell.thumImage = result;
                } else {
                    cell.thumImage = nil;
                }
            } else {
                cell.thumImage = nil;
            }
        });
    }];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _selectCell = [collectionView cellForItemAtIndexPath:indexPath];
    PHAsset *asset = [_asset objectAtIndex:indexPath.row];
    if (asset.mediaType == PHAssetMediaTypeAudio) return;
    
    __block WKPhotoPreviewViewController *next = [WKPhotoPreviewViewController new];
    next.previewAsset = asset;
    self.navigationController.delegate = next;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    [_imageManager requestImageForAsset:asset targetSize:[next targetSize] contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            if (asset.mediaType == PHAssetMediaTypeImage) {
                next.coverImage = result;
                self.selectCell.hidden = YES;
                
                UIGraphicsBeginImageContext(self.view.bounds.size);
                CGContextRef context = UIGraphicsGetCurrentContext();
                [self.view.layer renderInContext:context];
                UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                next.screenShotImage = image;
                
                [self.navigationController pushViewController:next animated:YES];
            } else {
                PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
                options.networkAccessAllowed = NO;
                options.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
                [_imageManager requestPlayerItemForVideo:asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (playerItem) {
                            
                            next.playerItem = playerItem;
                            next.coverImage = result;
                            self.selectCell.hidden = YES;
                            
                            UIGraphicsBeginImageContext(self.view.bounds.size);
                            CGContextRef context = UIGraphicsGetCurrentContext();
                            [self.view.layer renderInContext:context];
                            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            next.screenShotImage = image;
                            
                            [self.navigationController pushViewController:next animated:YES];
                        } else {
                            self.navigationController.delegate = nil;
                            next = nil;
                        }
                    });
                }];
            }
        } else {
            self.navigationController.delegate = nil;
            next = nil;
        }
    }];
 
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateAssets];
}

- (BOOL)photoCollectionCell:(WKPhotoCollectionCell *)photoCell didChangeToSelect:(BOOL)select {
    if (!photoCell.thumImage || _maxCount == 0) return NO;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:photoCell];
    if (!indexPath) return NO;
    
    if (select) {//选中
        if (_selectIndexArr.count == _maxCount) {
            NSIndexPath *removeIndexPath = [NSIndexPath indexPathForRow:[_selectIndexArr.firstObject integerValue] inSection:0];
            WKPhotoCollectionCell *cell = (WKPhotoCollectionCell *)[self.collectionView cellForItemAtIndexPath:removeIndexPath];
            cell.photoSelect = NO;
            [_selectIndexArr removeObjectAtIndex:0];
        }
        [_selectIndexArr addObject:@(indexPath.row)];
    } else {//取消选中
        [_selectIndexArr removeObject:@(indexPath.row)];
    }
    _rightNaviItem.hidden = (_selectIndexArr.count == 0);
    return YES;
}

#pragma mark - Update Assets
- (void)updateAssets {
    CGRect visiableRect = CGRectMake(0, self.collectionView.contentOffset.y, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    CGRect preheatRect = CGRectInset(visiableRect, 0, -0.5 * visiableRect.size.height);
    
    CGFloat delta = fabs(CGRectGetMidY(preheatRect) - CGRectGetMidY(_previousPreheatRect));
    if (delta <= self.view.bounds.size.height / 3) return;
    
    CGRect addRect = CGRectZero;
    CGRect removedRect = CGRectZero;
    if (CGRectIntersectsRect(_previousPreheatRect, preheatRect)) {//可见区域有重叠
        if (CGRectGetMaxY(preheatRect) > CGRectGetMaxY(_previousPreheatRect)) {//向下滑动
            addRect = CGRectMake(preheatRect.origin.x,
                                 CGRectGetMaxY(_previousPreheatRect),
                                 preheatRect.size.width,
                                 CGRectGetMaxY(preheatRect) - CGRectGetMaxY(_previousPreheatRect));
            if (_previousPreheatRect.origin.y < preheatRect.origin.y) {
                removedRect = CGRectMake(_previousPreheatRect.origin.x, _previousPreheatRect.origin.y, preheatRect.size.width, preheatRect.origin.y - _previousPreheatRect.origin.y);
            }
        }
        
        if (CGRectGetMaxY(preheatRect) < CGRectGetMaxY(_previousPreheatRect)) {//向上滑动
            removedRect = CGRectMake(preheatRect.origin.x,
                                     CGRectGetMaxY(preheatRect),
                                     preheatRect.size.width,
                                     CGRectGetMaxY(_previousPreheatRect) - CGRectGetMaxY(preheatRect));
            if (_previousPreheatRect.origin.y > preheatRect.origin.y) {
                addRect = CGRectMake(preheatRect.origin.x, preheatRect.origin.y, preheatRect.size.width, _previousPreheatRect.origin.y - preheatRect.origin.y);
            }
        }
    } else {//当前可见区域与之前的可见区域不重叠，则直接停止缓存之前的可见区域，开始缓存当前的可见区域
        addRect = preheatRect;
        removedRect = _previousPreheatRect;
    }
    
    NSArray *addIndexPaths    = [self indexPathForElementsInRect:addRect];
    NSArray *removeIndexPaths = [self indexPathForElementsInRect:removedRect];
    NSMutableArray *addAssets = [NSMutableArray array];
    for (NSIndexPath *index in addIndexPaths) {
        [addAssets addObject:[_asset objectAtIndex:index.row]];
    }
    NSMutableArray *removeAssets = [NSMutableArray array];
    for (NSIndexPath *index in removeIndexPaths) {
        [removeAssets addObject:[_asset objectAtIndex:index.row]];
    }
    
    [_imageManager startCachingImagesForAssets:addAssets targetSize:_thumSize contentMode:PHImageContentModeAspectFit options:_reqeustOptions];
    [_imageManager stopCachingImagesForAssets:removeAssets targetSize:_thumSize contentMode:PHImageContentModeAspectFit options:_reqeustOptions];
    
    _previousPreheatRect = preheatRect;
}

- (NSMutableArray *)indexPathForElementsInRect:(CGRect)rect {
    NSArray *layoutAttributes = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (!layoutAttributes.count) return nil;
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *att in layoutAttributes) {
        [indexPaths addObject:att.indexPath];
    }
    return indexPaths;
}

- (WKPhotoAlbumAuthorizationView *)authorizationView {
    if (!_authorizationView) {
        _authorizationView = [[WKPhotoAlbumAuthorizationView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:_authorizationView];
        
        __weak typeof(self) weakSelf = self;
        _authorizationView.jumpToSetting = ^{
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {}];
                } else {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        };
        _authorizationView.requestBlock = ^{
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (status == PHAuthorizationStatusAuthorized) {
                        [strongSelf installProperty];
                        [strongSelf insertPhotoAlbumVC];
                        [strongSelf setupManager];
                        [strongSelf setupSubviews];
                    }
                    [strongSelf.authorizationView configAuthStatus:status];
                    strongSelf->_photoAuthorization = status;
                });
            }];
        };
    }
    return _authorizationView;
}


@end
