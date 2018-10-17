//
//  WKPhotoReadTool.h
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoAlbumUtils : NSObject

+ (PHImageRequestID)readImageByAsset:(PHAsset *)asset
                                size:(CGSize)size
                        deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode
                        contentModel:(PHImageContentMode)contentModel
                         synchronous:(BOOL)synchronous
                            complete:(nullable void (^)(UIImage * _Nullable image))complete;

+ (NSMutableArray<PHAsset *> *)readSmartAlbumInConfig;


@end

NS_ASSUME_NONNULL_END
