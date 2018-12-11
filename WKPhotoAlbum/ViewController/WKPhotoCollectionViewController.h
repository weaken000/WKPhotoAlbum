//
//  WKPhotoCollectionViewController.h
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class WKPhotoAlbumPreviewCell;

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoCollectionViewController : UIViewController

@property (nonatomic, strong) NSDictionary *assetDict;

- (WKPhotoAlbumPreviewCell *)cellAtManagerPreviewIndex;

@end

NS_ASSUME_NONNULL_END
