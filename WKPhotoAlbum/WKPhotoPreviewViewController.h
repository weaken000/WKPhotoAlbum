//
//  WKPhotoPreviewViewController.h
//  WKProject
//
//  Created by mac on 2018/10/11.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoPreviewViewController : UIViewController<UINavigationControllerDelegate>

@property (nonatomic, strong) PHAsset *previewAsset;
//视频播放对象
@property (nonatomic, strong) AVPlayerItem *playerItem;
//大图
@property (nonatomic, strong) UIImage *coverImage;
//图片列表的截图
@property (nonatomic, strong) UIImage *screenShotImage;
//大图展示
@property (nonatomic, strong, readonly) UIImageView *previewImageView;
//截图展示
@property (nonatomic, strong, readonly) UIImageView *screenShotImageView;

- (CGSize)targetSize;

- (CGRect)imageFrameToWindow;

@end

NS_ASSUME_NONNULL_END
