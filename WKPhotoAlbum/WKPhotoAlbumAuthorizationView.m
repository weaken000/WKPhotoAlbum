//
//  WKPhotoAlbumAuthorizationView.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/23.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumAuthorizationView.h"
#import "WKPhotoAlbumUtils.h"

@implementation WKPhotoAlbumAuthorizationView {
    UIButton           *_requestAlbumBtn;
    UIButton           *_reqeustCameraBtn;
    UIButton           *_reqeustMicBtn;
    UIButton           *_jumpToSettingBtn;
    UILabel            *_deniedTipLabel;
    UIImageView        *_deniedTipImageView;
    WKAuthorizationType _type;
}

- (void)requestAuthorizationForType:(WKAuthorizationType)type handle:(void (^)(PHAuthorizationStatus, AVAuthorizationStatus, AVAuthorizationStatus))handle {
    _type = type;
    if (type == WKAuthorizationTypeAlbum) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        [self configAlbumAuthStatus:status];
        handle(status, AVAuthorizationStatusAuthorized, AVAuthorizationStatusAuthorized);
    } else if (type == WKAuthorizationTypeVideo) {
        AVAuthorizationStatus cameraStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        AVAuthorizationStatus micStatus    = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        [self configCameraStatus:cameraStatus micStatus:micStatus];
        handle(0, cameraStatus, micStatus);
    } else {
        AVAuthorizationStatus cameraStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        [self configCameraStatus:cameraStatus micStatus:AVAuthorizationStatusAuthorized];
        handle(0, cameraStatus, AVAuthorizationStatusAuthorized);
    }
}

- (void)configAlbumAuthStatus:(PHAuthorizationStatus)authStatus {
    self.albumStatus = authStatus;
    if (authStatus == PHAuthorizationStatusAuthorized) {
        self.hidden = YES;
    } else if (authStatus == PHAuthorizationStatusDenied || authStatus == PHAuthorizationStatusRestricted) {
        _requestAlbumBtn.hidden = YES;
        if (!_jumpToSettingBtn) {
            _deniedTipLabel = [[UILabel alloc] init];
            _deniedTipLabel.textAlignment = NSTextAlignmentCenter;
            _deniedTipLabel.numberOfLines = 0;
            _deniedTipLabel.font = [UIFont systemFontOfSize:18];
            _deniedTipLabel.textColor = [UIColor blackColor];
            _deniedTipLabel.text = @"获取相册被拒绝，请在iPhone的\"设置-隐私-照片\"中允许访问照片";
            [self addSubview:_deniedTipLabel];
            
            _deniedTipImageView = [[UIImageView alloc] init];
            _deniedTipImageView.image = [WKPhotoAlbumUtils imageName:@"wk_auth_lock"];
            [self addSubview:_deniedTipImageView];
            
            _jumpToSettingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            _jumpToSettingBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
            [_jumpToSettingBtn setTitle:@"前往设置" forState:UIControlStateNormal];
            [_jumpToSettingBtn addTarget:self action:@selector(click_jumpToSetting) forControlEvents:UIControlEventTouchUpInside];
            [_jumpToSettingBtn sizeToFit];
            [self addSubview:_jumpToSettingBtn];
            
            _deniedTipImageView.frame = CGRectMake(0, 0, 120, 120);
            _deniedTipImageView.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 60);
            _jumpToSettingBtn.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(_deniedTipImageView.frame) + 30);
            CGSize labelSize = [_deniedTipLabel sizeThatFits:CGSizeMake(self.frame.size.width - 60, CGFLOAT_MAX)];
            _deniedTipLabel.frame = CGRectMake((self.frame.size.width - labelSize.width) * 0.5, CGRectGetMinY(_deniedTipImageView.frame) - 20 - labelSize.height, labelSize.width, labelSize.height);
            
        }
        _jumpToSettingBtn.hidden = NO;
        _deniedTipLabel.hidden = NO;
        _deniedTipImageView.hidden = NO;
        self.hidden = NO;
    } else {
        _jumpToSettingBtn.hidden = YES;
        _deniedTipLabel.hidden = YES;
        _deniedTipImageView.hidden = YES;
        if (!_requestAlbumBtn) {
            _requestAlbumBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            _requestAlbumBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
            [_requestAlbumBtn setTitle:@"开启相册权限" forState:UIControlStateNormal];
            [_requestAlbumBtn addTarget:self action:@selector(click_requestAlbumBtn) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_requestAlbumBtn];
            [_requestAlbumBtn sizeToFit];
            _requestAlbumBtn.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        }
        _requestAlbumBtn.hidden = NO;
        self.hidden = NO;
    }
}

- (void)configCameraStatus:(AVAuthorizationStatus)cameraStatus micStatus:(AVAuthorizationStatus)micStatus {
    _cameraStatus = cameraStatus;
    _micStatus    = micStatus;
    if (cameraStatus == AVAuthorizationStatusAuthorized && micStatus == AVAuthorizationStatusAuthorized) {
        self.hidden = YES;
        return;
    }
    
    if (!_reqeustCameraBtn) {
        _reqeustCameraBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _reqeustCameraBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [self addSubview:_reqeustCameraBtn];
    }
    if (cameraStatus == AVAuthorizationStatusNotDetermined) {//未请求
        [_reqeustCameraBtn setTitle:@"获取相机权限" forState:UIControlStateNormal];
        [_reqeustCameraBtn addTarget:self action:@selector(click_requestCameraBtn) forControlEvents:UIControlEventTouchUpInside];
    } else if (cameraStatus == AVAuthorizationStatusAuthorized) {
        _reqeustCameraBtn.hidden = YES;
    } else {//拒绝
        [_reqeustCameraBtn setTitle:@"前往设置，开启相机权限" forState:UIControlStateNormal];
        [_reqeustCameraBtn addTarget:self action:@selector(click_jumpToSetting) forControlEvents:UIControlEventTouchUpInside];
    }
    [_reqeustCameraBtn sizeToFit];
    if (_type == WKAuthorizationTypeImage) {
        _reqeustCameraBtn.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        return;
    }
    _reqeustCameraBtn.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 20);

    if (!_reqeustMicBtn) {
        _reqeustMicBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _reqeustMicBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [self addSubview:_reqeustMicBtn];
    }
    if (micStatus == AVAuthorizationStatusNotDetermined) {//未请求
        [_reqeustMicBtn setTitle:@"获取麦克风权限" forState:UIControlStateNormal];
        [_reqeustMicBtn addTarget:self action:@selector(click_requestMicBtn) forControlEvents:UIControlEventTouchUpInside];
    } else if (micStatus == AVAuthorizationStatusAuthorized) {
        _reqeustMicBtn.hidden = YES;
    }  else {//拒绝
        [_reqeustMicBtn setTitle:@"前往设置，开启麦克风权限" forState:UIControlStateNormal];
        [_reqeustMicBtn addTarget:self action:@selector(click_jumpToSetting) forControlEvents:UIControlEventTouchUpInside];
    }
    [_reqeustMicBtn sizeToFit];
    _reqeustMicBtn.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) + 20);
}

- (void)click_requestAlbumBtn {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configAlbumAuthStatus:status];
            if (self.authChanged && status == PHAuthorizationStatusAuthorized) {
                self.authChanged(status, 0, 0);
            }
        });
    }];
}

- (void)click_requestCameraBtn {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AVAuthorizationStatus micAuth = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
            if (granted) {
                [self configCameraStatus:AVAuthorizationStatusAuthorized micStatus:micAuth];
                if (self.authChanged) {
                    self.authChanged(0, AVAuthorizationStatusAuthorized, micAuth);
                }
            } else {
                [self configCameraStatus:AVAuthorizationStatusDenied micStatus:micAuth];
            }
        });
    }];
}

- (void)click_requestMicBtn {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AVAuthorizationStatus cameraAuth = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (granted) {
                [self configCameraStatus:cameraAuth micStatus:AVAuthorizationStatusAuthorized];
                if (self.authChanged) {
                    self.authChanged(0, cameraAuth, AVAuthorizationStatusAuthorized);
                }
            } else {
                [self configCameraStatus:cameraAuth micStatus:AVAuthorizationStatusDenied];
            }
        });
    }];
}

- (void)click_jumpToSetting {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {}];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end
