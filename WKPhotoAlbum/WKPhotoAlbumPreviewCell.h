//
//  WKPhotoAlbumPreviewCell.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/8.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WKPhotoAlbumPreviewCell;

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

@end

@interface WKPhotoAlbumPreviewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView       *imageView;

@property (nonatomic, strong) UIScrollView       *imageContentScrollView;

@property (nonatomic, strong) UIView             *videoContentView;

@property (nonatomic, copy  , nullable) NSString *assetIdentifier;

@property (nonatomic, strong, nullable) UIImage  *image;

@property (nonatomic, assign) NSInteger selectIndex;

@property (nonatomic, weak  ) id<WKPhotoAlbumPreviewCellDelegate> delegate;

@property (nonatomic, assign) WKPhotoAlbumCellType cellType;

- (void)intoClipMode:(BOOL)clipMode;

@end

NS_ASSUME_NONNULL_END
