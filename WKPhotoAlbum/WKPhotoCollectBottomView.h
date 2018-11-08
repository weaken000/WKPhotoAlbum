//
//  WKPhotoCollectBottomView.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/6.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WKPhotoCollectBottomView;


NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN CGFloat const kActionViewPreViewHeight;
UIKIT_EXTERN CGFloat const kActionViewActionHeight;

@protocol WKPhotoCollectBottomViewDelegate <NSObject>

@optional

- (void)actionViewDidClickPreOrEditView:(WKPhotoCollectBottomView *)actionView;
- (void)actionViewDidClickUseOrigin:(WKPhotoCollectBottomView *)actionView useOrigin:(BOOL)useOrigin;
- (void)actionViewDidClickSelect:(WKPhotoCollectBottomView *)actionView;

@end

@interface WKPhotoCollectBottomView : UIView

@property (nonatomic, weak) id<WKPhotoCollectBottomViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame useForCollectVC:(BOOL)useForCollectVC;

- (void)configSelectCount:(NSInteger)selectCount;

- (void)configUseOrigin:(BOOL)useOrigin;

@end

NS_ASSUME_NONNULL_END
