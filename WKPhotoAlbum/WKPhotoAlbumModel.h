//
//  WKPhotoAlbumModel.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/6.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoAlbumModel : NSObject

@property (nonatomic, assign) NSInteger collectIndex;

@property (nonatomic, assign) NSInteger selectIndex;

@property (nonatomic, strong, nullable) UIImage *resultImage;

@property (nonatomic, strong, nullable) PHAsset *asset;

@end

NS_ASSUME_NONNULL_END
