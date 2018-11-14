//
//  WKPhotoAlbum.h
//  WKProject
//
//  Created by mac on 2018/10/12.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKPhotoAlbumConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoAlbum : NSObject

/** 模态跳转 */
+ (UIViewController *)presentAlbumVC;
+ (UIViewController *)presentAlbumVCWithSelectBlock:(nullable void(^)(NSArray *result))selectBlock
                                        cancelBlock:(nullable void(^)(void))cancelBlock;

+ (void)setPhotoAlbumDelegate:(nullable id<WKPhotoAlbumDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
