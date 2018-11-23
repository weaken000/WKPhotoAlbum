//
//  WKPhotoAlbumCollectManager.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/6.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumCollectManager.h"
#import "WKPhotoAlbumUtils.h"
#import "WKPhotoAlbumConfig.h"

@implementation WKPhotoAlbumModel

- (instancetype)init {
    if (self == [super init]) {
        _collectIndex = -1;
        _selectIndex  = 0;
    }
    return self;
}

- (void)setPlayItem:(AVPlayerItem *)playItem {
    _playItem = playItem;
    if (playItem) {
        NSInteger second = CMTimeGetSeconds(playItem.asset.duration);
        NSInteger min = second / 60;
        NSInteger sec = second % 60;
        _assetDuration = [NSString stringWithFormat:@"%02zd:%02zd", min, sec];
    } else {
        _assetDuration = nil;
    }
}

@end

@interface WKPhotoAlbumCollectManager()

@property (nonatomic, strong, readwrite) PHCachingImageManager *cacheManager;

@property (nonatomic, strong) NSMutableArray<id<WKPhotoAlbumCollectManagerChanged>> *listeners;

@end

@implementation WKPhotoAlbumCollectManager {
    CGRect                _previousPreheatRect;
    PHAssetCollection    *_assetCollection;
}

- (instancetype)initWithAssets:(NSArray<PHAsset *> *)assets assetCollection:(PHAssetCollection *)assetCollection {
    if (self == [super init]) {
        
        if (!assets) {
            NSDictionary *assetDict = [WKPhotoAlbumUtils readSmartAlbumInConfig];
            assets = assetDict[@"asset"];
            assetCollection = assetDict[@"collection"];
        }
        _assetCollection = assetCollection;
        _allPhotoArray = [NSMutableArray array];
        [assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            WKPhotoAlbumModel *model = [[WKPhotoAlbumModel alloc] init];
            model.collectIndex = idx;
            model.asset = obj;
            [_allPhotoArray addObject:model];
        }];
        
        _selectIndexArray = [NSMutableArray arrayWithCapacity:[WKPhotoAlbumConfig sharedConfig].maxSelectCount];
        _currentPreviewIndex = -1;
        _isUseOrigin = NO;
    }
    return self;
}

- (NSIndexPath *)addSelectWithIndex:(NSInteger)index {
    NSIndexPath *cancelSelectIndexPath;
    if (_selectIndexArray.count == [WKPhotoAlbumConfig sharedConfig].maxSelectCount) {
        //清除第一个
        NSInteger removeIndex = [_selectIndexArray.firstObject integerValue];
        _allPhotoArray[removeIndex].selectIndex = 0;
        [_selectIndexArray removeObject:@(removeIndex)];
        cancelSelectIndexPath = [NSIndexPath indexPathForRow:removeIndex inSection:0];
        //其余索引-1
        for (NSNumber *leftIndex in _selectIndexArray) {
            _allPhotoArray[[leftIndex integerValue]].selectIndex -= 1;
        }
    }
    
    //选择索引等于最后一个+1
    _allPhotoArray[index].selectIndex = _allPhotoArray[_selectIndexArray.lastObject.integerValue].selectIndex + 1;
    [_selectIndexArray addObject:@(index)];
    
    [self triggerListenerWithKey:@"selectIndexArray" value:self.selectIndexArray];
    return cancelSelectIndexPath;
}

- (void)cancelSelectIndex:(NSInteger)index {
    [_selectIndexArray removeObject:@(index)];
    NSInteger deltaIndex = _allPhotoArray[index].selectIndex;
    _allPhotoArray[index].selectIndex = 0;
    for (NSNumber *leftIndex in _selectIndexArray) {
        WKPhotoAlbumModel *model = _allPhotoArray[[leftIndex integerValue]];
        if (model.selectIndex > deltaIndex) {
            model.selectIndex -= 1;
        }
    }
    [self triggerListenerWithKey:@"selectIndexArray" value:self.selectIndexArray];
}

- (void)addPhotoIntoCollection:(UIImage *)image completed:(void (^)(BOOL, NSString *))completed {
    __block NSString *assetId = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        assetId = [PHAssetCreationRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
            //当前已经处于相机胶卷相册，不需要再次添加
            if (_assetCollection.assetCollectionType == PHAssetCollectionTypeSmartAlbum && _assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                WKPhotoAlbumModel *model = [[WKPhotoAlbumModel alloc] init];
                model.collectIndex = _allPhotoArray.count;
                model.asset = asset;
                [_allPhotoArray addObject:model];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addSelectWithIndex:model.collectIndex];
                    completed(YES, nil);
                });
            } else {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:_assetCollection];
                    [request addAssets:@[asset]];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    if (success) {
                        PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                        WKPhotoAlbumModel *model = [[WKPhotoAlbumModel alloc] init];
                        model.collectIndex = _allPhotoArray.count;
                        model.asset = asset;
                        [_allPhotoArray addObject:model];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self addSelectWithIndex:model.collectIndex];
                            completed(YES, nil);
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completed(NO, @"添加到相册失败，请重新添加");
                        });
                    }
                }];
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completed(NO, @"添加到相册失败，请重新添加");
            });
        }
    }];
}

- (void)reqeustCollectionImageForIndexPath:(NSIndexPath *)indexPath resultHandler:(void (^)(UIImage * _Nullable, NSDictionary * _Nullable))resultHandler {
    WKPhotoAlbumModel *model = self.allPhotoArray[indexPath.row];
    
  if (model.asset.mediaType == PHAssetMediaTypeVideo) {//视频
        if (model.playItem && model.videoCaptureImage) {
            resultHandler(model.videoCaptureImage, nil);
            return;
        }
        [self.cacheManager requestImageForAsset:model.asset targetSize:self.reqeustImageSize contentMode:PHImageContentModeAspectFit options:self.reqeustImageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            model.videoCaptureImage = result;
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
            [self.cacheManager requestPlayerItemForVideo:model.asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
                model.playItem = playerItem;
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultHandler(model.videoCaptureImage, info);
                });
            }];
        }];
    } else if (model.asset.mediaType == PHAssetMediaTypeImage) {//图片
        if (model.clipImage) {
            resultHandler(model.clipImage, nil);
            return;
        }
        [self.cacheManager requestImageForAsset:model.asset targetSize:self.reqeustImageSize contentMode:PHImageContentModeAspectFit options:self.reqeustImageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultHandler(result, info);
            });
        }];
    } else {
        resultHandler(nil, nil);
    }
}

- (void)updateCacheForCollectionView:(UICollectionView *)collectionView withOffset:(CGPoint)offset {
    CGRect visiableRect = CGRectMake(collectionView.contentOffset.x,
                                     collectionView.contentOffset.y,
                                     collectionView.bounds.size.width,
                                     collectionView.bounds.size.height);
    CGRect preheatRect = CGRectInset(visiableRect, offset.x, offset.y);
    
    BOOL isVertical = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).scrollDirection == UICollectionViewScrollDirectionVertical;

    
    CGFloat delta;
    if (isVertical) {
        delta = fabs(CGRectGetMidY(preheatRect) - CGRectGetMidY(_previousPreheatRect));
    } else {
        delta = fabs(CGRectGetMidX(preheatRect) - CGRectGetMidX(_previousPreheatRect));
    }
    if ((isVertical && delta < collectionView.bounds.size.height / 3) || (!isVertical && delta < collectionView.bounds.size.width / 3)) return;
    
    CGRect addRect = CGRectZero;
    CGRect removedRect = CGRectZero;
    if (CGRectIntersectsRect(_previousPreheatRect, preheatRect)) {//可见区域有重叠
        if ((CGRectGetMaxY(preheatRect) > CGRectGetMaxY(_previousPreheatRect))) {//向下滑
            addRect = CGRectMake(_previousPreheatRect.origin.x,
                                 CGRectGetMaxY(_previousPreheatRect),
                                 preheatRect.size.width,
                                 CGRectGetMaxY(preheatRect) - CGRectGetMaxY(_previousPreheatRect));
            if (_previousPreheatRect.origin.y < preheatRect.origin.y) {
                removedRect = CGRectMake(_previousPreheatRect.origin.x, _previousPreheatRect.origin.y, preheatRect.size.width, preheatRect.origin.y - _previousPreheatRect.origin.y);
            }
            return;
        }
        
        if (CGRectGetMaxX(preheatRect) > CGRectGetMaxX(_previousPreheatRect)) {//向右滑
            addRect = CGRectMake(CGRectGetMaxX(_previousPreheatRect),
                                 CGRectGetMinY(_previousPreheatRect),
                                 CGRectGetMaxX(preheatRect) - CGRectGetMaxX(_previousPreheatRect),
                                 CGRectGetMaxY(_previousPreheatRect));
            if (_previousPreheatRect.origin.x < preheatRect.origin.x) {
                removedRect = CGRectMake(_previousPreheatRect.origin.x,
                                         _previousPreheatRect.origin.y,
                                         preheatRect.origin.x - _previousPreheatRect.origin.x,
                                         CGRectGetMaxY(_previousPreheatRect));
            }
            return;
        }

        
        if (CGRectGetMaxY(preheatRect) < CGRectGetMaxY(_previousPreheatRect)) {//向上滑动
            removedRect = CGRectMake(preheatRect.origin.x,
                                     CGRectGetMaxY(preheatRect),
                                     preheatRect.size.width,
                                     CGRectGetMaxY(_previousPreheatRect) - CGRectGetMaxY(preheatRect));
            if (_previousPreheatRect.origin.y > preheatRect.origin.y) {
                addRect = CGRectMake(preheatRect.origin.x,
                                     preheatRect.origin.y,
                                     preheatRect.size.width,
                                     _previousPreheatRect.origin.y - preheatRect.origin.y);
            }
            return;
        }
        
        if (CGRectGetMaxX(preheatRect) < CGRectGetMaxX(_previousPreheatRect)) {//向左滑动
            removedRect = CGRectMake(CGRectGetMaxX(preheatRect),
                                     _previousPreheatRect.origin.y,
                                     CGRectGetMaxX(preheatRect) - CGRectGetMaxX(_previousPreheatRect),
                                     _previousPreheatRect.size.height);
            if (_previousPreheatRect.origin.x > preheatRect.origin.x) {
                addRect = CGRectMake(preheatRect.origin.x,
                                     preheatRect.origin.y,
                                     _previousPreheatRect.origin.x - preheatRect.origin.x,
                                     preheatRect.size.height);
            }
            return;
        }
    } else {//当前可见区域与之前的可见区域不重叠，则直接停止缓存之前的可见区域，开始缓存当前的可见区域
        addRect = preheatRect;
        removedRect = _previousPreheatRect;
    }
    
    NSArray *addIndexPaths    = [self indexPathForElementsInRect:addRect forCollectionView:collectionView];
    NSArray *removeIndexPaths = [self indexPathForElementsInRect:removedRect forCollectionView:collectionView];
    NSMutableArray *addAssets = [NSMutableArray array];
    for (NSIndexPath *index in addIndexPaths) {
        [addAssets addObject:self.allPhotoArray[index.row].asset];
    }
    NSMutableArray *removeAssets = [NSMutableArray array];
    for (NSIndexPath *index in removeIndexPaths) {
        [removeAssets addObject:self.allPhotoArray[index.row].asset];
    }
    
    [self.cacheManager startCachingImagesForAssets:addAssets targetSize:self.reqeustImageSize contentMode:PHImageContentModeAspectFit options:self.reqeustImageOptions];
    [self.cacheManager stopCachingImagesForAssets:removeAssets targetSize:self.reqeustImageSize contentMode:PHImageContentModeAspectFit options:self.reqeustImageOptions];
    
    _previousPreheatRect = preheatRect;
}

- (NSMutableArray *)indexPathForElementsInRect:(CGRect)rect forCollectionView:(UICollectionView *)collectionView {
    NSArray *layoutAttributes = [collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (!layoutAttributes.count) return nil;
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *att in layoutAttributes) {
        [indexPaths addObject:att.indexPath];
    }
    return indexPaths;
}

- (void)addChangedListener:(id<WKPhotoAlbumCollectManagerChanged>)listener {
    if (!listener) {
        NSLog(@"listener can be nil");
        return;
    }
    
    if (![listener respondsToSelector:@selector(inListening)] && ![listener respondsToSelector:@selector(managerValueChangedForKey:withValue:)]) {
        NSLog(@"listener should implement delegate methods");
        return;
    }
    
    [self.listeners addObject:listener];
    if ([listener inListening]) {
        [listener managerValueChangedForKey:@"selectIndexArray" withValue:self.selectIndexArray];
        [listener managerValueChangedForKey:@"isUseOrigin" withValue:@(self.isUseOrigin)];
        if (_currentPreviewIndex >= 0) {
            [listener managerValueChangedForKey:@"currentPreviewIndex" withValue:@(self.currentPreviewIndex)];
        }
    }
}

- (void)removeListener:(id<WKPhotoAlbumCollectManagerChanged>)listener {
    if (!listener) return;
    [self.listeners removeObject:listener];
}

- (void)removeAllListener {
    [self.listeners removeAllObjects];
}

- (void)triggerListenerWithKey:(NSString *)key value:(id)value {
    for (id<WKPhotoAlbumCollectManagerChanged> listener in self.listeners) {
        if ([listener inListening]) {//
            [listener managerValueChangedForKey:key withValue:value];
        }
    }
}

- (void)triggerSelectArrayWhileClipImage {
    [self triggerListenerWithKey:@"selectIndexArray" value:self.selectIndexArray];
}

- (void)requestSelectImage:(void (^)(NSArray * _Nullable))selectImages {
    NSMutableArray *resultArr = [NSMutableArray arrayWithCapacity:self.selectIndexArray.count];
    for (NSNumber *index in self.selectIndexArray) {
        WKPhotoAlbumModel *model = self.allPhotoArray[index.integerValue];
        if (model.asset.mediaType == PHAssetMediaTypeImage) {
            if (model.clipImage) {
                [resultArr addObject:model.clipImage];
                if (resultArr.count == self.selectIndexArray.count) {
                    selectImages(resultArr);
                }
            } else {
                CGFloat scale = [UIScreen mainScreen].scale;
                CGSize targetSize = CGSizeMake([UIScreen mainScreen].bounds.size.width * scale, ([UIScreen mainScreen].bounds.size.height * scale));
                PHImageRequestOptions *options;
                if (self.isUseOrigin) {
                    options = [[PHImageRequestOptions alloc] init];
                    options.resizeMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                } else {
                    options = self.reqeustImageOptions;
                }
                [self.cacheManager requestImageForAsset:model.asset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (result) {
                            [resultArr addObject:result];
                            if (resultArr.count == self.selectIndexArray.count) {
                                selectImages(resultArr);
                            }
                        }
                    });
                }];
            }
        } else {
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            if (self.isUseOrigin) {
                options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
            } else {
                options.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
            }
            [self.cacheManager requestAVAssetForVideo:model.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (asset) {
                        NSURL *url = [asset valueForKey:@"URL"];
                        if (url) {
                            [resultArr addObject:url];
                            if (resultArr.count == self.selectIndexArray.count) {
                                selectImages(resultArr);
                            }
                        }
                    }
                });
            }];
        }
    }
}

#pragma mark - setter
- (void)setIsUseOrigin:(BOOL)isUseOrigin {
    if (_isUseOrigin != isUseOrigin) {
        _isUseOrigin = isUseOrigin;
        [self triggerListenerWithKey:@"isUseOrigin" value:@(_isUseOrigin)];
    }
}
- (void)setCurrentPreviewIndex:(NSInteger)currentPreviewIndex {
    if (_currentPreviewIndex != currentPreviewIndex) {
        _currentPreviewIndex = currentPreviewIndex;
        [self triggerListenerWithKey:@"currentPreviewIndex" value:@(_currentPreviewIndex)];
    }
}

#pragma mark - lazy load
- (PHCachingImageManager *)cacheManager {
    if (!_cacheManager) {
        _cacheManager = [[PHCachingImageManager alloc] init];
    }
    return _cacheManager;
}

- (NSMutableArray<id<WKPhotoAlbumCollectManagerChanged>> *)listeners {
    if (!_listeners) {
        _listeners = [NSMutableArray array];
    }
    return _listeners;
}

@end
