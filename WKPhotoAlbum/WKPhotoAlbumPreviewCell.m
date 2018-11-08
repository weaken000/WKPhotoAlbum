//
//  WKPhotoAlbumPreviewCell.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/8.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumPreviewCell.h"
#import "WKPhotoAlbumSelectButton.h"

@interface WKPhotoAlbumPreviewCell()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) WKPhotoAlbumSelectButton *selectButton;

@end

@implementation WKPhotoAlbumPreviewCell {
    UITapGestureRecognizer *_doubleTapGesture;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageContentScrollView.frame = self.bounds;
    _videoContentView.frame = self.bounds;
    _selectButton.frame = CGRectMake(self.contentView.bounds.size.width - 30, 5, 25, 25);
    if (_cellType != WKPhotoAlbumCellTypePreview) {
        _imageView.frame = self.bounds;
    }
}

- (void)setupSubviews {
    
    _imageView = [[UIImageView alloc] init];

    if (_cellType == WKPhotoAlbumCellTypePreview) {
        _imageContentScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _imageContentScrollView.showsVerticalScrollIndicator = NO;
        _imageContentScrollView.showsHorizontalScrollIndicator = NO;
        _imageContentScrollView.minimumZoomScale = 1.0;
        _imageContentScrollView.maximumZoomScale = 2.0;
        _imageContentScrollView.zoomScale = 1.0;
        _imageContentScrollView.delegate = self;
        [self.contentView addSubview:_imageContentScrollView];
        
        [_imageContentScrollView addSubview:_imageView];

        _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        _doubleTapGesture.numberOfTapsRequired = 2;
        _doubleTapGesture.numberOfTouchesRequired = 1;
        _doubleTapGesture.delegate = self;
        [self addGestureRecognizer:_doubleTapGesture];
        
    } else {
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview:_imageView];
    }
    
    if (_cellType == WKPhotoAlbumCellTypeCollect) {
        _selectButton = [[WKPhotoAlbumSelectButton alloc] init];
        [_selectButton addTarget:self action:@selector(click_selectButton) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_selectButton];
    }
}

#pragma mark - Action
- (void)handleDoubleTap:(UITapGestureRecognizer *)sender {
    [_imageContentScrollView setZoomScale:1.0 animated:YES];
}
- (void)click_selectButton {
    if ([self.delegate respondsToSelector:@selector(photoPreviewCell:didChangeToSelect:)]) {
        BOOL isSelect = self.selectButton.selectIndex > 0;
        BOOL success = [self.delegate photoPreviewCell:self didChangeToSelect:!isSelect];
        if (success) {
            if (self.selectButton.selectIndex > 0) {
                [self.selectButton showAnimation];
            }
        }
    }
}

#pragma mark - setter
- (void)setCellType:(WKPhotoAlbumCellType)cellType {
    if (_cellType != cellType) {
        _cellType = cellType;
        [self setupSubviews];
    }
}

- (void)setImage:(UIImage *)image {
    _image = image;
    if (_cellType == WKPhotoAlbumCellTypePreview) {
        [self aspectFitImageViewForImage:image];
    } else {
        _imageView.image = image;
    }
}

- (void)setSelectIndex:(NSInteger)selectIndex {
    self.selectButton.selectIndex = selectIndex;
}

#pragma mark - Config
- (void)aspectFitImageViewForImage:(UIImage *)image {
    if (image) {
        CGFloat scale = MIN(self.frame.size.width / image.size.width, self.frame.size.height / image.size.height);
        CGFloat w = scale * image.size.width;
        CGFloat h = scale * image.size.height;
        _imageView.frame = CGRectMake((self.frame.size.width - w) / 2.0, (self.frame.size.height - h) / 2.0, w, h);
    }
    _imageView.image = image;
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGRect frame = _imageView.frame;
    frame.origin.y = scrollView.frame.size.height > _imageView.frame.size.height ? (scrollView.frame.size.height - _imageView.frame.size.height) * 0.5 : 0;
    frame.origin.x = scrollView.frame.size.width > _imageView.frame.size.width ? (scrollView.frame.size.width - _imageView.frame.size.width) * 0.5 : 0;
    _imageView.frame = frame;
    scrollView.contentSize = CGSizeMake(frame.size.width, frame.size.height);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == _doubleTapGesture) {
        return YES;
    }
    return NO;
}


- (UIView *)videoContentView {
    if (!_videoContentView) {
        _videoContentView = [[UIView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:_videoContentView];
    }
    return _videoContentView;
}


@end
