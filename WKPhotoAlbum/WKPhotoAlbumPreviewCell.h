//
//  WKPhotoAlbumPreviewCell.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/8.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WKPhotoAlbumPreviewCell, WKPhotoAlbumModel;

typedef NS_ENUM(NSUInteger, WKPhotoAlbumCellType) {
    WKPhotoAlbumCellTypeUndefine,
    WKPhotoAlbumCellTypeCollect,
    WKPhotoAlbumCellTypePreview,
    WKPhotoAlbumCellTypeSubPreview,
};

NS_ASSUME_NONNULL_BEGIN

@protocol WKPhotoAlbumPreviewCellDelegate <NSObject>

@optional

- (BOOL)photoPreviewCell:(WKPhotoAlbumPreviewCell *)previewCell didChangeToSelect:(BOOL)select;

- (void)photoPreviewCellDidPlayControl:(WKPhotoAlbumPreviewCell *)previewCell;

@end

@interface WKPhotoAlbumPreviewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView        *imageView;

@property (nonatomic, strong) UIScrollView       *imageContentScrollView;

@property (nonatomic, strong) UIView             *videoContentView;

@property (nonatomic, strong) UIButton           *videoStartBtn;

@property (nonatomic, copy  , nullable) WKPhotoAlbumModel *albumInfo;

@property (nonatomic, strong, nullable) UIImage  *image;

@property (nonatomic, assign) NSInteger selectIndex;

@property (nonatomic, weak  ) id<WKPhotoAlbumPreviewCellDelegate> delegate;

@property (nonatomic, assign) WKPhotoAlbumCellType cellType;

@property (nonatomic, assign) int32_t requestID;

- (void)intoClipMode:(BOOL)clipMode;

@end

NS_ASSUME_NONNULL_END
