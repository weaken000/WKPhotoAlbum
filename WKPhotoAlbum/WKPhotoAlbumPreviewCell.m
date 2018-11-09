//
//  WKPhotoAlbumPreviewCell.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/8.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumPreviewCell.h"
#import "WKPhotoAlbumSelectButton.h"
#import "WKPhotoAlbumCollectManager.h"

@interface WKPhotoAlbumPreviewCell()<UIScrollViewDelegate>

@property (nonatomic, strong) WKPhotoAlbumSelectButton *selectButton;

@property (nonatomic, strong) UIImageView *videoTypeImageView;

@property (nonatomic, strong) UILabel *videoLengthLabel;

@end

@implementation WKPhotoAlbumPreviewCell {
    UITapGestureRecognizer *_doubleTapGesture;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_cellType != WKPhotoAlbumCellTypePreview) {
        _imageView.frame = self.bounds;
    }
    _imageContentScrollView.frame = self.bounds;
    _selectButton.frame = CGRectMake(self.contentView.bounds.size.width - 32, 2, 30, 30);
    _videoContentView.frame = _imageView.bounds;
    CGFloat controlW = 75;
    _videoStartBtn.frame = CGRectMake((self.bounds.size.width - controlW) / 2.0, (self.bounds.size.height - controlW) / 2.0, controlW, controlW);
    _videoTypeImageView.frame = CGRectMake(5, self.bounds.size.height - 25, 20, 20);
}

- (void)setupSubviews {
    
    _imageView = [[UIImageView alloc] init];

    if (_cellType == WKPhotoAlbumCellTypePreview) {
        _imageContentScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _imageContentScrollView.showsVerticalScrollIndicator = NO;
        _imageContentScrollView.showsHorizontalScrollIndicator = NO;
        _imageContentScrollView.maximumZoomScale = 2.0;
        _imageContentScrollView.zoomScale = 1.0;
        _imageContentScrollView.delegate = self;
        [self.contentView addSubview:_imageContentScrollView];
        
        _imageView.userInteractionEnabled = YES;
        [_imageContentScrollView addSubview:_imageView];

        _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        _doubleTapGesture.numberOfTapsRequired = 2;
        _doubleTapGesture.numberOfTouchesRequired = 1;
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
- (void)click_startButton {
    if ([self.delegate respondsToSelector:@selector(photoPreviewCellDidPlayControl:)]) {
        [self.delegate photoPreviewCellDidPlayControl:self];
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
        if (_cellType == WKPhotoAlbumCellTypeCollect && _albumInfo.playItem) {
            _videoLengthLabel.text = _albumInfo.assetDuration;
            [_videoLengthLabel sizeToFit];
            _videoLengthLabel.frame = CGRectMake(CGRectGetMaxX(_videoTypeImageView.frame) + 10,
                                                 self.bounds.size.height - 25 + (20 - _videoLengthLabel.frame.size.height) * 0.5,
                                                 _videoLengthLabel.frame.size.width,
                                                 _videoLengthLabel.frame.size.height);
        }
    }
}
- (void)setSelectIndex:(NSInteger)selectIndex {
    self.selectButton.selectIndex = selectIndex;
}
- (void)setAlbumInfo:(WKPhotoAlbumModel *)albumInfo {
    _albumInfo = albumInfo;
    //展示播放按钮
    if (_cellType == WKPhotoAlbumCellTypePreview) {
        if (albumInfo.asset.mediaType != PHAssetMediaTypeImage) {
            self.videoStartBtn.hidden = NO;
            _videoContentView.hidden = NO;
        } else {
            _videoStartBtn.hidden = YES;
            _videoContentView.hidden = YES;
        }
        return;
    }
    if (_cellType == WKPhotoAlbumCellTypeCollect) {
        if (albumInfo.asset.mediaType != PHAssetMediaTypeImage) {
            self.videoLengthLabel.hidden = NO;
            self.videoTypeImageView.hidden = NO;
        } else {
            _videoLengthLabel.hidden = YES;
            _videoTypeImageView.hidden = YES;
        }
        return;
    }
    if (_cellType == WKPhotoAlbumCellTypeSubPreview) {
        if (albumInfo.asset.mediaType != PHAssetMediaTypeImage) {
            self.videoTypeImageView.hidden = NO;
        } else {
            _videoTypeImageView.hidden = YES;
        }
        return;
    }
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

- (void)intoClipMode:(BOOL)clipMode {
    if (clipMode) {
        CGFloat topMargin = [UIApplication sharedApplication].statusBarFrame.size.height + 44.0;
        if (self.imageView.frame.origin.y + 20.0 < topMargin) {
            CGFloat zoom = (self.imageView.frame.size.height - (topMargin + 20.0 - self.imageView.frame.origin.y) * 2) / self.imageView.frame.size.height;
            self.imageContentScrollView.minimumZoomScale = zoom;
            [self.imageContentScrollView setZoomScale:zoom animated:YES];
        } else {
            CGFloat zoom = (self.imageView.frame.size.width - 50.0) / self.imageView.frame.size.width;
            self.imageContentScrollView.minimumZoomScale = zoom;
            [self.imageContentScrollView setZoomScale:zoom animated:YES];
        }
        self.imageContentScrollView.scrollEnabled = NO;
    } else {
        [self.imageContentScrollView setZoomScale:1.0 animated:YES];
        self.imageContentScrollView.minimumZoomScale = 1.0;
        self.imageContentScrollView.scrollEnabled = YES;
    }
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

#pragma mark - lazy load
- (UIView *)videoContentView {
    if (!_videoContentView) {
        _videoContentView = [[UIView alloc] initWithFrame:self.imageView.bounds];
        [self.imageView insertSubview:_videoContentView belowSubview:self.videoStartBtn];
    }
    return _videoContentView;
}

- (UIButton *)videoStartBtn {
    if (!_videoStartBtn) {
        _videoStartBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_videoStartBtn setBackgroundImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_play.png"] forState:UIControlStateNormal];
        [_videoStartBtn addTarget:self action:@selector(click_startButton) forControlEvents:UIControlEventTouchUpInside];
        [self.videoContentView addSubview:_videoStartBtn];
    }
    return _videoStartBtn;
}

- (UIImageView *)videoTypeImageView {
    if (!_videoTypeImageView) {
        _videoTypeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WKPhotoAlbum.bundle/wk_video_icon.png"]];
        _videoTypeImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.imageView addSubview:_videoTypeImageView];
    }
    return _videoTypeImageView;
}

- (UILabel *)videoLengthLabel {
    if (!_videoLengthLabel) {
        _videoLengthLabel = [[UILabel alloc] init];
        _videoLengthLabel.textColor = [UIColor whiteColor];
        _videoLengthLabel.font = [UIFont systemFontOfSize:12];
        [self.imageView addSubview:_videoLengthLabel];
    }
    return _videoLengthLabel;
}


@end
