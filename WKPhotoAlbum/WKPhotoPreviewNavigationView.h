//
//  WKPhotoPreviewNavigationView.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/7.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoPreviewNavigationView : UIView

@property (nonatomic, assign, readonly) BOOL isInEditMode;

- (instancetype)initWithTarget:(id)target
                    leftAction:(SEL)leftAction
                   rightAction:(SEL)rightAction;

- (void)toEditMode:(BOOL)editMode;

- (void)configSelectIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
