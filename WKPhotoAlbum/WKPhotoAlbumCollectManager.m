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

@interface WKPhotoAlbumCollectManager()

@property (nonatomic, strong, readwrite) PHCachingImageManager *cacheManager;

@end

@implementation WKPhotoAlbumCollectManager {
    CGRect _previousPreheatRect;
}

- (instancetype)initWithAssets:(NSArray<PHAsset *> *)assets {
    if (!assets) {
        assets = [WKPhotoAlbumUtils readSmartAlbumInConfig];
    }
    if (self == [super init]) {
        
        _allPhotoArray = [NSMutableArray array];
        [assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            WKPhotoAlbumModel *model = [[WKPhotoAlbumModel alloc] init];
            model.collectIndex = idx;
            model.asset = obj;
            [_allPhotoArray addObject:model];
        }];
        
        _selectIndexArray = [NSMutableArray arrayWithCapacity:[WKPhotoAlbumConfig sharedConfig].maxSelectCount];
        
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
    return cancelSelectIndexPath;
}

- (void)cancelSelectIndex:(NSInteger)index {
    [_selectIndexArray removeObject:@(index)];
    NSInteger deltaIndex = _allPhotoArray[index].selectIndex;
    for (NSNumber *leftIndex in _selectIndexArray) {
        WKPhotoAlbumModel *model = _allPhotoArray[[leftIndex integerValue]];
        if (model.selectIndex > deltaIndex) {
            model.selectIndex -= 1;
        }
    }
}

- (void)reqeustCollectionImageForIndexPath:(NSIndexPath *)indexPath resultHandler:(void (^)(UIImage * _Nullable, NSDictionary * _Nullable))resultHandler {
    WKPhotoAlbumModel *model = self.allPhotoArray[indexPath.row];
    [self.cacheManager requestImageForAsset:model.asset targetSize:self.reqeustImageSize contentMode:PHImageContentModeAspectFit options:self.reqeustImageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            resultHandler(result, info);
        });
    }];
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

#pragma mark - lazy load
- (PHCachingImageManager *)cacheManager {
    if (!_cacheManager) {
        _cacheManager = [[PHCachingImageManager alloc] init];
    }
    return _cacheManager;
}

@end
