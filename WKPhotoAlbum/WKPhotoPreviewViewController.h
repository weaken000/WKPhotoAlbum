//
//  WKPhotoPreviewViewController.h
//  WKProject
//
//  Created by mac on 2018/10/11.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "WKPhotoAlbumCollectManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoPreviewViewController : UIViewController<UINavigationControllerDelegate>
//图片列表的截图
@property (nonatomic, strong) UIImage *screenShotImage;
//截图展示
@property (nonatomic, strong, readonly) UIImageView *screenShotImageView;

@property (nonatomic, strong, readonly) UIImageView *dismissPreViewImageView;

@property (nonatomic, strong) WKPhotoAlbumCollectManager *manager;

- (CGSize)targetSize;

- (CGRect)dismissRect;

@end

NS_ASSUME_NONNULL_END
