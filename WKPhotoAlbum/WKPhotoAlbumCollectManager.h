//
//  WKPhotoAlbumCollectManager.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/6.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WKPhotoAlbumCollectManagerChanged <NSObject>

- (void)managerValueChangedForKey:(NSString *)key withValue:(id)value;

- (BOOL)inListening;

@end

@interface WKPhotoAlbumModel : NSObject

@property (nonatomic, assign) NSInteger collectIndex;

@property (nonatomic, assign) NSInteger selectIndex;

@property (nonatomic, strong, nullable) UIImage *resultImage;

@property (nonatomic, strong, nullable) PHAsset *asset;

@end

@interface WKPhotoAlbumCollectManager : NSObject
//当前相册所有图片
@property (nonatomic, strong, readonly) NSMutableArray<WKPhotoAlbumModel *> *allPhotoArray;
//选择的图片索引
@property (nonatomic, strong, readonly) NSMutableArray<NSNumber *> *selectIndexArray;
//当前展示的索引
@property (nonatomic, assign) NSInteger currentPreviewIndex;
//图片请求大小
@property (nonatomic, assign) CGSize reqeustImageSize;

@property (nonatomic, strong) PHImageRequestOptions *reqeustImageOptions;
//图片缓存
@property (nonatomic, strong, readonly) PHCachingImageManager *cacheManager;

@property (nonatomic, assign) BOOL isUseOrigin;

- (instancetype)initWithAssets:(NSArray<PHAsset *> *)assets;

- (NSIndexPath *)addSelectWithIndex:(NSInteger)index;

- (void)cancelSelectIndex:(NSInteger)index;

- (void)updateCacheForCollectionView:(UICollectionView *)collectionView withOffset:(CGPoint)offset;

- (void)reqeustCollectionImageForIndexPath:(NSIndexPath *)indexPath
                   resultHandler:(void (^)(UIImage * __nullable result, NSDictionary * __nullable info))resultHandler;

- (void)addChangedListener:(id<WKPhotoAlbumCollectManagerChanged>)listener;

- (void)removeListener:(id<WKPhotoAlbumCollectManagerChanged>)listener;

@end

NS_ASSUME_NONNULL_END
