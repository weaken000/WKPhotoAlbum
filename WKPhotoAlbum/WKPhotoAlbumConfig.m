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
        config.naviTitleFont = [UIFont systemFontOfSize:20];
        config.naviItemFont  = [UIFont systemFontOfSize:16];
        config.naviBgColor = [UIColor colorWithRed:42 / 255.0 green:42 / 255.0 blue:42 / 255.0 alpha:0.8];
        config.naviTitleColor = [UIColor whiteColor];
        config.isIncludeAudio = NO;
        config.isIncludeImage = YES;
        config.isIncludeVideo = YES;
        config.maxSelectCount = 1;
        config.canClipWhileSingle = NO;
        config.numberOfLine = 4;
        config.lineSpace = 5;
        config.selectColor = [UIColor colorWithRed:39 / 255.0 green:170 / 255.0 blue:45 / 255.0 alpha:1.0];
        config.bottomBarColorWhileCollect = [UIColor colorWithRed:42 / 255.0 green:47 / 255.0 blue:55 / 255.0 alpha:1.0];
        config.bottomBarColorWhilePreview = [UIColor colorWithRed:42 / 255.0 green:42 / 255.0 blue:42 / 255.0 alpha:0.8];
        config.unSelectColor = [UIColor colorWithRed:27 / 255.0 green:81 / 255.0 blue:28 / 255.0 alpha:1.0];
        config.unEnableTitleColor = [UIColor colorWithWhite:0.7 alpha:0.7];
    });
    return config;
}

+ (void)resetConfig {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    config.naviTitleFont = [UIFont systemFontOfSize:20];
    config.naviItemFont  = [UIFont systemFontOfSize:16];
    config.naviBgColor = [UIColor colorWithRed:42 / 255.0 green:42 / 255.0 blue:42 / 255.0 alpha:0.8];
    config.naviTitleColor = [UIColor whiteColor];
    config.isIncludeAudio = NO;
    config.isIncludeImage = YES;
    config.isIncludeVideo = YES;
    config.maxSelectCount = 1;
    config.canClipWhileSingle = NO;
    config.numberOfLine = 4;
    config.lineSpace = 5;
    config.selectColor = [UIColor colorWithRed:39 / 255.0 green:170 / 255.0 blue:45 / 255.0 alpha:1.0];
    config.bottomBarColorWhileCollect = [UIColor colorWithRed:42 / 255.0 green:47 / 255.0 blue:55 / 255.0 alpha:1.0];
    config.bottomBarColorWhilePreview = [UIColor colorWithRed:42 / 255.0 green:42 / 255.0 blue:42 / 255.0 alpha:0.8];
    config.unSelectColor = [UIColor colorWithRed:27 / 255.0 green:81 / 255.0 blue:28 / 255.0 alpha:1.0];
    config.unEnableTitleColor = [UIColor colorWithWhite:0.7 alpha:0.7];
}

+ (void)clearReback {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    config.selectBlock = nil;
    config.cancelBlock = nil;
    config.delegate = nil;
}

@end
