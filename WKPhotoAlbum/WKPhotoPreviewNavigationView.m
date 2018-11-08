//
//  WKPhotoPreviewNavigationView.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/7.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoPreviewNavigationView.h"
#import "WKPhotoAlbumSelectButton.h"

#import "WKPhotoAlbumUtils.h"

@implementation WKPhotoPreviewNavigationView {
    UIButton *_leftButton;
    UIButton *_rightButton;
    WKPhotoAlbumSelectButton *_selectButton;
}

- (instancetype)initWithTarget:(id)target leftAction:(SEL)leftAction rightAction:(SEL)rightAction {
    if (!target || !leftAction || !rightAction) return nil;
    if (self == [super init]) {
        CGFloat top = [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat height = top + 44.0;
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        self.frame = CGRectMake(0, 0, width, height);
        
        self.backgroundColor = [WKPhotoAlbumUtils r:39 g:48 b:55 a:0.8];
        
        _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _leftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [_leftButton addTarget:target action:leftAction forControlEvents:UIControlEventTouchUpInside];
        _leftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _leftButton.imageEdgeInsets = UIEdgeInsetsMake(14.5, 0, 14.5, 0);
        _leftButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_leftButton];
        
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        _rightButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [_rightButton addTarget:target action:rightAction forControlEvents:UIControlEventTouchUpInside];
        _rightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_rightButton setTitle:@"完成" forState:UIControlStateNormal];
        [self addSubview:_rightButton];
        
        _selectButton = [[WKPhotoAlbumSelectButton alloc] init];
        [_selectButton addTarget:target action:rightAction forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_selectButton];
        
        _leftButton.frame = CGRectMake(15, top, 44, 44);
        _rightButton.frame = CGRectMake(width - 59, top, 44, 44);
        _selectButton.frame = CGRectMake(width - 40, top + 9.5, 25, 25);

        [self toEditMode:NO];
    }
    return self;
}

- (void)toEditMode:(BOOL)editMode {
    if (!editMode) {
        [_leftButton setImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_navigation_back.png"] forState:UIControlStateNormal];
        [_leftButton setTitle:nil forState:UIControlStateNormal];
        _selectButton.hidden = NO;
        _rightButton.hidden = YES;
    } else {
        [_leftButton setImage:nil forState:UIControlStateNormal];
        [_leftButton setTitle:@"取消" forState:UIControlStateNormal];
        _selectButton.hidden = YES;
        _rightButton.hidden = NO;
    }
    _isInEditMode = editMode;
}

- (void)configSelectIndex:(NSInteger)index {
    _selectButton.selectIndex = index;
}

@end
