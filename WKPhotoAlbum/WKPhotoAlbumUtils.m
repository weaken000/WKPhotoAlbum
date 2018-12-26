//
//  WKPhotoReadTool.m
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumUtils.h"
#import "WKPhotoAlbumConfig.h"

static WKPhotoAlbumHUD *instance = nil;

@implementation WKPhotoAlbumHUD {
    UIView *_maskView;
    UIView *_shadowView;
    UIActivityIndicatorView *_loadView;
    UILabel *_textLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self == [super initWithFrame:frame]) {
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        
        _shadowView = [[UIView alloc] init];
        _shadowView.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7].CGColor;
        _shadowView.layer.shadowRadius = 5;
        _shadowView.layer.shadowOffset = CGSizeZero;
        _shadowView.layer.shadowOpacity = 0.5;
        [self addSubview:_shadowView];
        
        _maskView = [[UIView alloc] init];
        _maskView.backgroundColor = [UIColor blackColor];
        _maskView.layer.cornerRadius = 5.0;
        _maskView.layer.masksToBounds = YES;
        [_shadowView addSubview:_maskView];
        
    }
    return self;
}

+ (void)createHUD {
    if (!instance) {
        instance = [[WKPhotoAlbumHUD alloc] init];
    }
}

- (void)showLoading {
    _textLabel.hidden = YES;
    if (!_loadView) {
        _loadView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _loadView.hidesWhenStopped = YES;
        [_maskView addSubview:_loadView];
    }
    
    _shadowView.frame = CGRectMake((self.frame.size.width - 80) / 2, (self.frame.size.height - 80) / 2, 80, 80);
    _maskView.frame = _shadowView.bounds;
    _loadView.frame = CGRectMake((80 - _loadView.frame.size.width) / 2, (80 - _loadView.frame.size.height) / 2, _loadView.frame.size.width, _loadView.frame.size.height);
    [_loadView startAnimating];
}

- (void)showText:(NSString *)text {
    if (_loadView && _loadView.isAnimating) {
        [_loadView stopAnimating];
    }
    
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.font = [UIFont systemFontOfSize:15.0];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.numberOfLines = 0;
        [_maskView addSubview:_textLabel];
    }
    _textLabel.text = text;
    
    CGFloat maxLabelW = [UIScreen mainScreen].bounds.size.width * 0.6 - 30;
    CGSize labelSize = [_textLabel sizeThatFits:CGSizeMake(maxLabelW, MAXFLOAT)];
    CGFloat maskW = labelSize.width + 30;
    CGFloat maskH = MAX((labelSize.height + 10), 30);
    CGFloat maskX = (self.frame.size.width - maskW) / 2;
    CGFloat maskY = (self.frame.size.height - maskH) / 2;
    
    _shadowView.frame = CGRectMake(maskX, maskY, maskW, maskH);
    _maskView.frame = _shadowView.bounds;
    _textLabel.frame = CGRectMake(15, (maskH - labelSize.height) / 2, labelSize.width, labelSize.height);
    _textLabel.hidden = NO;
}

- (void)dismiss {
    [_loadView stopAnimating];
    [self removeFromSuperview];
}

#pragma mark - public
+ (void)showLoading {
    [self createHUD];
    [instance showLoading];
    
    [[UIApplication sharedApplication].windows.firstObject addSubview:instance];
    [NSObject cancelPreviousPerformRequestsWithTarget:instance selector:@selector(dismiss) object:nil];
}

+ (void)showHUDText:(NSString *)text {
    [self createHUD];
    [instance showText:text];
    
    [[UIApplication sharedApplication].windows.firstObject addSubview:instance];
    [NSObject cancelPreviousPerformRequestsWithTarget:instance selector:@selector(dismiss) object:nil];
    [instance performSelector:@selector(dismiss) withObject:nil afterDelay:1.5];
}

+ (void)dismiss {
    [instance dismiss];
    [NSObject cancelPreviousPerformRequestsWithTarget:instance selector:@selector(dismiss) object:nil];
}

@end

@implementation WKPhotoAlbumUtils

+ (PHImageRequestID)readImageByAsset:(PHAsset *)asset size:(CGSize)size deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode contentModel:(PHImageContentMode)contentModel synchronous:(BOOL)synchronous complete:(void (^)(UIImage * _Nullable))complete {
    
    PHImageRequestOptions *imageOptions = [PHImageRequestOptions new];
    imageOptions.deliveryMode = deliveryMode;
    imageOptions.synchronous = synchronous;

    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:contentModel options:imageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (!synchronous) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result) {
                    complete(result);
                } else {
                    complete(nil);
                }
            });
        } else {
            if (result) {
                complete(result);
            } else {
                complete(nil);
            }
        }
    }];
}

+ (NSDictionary *)readSmartAlbumInConfig {
    
    PHFetchResult<PHAssetCollection *> *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        PHFetchOptions *fetchResoultOption = [[PHFetchOptions alloc] init];
        fetchResoultOption.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:false]];
        PHFetchResult *asset = [PHAsset fetchAssetsInAssetCollection:collection options:fetchResoultOption];
        
        if (asset.count == 0 || !asset) continue;
        NSMutableArray *assetArr = [NSMutableArray array];
        WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
        [asset enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.mediaType == PHAssetMediaTypeVideo && config.isIncludeVideo) {
                [assetArr addObject:obj];
            }
            if (obj.mediaType == PHAssetMediaTypeImage && config.isIncludeImage) {
                [assetArr addObject:obj];
            }
        }];
        return @{@"collection": collection,
                 @"asset": assetArr};
    }
    return nil;
}

+ (UIColor *)r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a {
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a];
}

+ (UIImage *)imageName:(NSString *)imageName {
    CGFloat scale = [UIScreen mainScreen].scale;
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"WKPhotoAlbum" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *path;
    if (ABS(scale - 3) <= 0.001) {
        path = [bundle pathForResource:[NSString stringWithFormat:@"%@@3x", imageName] ofType:@"png"];
    } else if (ABS(scale - 2) <= 0.001) {
        path = [bundle pathForResource:[NSString stringWithFormat:@"%@@2x", imageName] ofType:@"png"];
    } else {
        path = [bundle pathForResource:imageName ofType:@"png"];
    }
    return [UIImage imageWithContentsOfFile:path];
}

@end
