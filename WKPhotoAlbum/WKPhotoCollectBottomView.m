//
//  WKPhotoCollectBottomView.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/6.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoCollectBottomView.h"
#import "WKPhotoAlbumUtils.h"

CGFloat const kActionViewPreViewHeight  = 80.0;
CGFloat const kActionViewActionHeight   = 44.0;
CGFloat const kActionViewLeftMargin     = 15.0;

@interface WKPhotoCollectBottomView()<UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation WKPhotoCollectBottomView {
    
    UIButton         *_selectButton;
    UIButton         *_useOriginButton;
    UIButton         *_preOrEditButton;
    UICollectionView *_selectPreCollectionView;
    BOOL              _useForCollectVC;
}

- (instancetype)initWithFrame:(CGRect)frame useForCollectVC:(BOOL)useForCollectVC {
    if (self == [super initWithFrame:frame]) {
        _useForCollectVC = useForCollectVC;
        [self setupSubviews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [_useOriginButton sizeToFit];
    
    _selectPreCollectionView.frame = CGRectMake(0, 0, self.frame.size.width, kActionViewPreViewHeight);
    if (_useForCollectVC) {
        _useOriginButton.center = CGPointMake(self.frame.size.width * 0.5, kActionViewActionHeight * 0.5);
    } else {
        _useOriginButton.center = CGPointMake(self.frame.size.width * 0.5, kActionViewPreViewHeight + kActionViewActionHeight * 0.5);
    }
    _preOrEditButton.frame = CGRectMake(kActionViewLeftMargin,
                                        _useOriginButton.center.y - kActionViewActionHeight * 0.5,
                                             60, kActionViewActionHeight);
    _selectButton.frame = CGRectMake(self.frame.size.width - kActionViewLeftMargin - 60,
                                     _useOriginButton.center.y - 15, 60, 30);
}

- (void)setupSubviews {
    self.backgroundColor = [WKPhotoAlbumUtils r:39 g:48 b:55 a:0.8];
    
    if (!_useForCollectVC) {
        CGFloat margin = 15.0;
        CGFloat itemW = kActionViewPreViewHeight - 2 * margin;
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(itemW, itemW);
        layout.minimumInteritemSpacing = margin;
        layout.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
        _selectPreCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _selectPreCollectionView.delegate = self;
        _selectPreCollectionView.dataSource = self;
        [_selectPreCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        _selectPreCollectionView.backgroundColor = self.backgroundColor;
        [self addSubview:_selectPreCollectionView];
    }

    _preOrEditButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_preOrEditButton setTitle:(_useForCollectVC ? @"预览" : @"编辑") forState:UIControlStateNormal];
    _preOrEditButton.titleLabel.font = [UIFont systemFontOfSize:16];
    _preOrEditButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_preOrEditButton addTarget:self action:@selector(click_preview) forControlEvents:UIControlEventTouchUpInside];
    _preOrEditButton.enabled = YES;
    [_preOrEditButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self addSubview:_preOrEditButton];
    
    _useOriginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_useOriginButton setTitle:@"使用原图" forState:UIControlStateNormal];
    [_useOriginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_useOriginButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    _useOriginButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_useOriginButton addTarget:self action:@selector(click_useOrigin) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_useOriginButton];
    
    _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _selectButton.layer.cornerRadius = 5.0;
    _selectButton.layer.masksToBounds = YES;
    [_selectButton setTitle:@"选择" forState:UIControlStateNormal];
    _selectButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_selectButton addTarget:self action:@selector(click_select) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_selectButton];
    
    [self configSelectCount:0];
}

- (void)configUseOrigin:(BOOL)useOrigin {
    _useOriginButton.selected = useOrigin;
}

- (void)configSelectCount:(NSInteger)selectCount {
    BOOL enable = (selectCount > 0);
    if (enable) {
        _selectButton.backgroundColor = [WKPhotoAlbumUtils r:37 g:171 b:40 a:1.0];
        if (_useForCollectVC) {
            [_preOrEditButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        [_selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_selectButton setTitle:[NSString stringWithFormat:@"选择(%zd)", selectCount] forState:UIControlStateNormal];
    } else {
        if (_useForCollectVC) {
            [_preOrEditButton setTitleColor:[UIColor colorWithWhite:0.7 alpha:0.7] forState:UIControlStateNormal];
        }
        [_selectButton setTitleColor:[UIColor colorWithWhite:0.7 alpha:0.7] forState:UIControlStateNormal];
        _selectButton.backgroundColor = [WKPhotoAlbumUtils r:27 g:81 b:28 a:0.8];
        [_selectButton setTitle:@"选择" forState:UIControlStateNormal];
    }
    if (_useForCollectVC) {
        _preOrEditButton.enabled = enable;
    }
    _selectButton.enabled = enable;
}

- (void)click_preview {
    if ([self.delegate respondsToSelector:@selector(actionViewDidClickPreOrEditView:)]) {
        [self.delegate actionViewDidClickPreOrEditView:self];
    }
}
- (void)click_useOrigin {
    if ([self.delegate respondsToSelector:@selector(actionViewDidClickUseOrigin:useOrigin:)]) {
        [self.delegate actionViewDidClickUseOrigin:self useOrigin:!_useOriginButton.isSelected];
    }
}
- (void)click_select {
    if ([self.delegate respondsToSelector:@selector(actionViewDidClickSelect:)]) {
        [self.delegate actionViewDidClickSelect:self];
    }
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    return cell;
}


@end
