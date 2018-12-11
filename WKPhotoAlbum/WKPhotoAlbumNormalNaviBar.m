//
//  WKPhotoAlbumNormalNaviBar.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/7.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumNormalNaviBar.h"
#import "WKPhotoAlbumConfig.h"
#import "WKPhotoAlbumUtils.h"

@implementation WKPhotoAlbumNormalNaviBar {
    UILabel *_titleLabel;
}

- (instancetype)initWithTarget:(id)target popAction:(SEL)popAction cancelAction:(SEL)cancelAction {
    return [self initWithTarget:target popAction:popAction takePhotoAction:nil cancelAction:cancelAction];
}

- (instancetype)initWithTarget:(id)target popAction:(SEL)popAction takePhotoAction:(SEL)takePhotoAction cancelAction:(SEL)cancelAction {
    if (self == [super init]) {
        CGFloat statusH = [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        self.frame = CGRectMake(0, 0, width, 44.0 + statusH);
        self.backgroundColor = [WKPhotoAlbumConfig sharedConfig].naviBgColor;
        
        if (popAction) {
            UIButton *backButton = [[UIButton alloc] init];
            [backButton setImage:[WKPhotoAlbumUtils imageName:@"wk_navigation_back"] forState:UIControlStateNormal];
            backButton.frame = CGRectMake(15, statusH, 44, 44);
            backButton.imageEdgeInsets = UIEdgeInsetsMake(14.5, 0, 14.5, 0);
            backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            [backButton addTarget:target action:popAction forControlEvents:UIControlEventTouchUpInside];
            backButton.tag = 101;
            [self addSubview:backButton];
        }
        
        if (cancelAction) {
            UIButton *cancelButton = [[UIButton alloc] init];
            cancelButton.frame = CGRectMake(width - 64, statusH, 50, 44);
            cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
            [cancelButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].naviTitleColor forState:UIControlStateNormal];
            cancelButton.titleLabel.font = [WKPhotoAlbumConfig sharedConfig].naviItemFont;
            [cancelButton addTarget:target action:cancelAction forControlEvents:UIControlEventTouchUpInside];
            cancelButton.tag = 102;
            [self addSubview:cancelButton];
        }
        
        if (takePhotoAction) {
            UIButton *takePhotoButton = [[UIButton alloc] init];
            takePhotoButton.frame = CGRectMake(width - 64 - 44, statusH, 44, 44);
            takePhotoButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            [takePhotoButton setImage:[WKPhotoAlbumUtils imageName:@"wk_record_camera"] forState:UIControlStateNormal];
            takePhotoButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
            [takePhotoButton addTarget:target action:takePhotoAction forControlEvents:UIControlEventTouchUpInside];
            takePhotoButton.tag = 103;
            [self addSubview:takePhotoButton];
        }
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [WKPhotoAlbumConfig sharedConfig].naviTitleFont;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.center = CGPointMake(width * 0.5, statusH + 22.0);
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat statusH = [UIApplication sharedApplication].statusBarFrame.size.height;
    _titleLabel.center = CGPointMake(self.bounds.size.width * 0.5, statusH + 22.0);
}

- (void)setTitle:(NSString *)title {
    _title = title;
    _titleLabel.text = title;
    [_titleLabel sizeToFit];
}

- (void)hiddenCameraButton:(BOOL)hidden {
    UIButton *btn = [self viewWithTag:103];
    if (btn) {
        btn.hidden = hidden;
    }
}

@end
