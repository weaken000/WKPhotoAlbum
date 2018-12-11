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
//裁剪后的图片
@property (nonatomic, strong, nullable) UIImage *clipImage;

@property (nonatomic, strong, nullable) PHAsset *asset;

@property (nonatomic, strong, nullable) AVPlayerItem *playItem;
//播放资源的封面图
@property (nonatomic, strong, nullable) UIImage *videoCaptureImage;

@property (nonatomic, copy  , readonly, nullable) NSString *assetDuration;

@property (nonatomic, assign) BOOL isPlaying;

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

- (instancetype)initWithAssets:(nullable NSArray<PHAsset *> *)assets assetCollection:(nullable PHAssetCollection *)assetCollection;

- (NSIndexPath *)addSelectWithIndex:(NSInteger)index;

- (void)cancelSelectIndex:(NSInteger)index;
//往当前相册中添加图片、视频
- (void)addPhotoIntoCollection:(id)result completed:(void (^)(BOOL success, NSString * _Nullable errorMsg))completed;

- (void)updateCacheForCollectionView:(UICollectionView *)collectionView withOffset:(CGPoint)offset;

- (PHImageRequestID)reqeustCollectionImageForIndexPath:(NSIndexPath *)indexPath
                                         resultHandler:(void (^)(UIImage * __nullable result, NSDictionary * __nullable info))resultHandler;

- (void)addChangedListener:(id<WKPhotoAlbumCollectManagerChanged>)listener;

- (void)removeListener:(id<WKPhotoAlbumCollectManagerChanged>)listener;

- (void)removeAllListener;

- (void)requestSelectImage:(void (^)(NSArray * __nullable images))selectImages;

- (void)triggerSelectArrayWhileClipImage;

@end

NS_ASSUME_NONNULL_END
