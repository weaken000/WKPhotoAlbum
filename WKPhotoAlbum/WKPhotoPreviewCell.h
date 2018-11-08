//
//  WKCheckContactScaleCell.h
//  QingYouProject
//
//  Created by mac on 2018/6/19.
//  Copyright © 2018年 ccyouge. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WKPhotoPreviewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIScrollView *imageContentScrollView;

@property (nonatomic, strong) UIView *videoContentView;

@property (nonatomic, copy  , nullable) NSString *assetIdentifier;

@property (nonatomic, strong, nullable) UIImage  *thumImage;

@end
