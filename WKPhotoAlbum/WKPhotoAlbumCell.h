//
//  WKPhotoAlbumCell.h
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoAlbumCell : UITableViewCell

@property (nonatomic, strong) UILabel *albumTitleLabel;

@property (nonatomic, strong) UILabel *albumCountLabel;

@property (nonatomic, strong) UIImageView *albumCoverImageView;

@property (nonatomic, strong) UIImageView *arrowImageView;

@end

NS_ASSUME_NONNULL_END
