//
//  WKPhotoReadTool.m
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumUtils.h"
#import "WKPhotoAlbumConfig.h"

@implementation WKPhotoAlbumUtils

+ (PHImageRequestID)readImageByAsset:(PHAsset *)asset size:(CGSize)size deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode contentModel:(PHImageContentMode)contentModel synchronous:(BOOL)synchronous complete:(void (^)(UIImage * _Nullable))complete {
    
    PHImageRequestOptions *imageOptions = [PHImageRequestOptions new];
    imageOptions.deliveryMode = deliveryMode;
    imageOptions.synchronous = synchronous;

    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:contentModel options:imageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (!synchronous) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result) {
                    complete(result);
                } else {
                    complete(nil);
                }
            });
        } else {
            if (result) {
                complete(result);
            } else {
                complete(nil);
            }
        }
    }];
}

+ (NSMutableArray<PHAsset *> *)readSmartAlbumInConfig {
    
    PHFetchResult<PHAssetCollection *> *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        PHFetchResult *asset = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        if (asset.count == 0 || !asset) continue;
        NSMutableArray *assetArr = [NSMutableArray array];
        WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
        [asset enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.mediaType == PHAssetMediaTypeVideo && config.isIncludeVideo) {
                [assetArr addObject:obj];
            }
            if (obj.mediaType == PHAssetMediaTypeImage && config.isIncludeImage) {
                [assetArr addObject:obj];
            }
            if (obj.mediaType == PHAssetMediaTypeAudio && config.isIncludeAudio) {
                [assetArr addObject:obj];
            }
        }];
        return assetArr;
    }
    return nil;
}

+ (UIColor *)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a {
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a];
}

+ (UIImage *)createImageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
