//
//  WKPhotoAlbumSelectButton.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/7.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoAlbumSelectButton : UIButton

@property (nonatomic, assign) NSInteger selectIndex;

- (void)showAnimation;

@end

NS_ASSUME_NONNULL_END
