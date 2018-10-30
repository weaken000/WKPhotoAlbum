//
//  WKPhotoCollectionCell.m
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoCollectionCell.h"

@interface WKPhotoCollectionCell()

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIButton *selectButton;

@property (nonatomic, strong) UILabel *selectNumLabel;

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
    
    _selectButton = [[UIButton alloc] init];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_photo_select.png"] forState:UIControlStateNormal];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_photo_select.png"] forState:UIControlStateHighlighted];
    [_selectButton addTarget:self action:@selector(click_selectButton) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_selectButton];
}

- (void)click_selectButton {
    if ([self.delegate respondsToSelector:@selector(photoCollectionCell:didChangeToSelect:)]) {
        BOOL success = [self.delegate photoCollectionCell:self didChangeToSelect:!self.isPhotoSelect];
        if (success) {
            self.photoSelect = !self.isPhotoSelect;
            if (self.isPhotoSelect) {
                NSValue *startValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
                NSValue *overValue  = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)];
                NSValue *thinValue  = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.80, 0.80, 1.0)];
                NSValue *endValue   = [NSValue valueWithCATransform3D:CATransform3DIdentity];
                CAKeyframeAnimation *scaleAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
                scaleAnim.values = @[startValue, overValue, thinValue, endValue];
                scaleAnim.keyTimes = @[@(0.f), @(0.5f), @(0.9f), @(1.0f)];
                scaleAnim.duration = 0.4;
                scaleAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                [self.selectButton.layer addAnimation:scaleAnim forKey:nil];
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
- (void)setPhotoSelect:(BOOL)photoSelect {
    _photoSelect = photoSelect;
    if (photoSelect) {
        self.selectNumLabel.hidden = NO;
    } else {
        _selectNumLabel.hidden = YES;
    }
}

- (void)setSelectIndex:(NSInteger)selectIndex {
    if (selectIndex <= 0) {
        return;
    }
    self.selectNumLabel.text = [NSString stringWithFormat:@"%zd", selectIndex];
}

- (UILabel *)selectNumLabel {
    if (!_selectNumLabel) {
        _selectNumLabel = [[UILabel alloc] init];
        _selectNumLabel.textColor = [UIColor whiteColor];
        _selectNumLabel.font = [UIFont systemFontOfSize:13];
        _selectNumLabel.backgroundColor = [UIColor greenColor];
        _selectNumLabel.textAlignment = NSTextAlignmentCenter;
        
        _selectNumLabel.frame = CGRectMake(0, 0, 25, 25);
        _selectNumLabel.layer.cornerRadius = 12.5;
        _selectNumLabel.layer.masksToBounds = YES;
        [_selectButton addSubview:_selectNumLabel];
    }
    return _selectNumLabel;
}

@end
