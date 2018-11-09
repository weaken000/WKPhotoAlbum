//
//  WKPhotoAlbumSelectButton.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/7.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumSelectButton.h"
#import "WKPhotoAlbumConfig.h"

@interface WKPhotoAlbumSelectButton()

@property (nonatomic, strong) UILabel *selectIndexLabel;

@end

@implementation WKPhotoAlbumSelectButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self == [super initWithFrame:frame]) {
        [self setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_photo_select.png"] forState:UIControlStateNormal];
        [self setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_photo_select.png"] forState:UIControlStateHighlighted];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _selectIndexLabel.frame = self.bounds;
    _selectIndexLabel.layer.cornerRadius = self.bounds.size.width * 0.5;
}

- (void)setSelectIndex:(NSInteger)selectIndex {
    _selectIndex = selectIndex;
    if (selectIndex > 0) {
        self.selectIndexLabel.hidden = NO;
        self.selectIndexLabel.text = [NSString stringWithFormat:@"%zd", selectIndex];
    } else {
        _selectIndexLabel.hidden = YES;
    }
}

- (void)showAnimation {
    NSValue *startValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    NSValue *overValue  = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)];
    NSValue *thinValue  = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.80, 0.80, 1.0)];
    NSValue *endValue   = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    CAKeyframeAnimation *scaleAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    scaleAnim.values = @[startValue, overValue, thinValue, endValue];
    scaleAnim.keyTimes = @[@(0.f), @(0.5f), @(0.9f), @(1.0f)];
    scaleAnim.duration = 0.4;
    scaleAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.layer addAnimation:scaleAnim forKey:nil];
}

- (UILabel *)selectIndexLabel {
    if (!_selectIndexLabel) {
        _selectIndexLabel = [[UILabel alloc] init];
        _selectIndexLabel.textColor = [UIColor whiteColor];
        _selectIndexLabel.font = [UIFont systemFontOfSize:13];
        _selectIndexLabel.backgroundColor = [WKPhotoAlbumConfig sharedConfig].selectColor;
        _selectIndexLabel.textAlignment = NSTextAlignmentCenter;
        _selectIndexLabel.layer.masksToBounds = YES;
        [self addSubview:_selectIndexLabel];
    }
    return _selectIndexLabel;
}

@end
