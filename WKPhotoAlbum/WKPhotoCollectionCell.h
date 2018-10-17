//
//  WKPhotoCollectionCell.h
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class WKPhotoCollectionCell;

@protocol WKPhotoCollectionCellDelegate <NSObject>

- (BOOL)photoCollectionCell:(WKPhotoCollectionCell *)photoCell didChangeToSelect:(BOOL)select;

@end

@interface WKPhotoCollectionCell : UICollectionViewCell

@property (nonatomic, copy  ) NSString *assetIdentifier;

@property (nonatomic, assign, getter=isPhotoSelect) BOOL photoSelect;

@property (nonatomic, strong, nullable) UIImage  *thumImage;

@property (nonatomic, weak  ) id<WKPhotoCollectionCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
