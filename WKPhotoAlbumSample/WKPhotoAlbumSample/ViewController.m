//
//  ViewController.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/10/17.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "ViewController.h"
#import "WKPhotoAlbum.h"

@interface ViewController ()<WKPhotoAlbumDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *modalBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [modalBtn setTitle:@"modal To Album" forState:UIControlStateNormal];
    [modalBtn addTarget:self action:@selector(click_modalBtn) forControlEvents:UIControlEventTouchUpInside];
    [modalBtn sizeToFit];
    [self.view addSubview:modalBtn];

    modalBtn.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame) + 30);
}

- (void)click_modalBtn {
    [WKPhotoAlbumConfig sharedConfig].maxSelectCount = 3;
    [WKPhotoAlbumConfig sharedConfig].allowTakeVideo = YES;
    [WKPhotoAlbumConfig sharedConfig].canClip = NO;
    [WKPhotoAlbum setPhotoAlbumDelegate:self];
    UIViewController *next = [WKPhotoAlbum presentAlbumVCWithSelectBlock:^(NSArray * _Nonnull result) {
        NSLog(@"blockSelect--%@", result);
    } cancelBlock:^{
        NSLog(@"blockCancel");
    }];
    [self presentViewController:next animated:YES completion:nil];
}


#pragma mark - WKPhotoAlbumDelegate
- (void)photoAlbumDidSelectResult:(NSArray *)result {
    NSLog(@"delegateSelect-%@", result);
}
- (void)photoAlbumCancelSelect {
    NSLog(@"delegateCancel");
    
}

@end
