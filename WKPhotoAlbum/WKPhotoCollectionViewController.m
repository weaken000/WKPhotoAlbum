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
#import "WKPhotoAlbumCameraViewController.h"

#import "WKPhotoAlbumPreviewCell.h"
#import "WKPhotoCollectBottomView.h"
#import "WKPhotoAlbumNormalNaviBar.h"
#import "WKPhotoAlbumAuthorizationView.h"

#import "WKPhotoAlbumConfig.h"
#import "WKPhotoAlbumCollectManager.h"
#import "WKPhotoAlbumUtils.h"

@interface WKPhotoCollectionViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
WKPhotoAlbumPreviewCellDelegate,
WKPhotoCollectBottomViewDelegate,
WKPhotoAlbumCollectManagerChanged,
WKPhotoAlbumCameraViewControllerDelegate
>

@property (nonatomic, strong) UICollectionView              *collectionView;

@property (nonatomic, strong) WKPhotoAlbumAuthorizationView *authorizationView;

@property (nonatomic, strong) WKPhotoCollectBottomView      *actionView;

@property (nonatomic, strong) WKPhotoAlbumCollectManager    *manager;

@property (nonatomic, strong) WKPhotoAlbumNormalNaviBar     *navigationView;

@end

@implementation WKPhotoCollectionViewController {
    NSInteger             _maxCount;
    NSUInteger            _numberOfLine;
    CGFloat               _lineSpace;
}

#pragma mark - life circle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.extendedLayoutIncludesOpaqueBars = YES;

    _numberOfLine = [WKPhotoAlbumConfig sharedConfig].numberOfLine;
    _lineSpace    = [WKPhotoAlbumConfig sharedConfig].lineSpace;
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
        CGFloat itemW = (self.view.bounds.size.width - (_numberOfLine + 1) * _lineSpace - 1) / _numberOfLine;
        _manager.reqeustImageSize = CGSizeMake(itemW * [UIScreen mainScreen].scale,
                                               itemW * [UIScreen mainScreen].scale);
    }
}

#pragma mark - initializeInstall
- (void)requestAuthorization {
    __weak typeof(self) weakSelf = self;
    [self.authorizationView requestAuthorizationForType:WKAuthorizationTypeAlbum handle:^(PHAuthorizationStatus albumStatus, AVAuthorizationStatus avStatus, AVAuthorizationStatus micStatus) {
        if (albumStatus == PHAuthorizationStatusAuthorized) {//已获得权限
            [weakSelf installManager];
            [weakSelf setupSubviews];
        }
    }];
}

#pragma mark -
- (void)installManager {
    
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    NSArray<PHAsset *> *asset;
    PHAssetCollection *assetCollection;
    //获取资源
    if (self.assetDict) {
        assetCollection = self.assetDict[@"collection"];
        self.navigationView.title = assetCollection.localizedTitle?:@"照片";
        asset = self.assetDict[@"asset"];
    } else {
        self.navigationView.title = @"所有照片";
    }
    _manager = [[WKPhotoAlbumCollectManager alloc] initWithAssets:asset assetCollection:assetCollection];
    PHImageRequestOptions *reqeustOptions = [[PHImageRequestOptions alloc] init];
    reqeustOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    reqeustOptions.synchronous = NO;
    _manager.reqeustImageOptions = reqeustOptions;
    [_manager.cacheManager stopCachingImagesForAllAssets];
    [_manager addChangedListener:self];
    
    _maxCount = config.maxSelectCount;
}

- (void)setupSubviews {
    
    CGFloat itemW = (self.view.bounds.size.width - (_numberOfLine + 1) * _lineSpace - 1) / _numberOfLine;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.itemSize = CGSizeMake(itemW, itemW);
    layout.minimumLineSpacing = _lineSpace;
    layout.minimumInteritemSpacing = _lineSpace;
    layout.sectionInset = UIEdgeInsetsMake(_lineSpace, _lineSpace, _lineSpace, _lineSpace);
    
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
    if (self.authorizationView.albumStatus != PHAuthorizationStatusAuthorized) {
        [self click_cancelButton];
        return;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
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

- (void)click_takePhotoButton {
    WKPhotoAlbumCameraViewController *next = [[WKPhotoAlbumCameraViewController alloc] init];
    next.delegate = self;
    [self.navigationController pushViewController:next animated:YES];
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
        NSArray<NSIndexPath *> *visiableIndexs = [self.collectionView indexPathsForVisibleItems];
        for (NSIndexPath *indexPath in visiableIndexs) {
            WKPhotoAlbumPreviewCell *cell = (WKPhotoAlbumPreviewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            cell.selectIndex = 0;
            if (self.manager.allPhotoArray[indexPath.row].clipImage) {
                cell.image = self.manager.allPhotoArray[indexPath.row].clipImage;
            }
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
    __weak typeof(self) weakSelf = self;
    [self.manager requestSelectImage:^(NSArray * _Nullable images) {
        WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
        if ([config.delegate respondsToSelector:@selector(photoAlbumDidSelectResult:)]) {
            [config.delegate photoAlbumDidSelectResult:images];
        }
        if (config.selectBlock) {
            config.selectBlock(images);
        }
        [weakSelf popAndClearData];
    }];
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.manager.allPhotoArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WKPhotoAlbumPreviewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoCell" forIndexPath:indexPath];
    WKPhotoAlbumModel *model = [self.manager.allPhotoArray objectAtIndex:indexPath.row];
    cell.cellType  = WKPhotoAlbumCellTypeCollect;
    cell.albumInfo = model;
    cell.delegate  = self;
    cell.selectIndex = model.selectIndex;
    __weak typeof(cell) weakCell = cell;
    __weak typeof(model) weakModel = model;
    [self.manager reqeustCollectionImageForIndexPath:indexPath resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if ([weakCell.albumInfo.asset.localIdentifier isEqualToString:weakModel.asset.localIdentifier] && result) {
            weakCell.image = result;
        } else {
            weakCell.image = nil;
        }
    }];
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

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    __weak typeof(self) weakSelf = self;
    [self.manager addPhotoIntoCollection:image completed:^(BOOL success, NSString * _Nonnull errorMsg) {
        if (success) {
            [weakSelf.collectionView reloadData];
        }
    }];
}

#pragma mark - lazy load
- (WKPhotoAlbumAuthorizationView *)authorizationView {
    if (!_authorizationView) {
        _authorizationView = [[WKPhotoAlbumAuthorizationView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:_authorizationView];
        __weak typeof(self) weakSelf = self;
        _authorizationView.authChanged = ^(PHAuthorizationStatus albumStatus, AVAuthorizationStatus cameraStatus, AVAuthorizationStatus micStatus) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf installManager];
            [strongSelf setupSubviews];
        };
    }
    return _authorizationView;
}

- (WKPhotoAlbumNormalNaviBar *)navigationView {
    if (!_navigationView) {
        if ([WKPhotoAlbumConfig sharedConfig].allowTakePicture) {
            _navigationView = [[WKPhotoAlbumNormalNaviBar alloc] initWithTarget:self popAction:@selector(click_backButton) takePhotoAction:@selector(click_takePhotoButton) cancelAction:@selector(click_cancelButton)];
        } else {
            _navigationView = [[WKPhotoAlbumNormalNaviBar alloc] initWithTarget:self popAction:@selector(click_backButton) cancelAction:@selector(click_cancelButton)];
        }
        [self.view addSubview:_navigationView];
    }
    return _navigationView;
}

@end
