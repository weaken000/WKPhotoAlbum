//
//  WKPhotoAlbumConfig.m
//  WKProject
//
//  Created by mac on 2018/10/12.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumConfig.h"

@implementation WKPhotoAlbumConfig

+ (WKPhotoAlbumConfig *)sharedConfig {
    static dispatch_once_t onceToken;
    static WKPhotoAlbumConfig *config;
    dispatch_once(&onceToken, ^{
        config = [[WKPhotoAlbumConfig alloc] init];
        config.naviBarTintColor = [UIColor whiteColor];
        config.naviTitleColor = [UIColor whiteColor];
        config.naviTitleFont = [UIFont systemFontOfSize:20];
        config.naviItemFont = [UIFont systemFontOfSize:16];
        config.isIncludeAudio = NO;
        config.isIncludeImage = YES;
        config.isIncludeVideo = YES;
        config.maxSelectCount = 1;
        config.canClipWhileSingle = NO;
        config.imageDeliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        config.videoDeliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    });
    return config;
}

+ (void)resetConfig {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    config = [[WKPhotoAlbumConfig alloc] init];
    config.naviBarTintColor = [UIColor whiteColor];
    config.naviTitleColor = [UIColor blackColor];
    config.naviTitleFont = [UIFont systemFontOfSize:20];
    config.naviItemFont = [UIFont systemFontOfSize:16];
    config.isIncludeAudio = NO;
    config.isIncludeImage = YES;
    config.isIncludeVideo = YES;
    config.maxSelectCount = 1;
    config.canClipWhileSingle = NO;
    config.imageDeliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    config.videoDeliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
}

+ (void)clearReback {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    config.selectBlock = nil;
    config.cancelBlock = nil;
    config.delegate = nil;
    config.fromVC = nil;
}

@end
