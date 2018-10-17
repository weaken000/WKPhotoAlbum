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

@property (nonatomic, strong) CATextLayer *selectNumLayer;

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
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"choose"] forState:UIControlStateNormal];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"choose"] forState:UIControlStateHighlighted];
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
                [self.selectNumLayer addAnimation:scaleAnim forKey:nil];
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
        self.selectButton.layer.mask = self.selectNumLayer;
    } else {
        self.selectButton.layer.mask = nil;
    }
}

- (CATextLayer *)selectNumLayer {
    if (!_selectNumLayer) {
        _selectNumLayer = [CATextLayer layer];
        _selectNumLayer.alignmentMode = kCAAlignmentCenter;
        _selectNumLayer.backgroundColor = [UIColor greenColor].CGColor;
        _selectNumLayer.frame = CGRectMake(0, 0, 25, 25);
        _selectNumLayer.cornerRadius = 12.5;
        _selectNumLayer.string = [[NSAttributedString alloc] initWithString:@"1" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:15.0]}];
    }
    return _selectNumLayer;
}

@end
