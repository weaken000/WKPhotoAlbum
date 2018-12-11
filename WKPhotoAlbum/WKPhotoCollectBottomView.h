//
//  WKPhotoCollectBottomView.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/6.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WKPhotoCollectBottomView, WKPhotoAlbumCollectManager;


NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN CGFloat const kActionViewPreViewHeight;
UIKIT_EXTERN CGFloat const kActionViewActionHeight;

@protocol WKPhotoCollectBottomViewDelegate <NSObject>

@optional

- (void)actionViewDidClickPreOrEditView:(WKPhotoCollectBottomView *)actionView;
- (void)actionViewDidClickUseOrigin:(WKPhotoCollectBottomView *)actionView useOrigin:(BOOL)useOrigin;
- (void)actionViewDidClickSelect:(WKPhotoCollectBottomView *)actionView;
- (void)actionView:(WKPhotoCollectBottomView *)actionView didSelectIndex:(NSInteger)index;

@end

@interface WKPhotoCollectBottomView : UIView

@property (nonatomic, weak) id<WKPhotoCollectBottomViewDelegate> delegate;

@property (nonatomic, weak) WKPhotoAlbumCollectManager *manager;

- (instancetype)initWithFrame:(CGRect)frame useForCollectVC:(BOOL)useForCollectVC;

- (void)hiddenClipButtonAfterClip;

@end

NS_ASSUME_NONNULL_END
