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
    SEL fd = NSSelectorFromString(@"fd_fullscreenPopGestureRecognizer");
    if (fd && [self respondsToSelector:fd]) {
        UIGestureRecognizer *gesture = [self valueForKey:@"fd_fullscreenPopGestureRecognizer"];
        gesture.enabled = NO;
    }
    [self setNavigationBarHidden:YES];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    SEL fd = NSSelectorFromString(@"fd_prefersNavigationBarHidden");
    if (fd && [self respondsToSelector:fd]) {
        [viewController setValue:@(YES) forKey:@"fd_prefersNavigationBarHidden"];
    }
    [super pushViewController:viewController animated:animated];
}

@end


@implementation WKPhotoAlbum

+ (UIViewController *)presentAlbumVC {
    return [self presentAlbumVCWithSelectBlock:nil cancelBlock:nil];
}
+ (UIViewController *)presentAlbumVCWithSelectBlock:(void (^)(NSArray * _Nonnull))selectBlock cancelBlock:(void (^)(void))cancelBlock {
    [WKPhotoAlbumConfig sharedConfig].selectBlock = [selectBlock copy];
    [WKPhotoAlbumConfig sharedConfig].cancelBlock = [cancelBlock copy];

    WKPhotoAlbumViewController *rootVC = [[WKPhotoAlbumViewController alloc] init];
    WKPhotoAlbumNavigationController *navitionController = [[WKPhotoAlbumNavigationController alloc] initWithRootViewController:rootVC];
    navitionController.navigationBar.hidden = YES;
    [navitionController setNavigationBarHidden:YES];
    
    WKPhotoCollectionViewController *allPhotoVC = [[WKPhotoCollectionViewController alloc] init];
    [navitionController pushViewController:allPhotoVC animated:NO];
    return navitionController;
}

+ (void)setPhotoAlbumDelegate:(id<WKPhotoAlbumDelegate>)delegate {
    [WKPhotoAlbumConfig sharedConfig].delegate = delegate;
}

@end
