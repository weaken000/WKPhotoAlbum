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

@interface WKPhotoAlbumNavigationController: UINavigationController
@end
@implementation WKPhotoAlbumNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];

    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    NSDictionary *attributes   = @{NSForegroundColorAttributeName: config.naviTitleColor,
                                   NSFontAttributeName: config.naviTitleFont};
    [self.navigationBar setTitleTextAttributes:attributes];
    self.navigationBar.barTintColor = config.naviBarTintColor;
    self.navigationBar.tintColor    = config.naviTitleColor;
    self.navigationBar.translucent  = NO;
}

@end


@implementation WKPhotoAlbum

+ (UIViewController *)presentAlbumVC {
    return [self presentAlbumVCWithSelectBlock:nil cancelBlock:nil];
}
+ (UIViewController *)presentAlbumVCWithSelectBlock:(void (^)(NSArray * _Nonnull))selectBlock cancelBlock:(void (^)(void))cancelBlock {
    [WKPhotoAlbumConfig sharedConfig].selectBlock = [selectBlock copy];
    [WKPhotoAlbumConfig sharedConfig].cancelBlock = [cancelBlock copy];
    [WKPhotoAlbumConfig sharedConfig].fromVC = nil;

    WKPhotoAlbumViewController *rootVC = [[WKPhotoAlbumViewController alloc] init];
    WKPhotoAlbumNavigationController *navitionController = [[WKPhotoAlbumNavigationController alloc] initWithRootViewController:rootVC];WKPhotoCollectionViewController *allPhotoVC = [[WKPhotoCollectionViewController alloc] init];
    [navitionController pushViewController:allPhotoVC animated:NO];
    return navitionController;
}

+ (UIViewController *)pushAlbumVC {
    return [self pushAlbumVCWithSelectBlock:nil cancelBlock:nil];
}
+ (UIViewController *)pushAlbumVCWithSelectBlock:(void (^)(NSArray * _Nonnull))selectBlock cancelBlock:(void (^)(void))cancelBlock {
    [WKPhotoAlbumConfig sharedConfig].selectBlock = [selectBlock copy];
    [WKPhotoAlbumConfig sharedConfig].cancelBlock = [cancelBlock copy];
    WKPhotoCollectionViewController *rootVC = [[WKPhotoCollectionViewController alloc] init];
    return rootVC;
}

+ (void)setPhotoAlbumDelegate:(id<WKPhotoAlbumDelegate>)delegate {
    [WKPhotoAlbumConfig sharedConfig].delegate = delegate;
}

@end
