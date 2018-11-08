//
//  WKPhotoCollectionCell.m
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoCollectionCell.h"
#import "WKPhotoAlbumSelectButton.h"

@interface WKPhotoCollectionCell()

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) WKPhotoAlbumSelectButton *selectButton;

@end

@implementation WKPhotoCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self == [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.layer.masksToBounds = YES;
    [self.contentView addSubview:_imageView];
    
    _selectButton = [[WKPhotoAlbumSelectButton alloc] init];
    [_selectButton addTarget:self action:@selector(click_selectButton) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_selectButton];
}

- (void)click_selectButton {
    if ([self.delegate respondsToSelector:@selector(photoCollectionCell:didChangeToSelect:)]) {
        BOOL isSelect = self.selectButton.selectIndex > 0;
        BOOL success = [self.delegate photoCollectionCell:self didChangeToSelect:!isSelect];
        if (success) {
            if (self.selectButton.selectIndex > 0) {
                [self.selectButton showAnimation];
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.contentView.bounds;
    _selectButton.frame = CGRectMake(self.contentView.bounds.size.width - 30, 5, 25, 25);
}

- (void)setThumImage:(UIImage *)thumImage {
    _thumImage = thumImage;
    self.imageView.image = thumImage;
}

- (void)setSelectIndex:(NSInteger)selectIndex {
    self.selectButton.selectIndex = selectIndex;
}

@end
