//
//  WKPhotoCollectBottomView.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/6.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoCollectBottomView.h"
#import "WKPhotoAlbumPreviewCell.h"
#import "WKPhotoAlbumCollectManager.h"
#import "WKPhotoAlbumConfig.h"

CGFloat const kActionViewPreViewHeight  = 114.0;
CGFloat const kActionViewActionHeight   = 58.0;
CGFloat const kActionViewLeftMargin     = 15.0;

@interface WKPhotoCollectBottomView()<UICollectionViewDelegate, UICollectionViewDataSource, WKPhotoAlbumCollectManagerChanged>

@end

@implementation WKPhotoCollectBottomView {
    UIButton                     *_selectButton;
    UIButton                     *_useOriginButton;
    UIButton                     *_preOrEditButton;
    UICollectionView             *_selectPreCollectionView;
    UIView                       *_lineView;
    NSArray<WKPhotoAlbumModel *> *_previewAssetArr;
    BOOL                          _useForCollectVC;
    NSInteger                     _previewAssetIndex;
}

- (instancetype)initWithFrame:(CGRect)frame useForCollectVC:(BOOL)useForCollectVC {
    if (self == [super initWithFrame:frame]) {
        _useForCollectVC = useForCollectVC;
        _previewAssetIndex = -1;
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
    
    if (!_useForCollectVC) {
        self.backgroundColor = [WKPhotoAlbumConfig sharedConfig].bottomBarColorWhilePreview;
        CGFloat margin = 16.0;
        CGFloat itemW = kActionViewPreViewHeight - 2 * margin;
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(itemW, itemW);
        layout.minimumInteritemSpacing = margin;
        layout.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
        _selectPreCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _selectPreCollectionView.delegate = self;
        _selectPreCollectionView.dataSource = self;
        [_selectPreCollectionView registerClass:[WKPhotoAlbumPreviewCell class] forCellWithReuseIdentifier:@"cell"];
        _selectPreCollectionView.backgroundColor = [UIColor clearColor];
        [self addSubview:_selectPreCollectionView];
        
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.6];
        [self addSubview:_lineView];
        _lineView.frame = CGRectMake(margin, kActionViewPreViewHeight, [UIScreen mainScreen].bounds.size.width - 2 * margin, 0.5);
    } else {
        self.backgroundColor = [WKPhotoAlbumConfig sharedConfig].bottomBarColorWhileCollect;
    }

    _preOrEditButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_preOrEditButton setTitle:(_useForCollectVC ? @"预览" : @"编辑") forState:UIControlStateNormal];
    _preOrEditButton.titleLabel.font = [WKPhotoAlbumConfig sharedConfig].naviItemFont;
    _preOrEditButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_preOrEditButton addTarget:self action:@selector(click_preview) forControlEvents:UIControlEventTouchUpInside];
    _preOrEditButton.enabled = YES;
    [_preOrEditButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].naviTitleColor forState:UIControlStateNormal];
    [self addSubview:_preOrEditButton];
    
    _useOriginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_useOriginButton setTitle:@"使用原图" forState:UIControlStateNormal];
    [_useOriginButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].naviTitleColor forState:UIControlStateNormal];
    [_useOriginButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    _useOriginButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_useOriginButton addTarget:self action:@selector(click_useOrigin) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_useOriginButton];
    
    _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _selectButton.layer.cornerRadius = 5.0;
    _selectButton.layer.masksToBounds = YES;
    [_selectButton setTitle:@"选择" forState:UIControlStateNormal];
    _selectButton.titleLabel.font = [WKPhotoAlbumConfig sharedConfig].naviItemFont;
    [_selectButton addTarget:self action:@selector(click_select) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_selectButton];
    
    [self managerValueChangedForKey:@"selectIndexArray" withValue:@(0)];
}

- (void)setManager:(WKPhotoAlbumCollectManager *)manager {
    _manager = manager;
    [_manager addChangedListener:self];
}

#pragma mark - WKPhotoAlbumCollectManagerChanged
- (BOOL)inListening {
    return YES;
}
- (void)managerValueChangedForKey:(NSString *)key withValue:(id)value {
    if ([key isEqualToString:@"isUseOrigin"]) {//是否使用原图
        _useOriginButton.selected = [value boolValue];
    } else if ([key isEqualToString:@"selectIndexArray"]) {//选择的数组变化
        //改变选择按钮状态
        BOOL enable = (self.manager.selectIndexArray.count > 0);
        if (enable) {
            _selectButton.backgroundColor = [WKPhotoAlbumConfig sharedConfig].selectColor;
            if (_useForCollectVC) {
                [_preOrEditButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].naviTitleColor forState:UIControlStateNormal];
            }
            [_selectButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].naviTitleColor forState:UIControlStateNormal];
            [_selectButton setTitle:[NSString stringWithFormat:@"选择(%ld)", self.manager.selectIndexArray.count] forState:UIControlStateNormal];
        } else {
            if (_useForCollectVC) {
                [_preOrEditButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].unEnableTitleColor forState:UIControlStateNormal];
            }
            [_selectButton setTitleColor:[WKPhotoAlbumConfig sharedConfig].unEnableTitleColor forState:UIControlStateNormal];
            _selectButton.backgroundColor = [WKPhotoAlbumConfig sharedConfig].unSelectColor;
            [_selectButton setTitle:@"选择" forState:UIControlStateNormal];
        }
        if (_useForCollectVC) {
            _preOrEditButton.enabled = enable;
        }
        _selectButton.enabled = enable;
        //刷新列表
        if (_selectPreCollectionView) {
            if (!self.manager.selectIndexArray.count) {
                if (_previewAssetArr.count > 0) {
                    _previewAssetArr = nil;
                    [_selectPreCollectionView reloadData];
                }
                return;
            }
            NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:self.manager.selectIndexArray.count];
            for (NSNumber *index in self.manager.selectIndexArray) {
                WKPhotoAlbumModel *model = self.manager.allPhotoArray[index.integerValue];
                [tmp addObject:model];
            }
            _previewAssetArr = [tmp copy];
            [_selectPreCollectionView reloadData];
        }
    } else if ([key isEqualToString:@"currentPreviewIndex"]) {//当前展示的图片索引变化
        if (_selectPreCollectionView) {
            _previewAssetIndex = [value integerValue];
            [_selectPreCollectionView reloadData];
            WKPhotoAlbumModel *model = self.manager.allPhotoArray[self.manager.currentPreviewIndex];
            _preOrEditButton.hidden = (model.asset.mediaType != PHAssetMediaTypeImage);
        }
    }
}

#pragma mark - action
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
    return _previewAssetArr.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WKPhotoAlbumModel *model = _previewAssetArr[indexPath.row];
    WKPhotoAlbumPreviewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.cellType = WKPhotoAlbumCellTypeSubPreview;
    cell.albumInfo = model;
    if (model.resultImage) {
        cell.image = model.resultImage;
    } else {
        [_manager reqeustCollectionImageForIndexPath:[NSIndexPath indexPathForRow:model.collectIndex inSection:0] resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if ([cell.albumInfo.asset.localIdentifier isEqualToString:model.asset.localIdentifier] && result) {
                cell.image = result;
            } else {
                cell.image = nil;
            }
        }];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(actionView:didSelectIndex:)]) {
        WKPhotoAlbumModel *model = _previewAssetArr[indexPath.row];
        [self.delegate actionView:self didSelectIndex:model.collectIndex];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    WKPhotoAlbumPreviewCell *previewCell = (WKPhotoAlbumPreviewCell *)cell;
    WKPhotoAlbumModel *model = _previewAssetArr[indexPath.row];
    if (model.collectIndex == _previewAssetIndex) {
        previewCell.imageView.layer.borderColor = [WKPhotoAlbumConfig sharedConfig].selectColor.CGColor;
        previewCell.imageView.layer.borderWidth = 4.0;
    } else {
        previewCell.imageView.layer.borderWidth = 0.0;
    }
}


@end
