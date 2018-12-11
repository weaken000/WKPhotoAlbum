//
//  WKPhotoAlbumCell.m
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumCell.h"

@implementation WKPhotoAlbumCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self == [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupSubviews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat x = 20;
    CGFloat y = 10;
    CGFloat w = self.bounds.size.height - 2 * y;
    _albumCoverImageView.frame = CGRectMake(x, y, w, w);
    _albumTitleLabel.frame = CGRectMake(CGRectGetMaxX(_albumCoverImageView.frame) + 15, y, self.bounds.size.width - 2 * x - w - 15 - _arrowImageView.frame.size.width - 15, 16);
    _albumCountLabel.frame = CGRectMake(CGRectGetMaxX(_albumCoverImageView.frame) + 15, CGRectGetMaxY(_albumTitleLabel.frame) + 10, self.bounds.size.width - 2 * x - w - 15 - _arrowImageView.frame.size.width - 15, 16);
    
}

- (void)setupSubviews {
    
    _albumCoverImageView = [[UIImageView alloc] init];
    _albumCoverImageView.contentMode = UIViewContentModeScaleAspectFill;
    _albumCoverImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:_albumCoverImageView];
    
    _albumTitleLabel = [[UILabel alloc] init];
    _albumTitleLabel.numberOfLines = 1;
    _albumTitleLabel.font = [UIFont systemFontOfSize:16.0];
    [self.contentView addSubview:_albumTitleLabel];
    
    _albumCountLabel = [[UILabel alloc] init];
    _albumCountLabel.numberOfLines = 1;
    _albumCountLabel.font = [UIFont systemFontOfSize:14.0];
    [self.contentView addSubview:_albumCountLabel];
    
    _arrowImageView = [[UIImageView alloc] init];
    [self.contentView addSubview:_arrowImageView];
}

@end
