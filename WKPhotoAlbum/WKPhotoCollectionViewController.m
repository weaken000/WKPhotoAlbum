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

#import "WKPhotoAlbumPreviewCell.h"
#import "WKPhotoCollectBottomView.h"
#import "WKPhotoAlbumNormalNaviBar.h"

#import "WKPhotoAlbumUtils.h"
#import "WKPhotoAlbumConfig.h"
#import "WKPhotoAlbumCollectManager.h"

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

@interface WKPhotoCollectionViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
WKPhotoAlbumPreviewCellDelegate,
WKPhotoCollectBottomViewDelegate,
WKPhotoAlbumCollectManagerChanged
>

@property (nonatomic, strong) UICollectionView              *collectionView;

@property (nonatomic, strong) WKPhotoAlbumAuthorizationView *authorizationView;

@property (nonatomic, strong) WKPhotoCollectBottomView      *actionView;

@property (nonatomic, strong) WKPhotoAlbumCollectManager    *manager;

@property (nonatomic, strong) WKPhotoAlbumNormalNaviBar     *navigationView;

@end

@implementation WKPhotoCollectionViewController {
    NSInteger                 _maxCount;
    PHAuthorizationStatus     _photoAuthorization;
}

#pragma mark - life circle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.extendedLayoutIncludesOpaqueBars = YES;

    self.navigationView.hidden = NO;
    [self requestAuthorization];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutSubiews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.manager.reqeustImageSize.width != 0) {
        CGFloat numberOfLine = 4;
        CGFloat itemMargin = 1.0;
        CGFloat itemW = (self.view.bounds.size.width - (numberOfLine + 1) * itemMargin - 1) / numberOfLine;
        _manager.reqeustImageSize = CGSizeMake(itemW * [UIScreen mainScreen].scale,
                                               itemW * [UIScreen mainScreen].scale);
    }
}

#pragma mark - initializeInstall
- (void)requestAuthorization {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    _photoAuthorization = status;
    if (status == PHAuthorizationStatusAuthorized) {//已获得权限
        [self installManager];
        [self setupSubviews];
    } else {
        [self.authorizationView configAuthStatus:status];
    }
}

#pragma mark -
- (void)installManager {
    
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    NSArray<PHAsset *> *asset;
    //获取资源
    if (self.assetDict) {
        PHAssetCollection *collection = self.assetDict[@"collection"];
        self.navigationView.title = collection.localizedTitle?:@"照片";
        asset = self.assetDict[@"asset"];
    } else {
        self.navigationView.title = @"所有照片";
    }
    _manager = [[WKPhotoAlbumCollectManager alloc] initWithAssets:asset];
    PHImageRequestOptions *reqeustOptions = [[PHImageRequestOptions alloc] init];
    reqeustOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    reqeustOptions.synchronous = NO;
    _manager.reqeustImageOptions = reqeustOptions;
    [_manager.cacheManager stopCachingImagesForAllAssets];
    [_manager addChangedListener:self];
    
    _maxCount = config.maxSelectCount;
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
    
    _manager.reqeustImageSize = CGSizeMake(itemW * [UIScreen mainScreen].scale,
                                           itemW * [UIScreen mainScreen].scale);
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.showsVerticalScrollIndicator = NO;
    [_collectionView registerClass:[WKPhotoAlbumPreviewCell class] forCellWithReuseIdentifier:@"photoCell"];
    if (@available(iOS 11.0, *)) {
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self.view addSubview:_collectionView];
    
    _actionView = [[WKPhotoCollectBottomView alloc] initWithFrame:CGRectZero useForCollectVC:YES];
    _actionView.delegate = self;
    _actionView.manager = self.manager;
    [self.view addSubview:_actionView];
    
    [self.view bringSubviewToFront:self.navigationView];
}

- (void)layoutSubiews {
    CGFloat actionH = kActionViewActionHeight;
    CGFloat topInsetH = [UIApplication sharedApplication].statusBarFrame.size.height + 44.0;
    if (@available(iOS 11.0, *)) {
        actionH += self.view.safeAreaInsets.bottom;
    }
    _collectionView.frame = self.view.bounds;
    _collectionView.contentInset = UIEdgeInsetsMake(topInsetH, 0, actionH, 0);
    _actionView.frame = CGRectMake(0, self.view.frame.size.height - actionH, self.view.frame.size.width, actionH);
}

#pragma mark - action
- (void)click_backButton {
    if (_photoAuthorization != PHAuthorizationStatusAuthorized) {
        [self click_cancelButton];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [self.manager removeListener:(id<WKPhotoAlbumCollectManagerChanged>)self.actionView];
    [self.manager removeListener:self];
}

- (void)click_cancelButton {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    if ([config.delegate respondsToSelector:@selector(photoAlbumCancelSelect)]) {
        [config.delegate photoAlbumCancelSelect];
    }
    if (config.cancelBlock) {
        config.cancelBlock();
    }
    [self popAndClearData];
}

- (void)pushToPreviewWithIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        indexPath = [NSIndexPath indexPathForRow:self.manager.selectIndexArray.firstObject.integerValue inSection:0];
    }
    WKPhotoAlbumModel *model = [self.manager.allPhotoArray objectAtIndex:indexPath.row];
    if (model.asset.mediaType == PHAssetMediaTypeAudio) return;
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.manager.currentPreviewIndex = indexPath.row;
    WKPhotoPreviewViewController *next = [[WKPhotoPreviewViewController alloc] init];
    self.navigationController.delegate = next;
    next.manager = self.manager;
    next.screenShotImage = image;
    [self.navigationController pushViewController:next animated:YES];
}

- (void)popAndClearData {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [WKPhotoAlbumConfig clearReback];
    [self.manager removeListener:(id<WKPhotoAlbumCollectManagerChanged>)self.actionView];
    [self.manager removeListener:self];
}

- (WKPhotoAlbumPreviewCell *)cellAtManagerPreviewIndex {
    return (WKPhotoAlbumPreviewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.manager.currentPreviewIndex inSection:0]];
}

#pragma mark - WKPhotoAlbumCollectManagerChanged
- (BOOL)inListening {//跳转到预览时开启监听
    return self.navigationController.topViewController != self;
}
- (void)managerValueChangedForKey:(NSString *)key withValue:(id)value {
    if ([key isEqualToString:@"selectIndexArray"]) {
        NSArray<WKPhotoAlbumPreviewCell *> *cells = [self.collectionView visibleCells];
        for (WKPhotoAlbumPreviewCell *cell in cells) {
            cell.selectIndex = 0;
        }
        for (NSNumber *selectIndex in self.manager.selectIndexArray) {
            WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:selectIndex.integerValue inSection:0]];
            cell.selectIndex = self.manager.allPhotoArray[selectIndex.integerValue].selectIndex;
        }
    }
}

#pragma mark - WKPhotoCollectBottomViewDelegate
- (void)actionViewDidClickPreOrEditView:(WKPhotoCollectBottomView *)actionView {
    
    CGRect visiableRect = CGRectMake(0, self.collectionView.contentOffset.y + self.collectionView.contentInset.top, self.collectionView.frame.size.width, self.collectionView.frame.size.height - self.collectionView.contentInset.bottom - self.collectionView.contentInset.top);
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttributes = [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:visiableRect];
    self.manager.currentPreviewIndex = layoutAttributes.firstObject.indexPath.row;

    for (NSNumber *index in self.manager.selectIndexArray) {
        if (index.integerValue < layoutAttributes.firstObject.indexPath.row || index.integerValue > layoutAttributes.lastObject.indexPath.row) {
            continue;
        }
        self.manager.currentPreviewIndex = index.integerValue;
        break;
    }

    [self pushToPreviewWithIndexPath:[NSIndexPath indexPathForRow:self.manager.currentPreviewIndex inSection:0]];
}
- (void)actionViewDidClickUseOrigin:(WKPhotoCollectBottomView *)actionView useOrigin:(BOOL)useOrigin {
    self.manager.isUseOrigin = useOrigin;
}

- (void)actionViewDidClickSelect:(WKPhotoCollectBottomView *)actionView {
    [self.manager requestSelectImage:^(NSArray * _Nullable images) {
        WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
        if ([config.delegate respondsToSelector:@selector(photoAlbumDidSelectResult:)]) {
            [config.delegate photoAlbumDidSelectResult:images];
        }
        if (config.selectBlock) {
            config.selectBlock(images);
        }
        [self popAndClearData];
    }];
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.manager.allPhotoArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WKPhotoAlbumPreviewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoCell" forIndexPath:indexPath];
    WKPhotoAlbumModel *model = [self.manager.allPhotoArray objectAtIndex:indexPath.row];
    cell.cellType = WKPhotoAlbumCellTypeCollect;
    cell.albumInfo = model;
    cell.delegate = self;
    cell.selectIndex = model.selectIndex;
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self pushToPreviewWithIndexPath:indexPath];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.manager updateCacheForCollectionView:self.collectionView
                                    withOffset:CGPointMake(0, -0.5 * self.collectionView.bounds.size.height)];
}

#pragma mark - WKPhotoAlbumPreviewCellDelegate
- (BOOL)photoPreviewCell:(WKPhotoAlbumPreviewCell *)previewCell didChangeToSelect:(BOOL)select {
    if (!previewCell.image || _maxCount == 0) return NO;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:previewCell];
    if (!indexPath) return NO;
    
    if (select) {//选中
        NSIndexPath *cancelIndex = [self.manager addSelectWithIndex:indexPath.row];
        if (cancelIndex) {
            WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.collectionView cellForItemAtIndexPath:cancelIndex];
            cell.selectIndex = 0;
        }
    } else {//取消选中
        [self.manager cancelSelectIndex:indexPath.row];
        if (![self.manager.selectIndexArray containsObject:@(indexPath.row)]) {
            previewCell.selectIndex = 0;
        }
    }
    
    for (NSNumber *selectIndex in self.manager.selectIndexArray) {
        NSIndexPath *selectIndexPath = [NSIndexPath indexPathForRow:selectIndex.integerValue inSection:0];
        WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.collectionView cellForItemAtIndexPath:selectIndexPath];
        cell.selectIndex = self.manager.allPhotoArray[selectIndexPath.row].selectIndex;
    }
    return YES;
}

#pragma mark - lazy load
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
                        [strongSelf installManager];
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

- (WKPhotoAlbumNormalNaviBar *)navigationView {
    if (!_navigationView) {
        _navigationView = [[WKPhotoAlbumNormalNaviBar alloc] initWithTarget:self popAction:@selector(click_backButton) cancelAction:@selector(click_cancelButton)];
        [self.view addSubview:_navigationView];
    }
    return _navigationView;
}

@end
