//
//  WKPhotoAlbumNormalNaviBar.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/7.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoAlbumNormalNaviBar : UIView

@property (nonatomic, copy, nullable) NSString *title;

- (instancetype)initWithTarget:(id)target
                    popAction:(nullable SEL)popAction
                   cancelAction:(nullable SEL)cancelAction;

- (instancetype)initWithTarget:(id)target
                     popAction:(nullable SEL)popAction
               takePhotoAction:(nullable SEL)takePhotoAction
                  cancelAction:(nullable SEL)cancelAction;

- (void)hiddenCameraButton:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
