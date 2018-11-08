//
//  WKPhotoAlbumCollectManager.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/6.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "WKPhotoAlbumModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoAlbumCollectManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<WKPhotoAlbumModel *> *allPhotoArray;

@property (nonatomic, strong, readonly) NSMutableArray<NSNumber *> *selectIndexArray;

@property (nonatomic, assign) NSInteger previewFromIndex;

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



@end

NS_ASSUME_NONNULL_END
