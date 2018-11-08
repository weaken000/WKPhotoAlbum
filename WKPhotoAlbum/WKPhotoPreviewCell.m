//
//  WKPhotoPreviewCell.m
//  QingYouProject
//
//  Created by mac on 2018/6/19.
//  Copyright © 2018年 ccyouge. All rights reserved.
//

#import "WKPhotoPreviewCell.h"

@interface WKPhotoPreviewCell()<UIScrollViewDelegate>


@end

@implementation WKPhotoPreviewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self == [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    _imageContentScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _imageContentScrollView.showsVerticalScrollIndicator = NO;
    _imageContentScrollView.showsHorizontalScrollIndicator = NO;
    _imageContentScrollView.minimumZoomScale = 1.0;
    _imageContentScrollView.maximumZoomScale = 2.0;
    _imageContentScrollView.zoomScale = 1.0;
    _imageContentScrollView.delegate = self;
    [self.contentView addSubview:_imageContentScrollView];
    
    _imageView = [UIImageView new];
    [_imageContentScrollView addSubview:_imageView];
    _imageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapGesture.numberOfTapsRequired = 1;
    singleTapGesture.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:singleTapGesture];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:doubleTapGesture];
    //只有当doubleTapGesture识别失败的时候(即识别出这不是双击操作)，singleTapGesture才能开始识别
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
 
}

- (void)handleSingleTap:(UITapGestureRecognizer *)sender {

}
- (void)handleDoubleTap:(UITapGestureRecognizer *)sender {

}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageContentScrollView.frame = self.bounds;
    _videoContentView.frame = self.bounds;
}

- (void)setThumImage:(UIImage *)thumImage {
    _thumImage = thumImage;
    [self aspectFitImageViewForImage:thumImage];
}

- (void)aspectFitImageViewForImage:(UIImage *)image {
    CGFloat scale = MIN(self.frame.size.width / image.size.width, self.frame.size.height / image.size.height);
    CGFloat w = scale * image.size.width;
    CGFloat h = scale * image.size.height;
    _imageView.frame = CGRectMake((self.frame.size.width - w) / 2.0, (self.frame.size.height - h) / 2.0, w, h);
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


- (UIView *)videoContentView {
    if (!_videoContentView) {
        _videoContentView = [[UIView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:_videoContentView];
    }
    return _videoContentView;
}

@end
