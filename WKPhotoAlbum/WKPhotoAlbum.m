//
//  WKPhotoAlbum.m
//  WKProject
//
//  Created by mac on 2018/10/12.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbum.h"
#import "WKPhotoAlbumViewController.h"
#import "WKPhotoCollectionViewController.h"

@implementation WKPhotoAlbum

+ (UIViewController *)presentAlbumVC {
    return [self presentAlbumVCWithSelectBlock:nil cancelBlock:nil];
}
+ (UIViewController *)presentAlbumVCWithSelectBlock:(void (^)(NSArray * _Nonnull))selectBlock cancelBlock:(void (^)(void))cancelBlock {
    [WKPhotoAlbumConfig sharedConfig].selectBlock = [selectBlock copy];
    [WKPhotoAlbumConfig sharedConfig].cancelBlock = [cancelBlock copy];
    [WKPhotoAlbumConfig sharedConfig].fromVC = nil;

    WKPhotoAlbumViewController *rootVC = [[WKPhotoAlbumViewController alloc] init];
    UINavigationController *navitionController = [[UINavigationController alloc] initWithRootViewController:rootVC];WKPhotoCollectionViewController *allPhotoVC = [[WKPhotoCollectionViewController alloc] init];
    [navitionController pushViewController:allPhotoVC animated:NO];
    [navitionController setNavigationBarHidden:YES];
    return navitionController;
}

+ (void)setPhotoAlbumDelegate:(id<WKPhotoAlbumDelegate>)delegate {
    [WKPhotoAlbumConfig sharedConfig].delegate = delegate;
}

@end
