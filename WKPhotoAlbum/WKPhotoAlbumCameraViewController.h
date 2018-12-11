//
//  WKPhotoAlbumCameraViewController.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/23.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WKPhotoAlbumCameraViewController;

@protocol WKPhotoAlbumCameraViewControllerDelegate <NSObject>

- (void)captureView:(WKPhotoAlbumCameraViewController *)captureView didCreateResult:(id)result;

@end

@interface WKPhotoAlbumCameraViewController : UIViewController

@property (nonatomic, weak) id<WKPhotoAlbumCameraViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
