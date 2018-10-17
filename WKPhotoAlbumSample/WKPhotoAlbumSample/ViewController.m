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

    UIButton *pushBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [pushBtn setTitle:@"push To Album" forState:UIControlStateNormal];
    [pushBtn addTarget:self action:@selector(click_pushBtn) forControlEvents:UIControlEventTouchUpInside];
    [pushBtn sizeToFit];
    [self.view addSubview:pushBtn];
    
    UIButton *modalBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [modalBtn setTitle:@"modal To Album" forState:UIControlStateNormal];
    [modalBtn addTarget:self action:@selector(click_modalBtn) forControlEvents:UIControlEventTouchUpInside];
    [modalBtn sizeToFit];
    [self.view addSubview:modalBtn];
    
    pushBtn.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame) - 30);
    modalBtn.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame) + 30);
}

- (void)click_modalBtn {
    [WKPhotoAlbumConfig sharedConfig].maxSelectCount = 3;
    [WKPhotoAlbum setPhotoAlbumDelegate:self];
    UIViewController *next = [WKPhotoAlbum presentAlbumVC];
    [self presentViewController:next animated:YES completion:nil];
}

- (void)click_pushBtn {
    [WKPhotoAlbumConfig sharedConfig].maxSelectCount = 1;
    UIViewController *next = [WKPhotoAlbum pushAlbumVCWithSelectBlock:^(NSArray * _Nonnull result) {
        NSLog(@"select-%@", result);
    } cancelBlock:^{
        NSLog(@"cancel");
    }];
    [self.navigationController pushViewController:next animated:YES];
}


#pragma mark - WKPhotoAlbumDelegate
- (void)photoAlbumDidSelectResult:(NSArray *)result {
    NSLog(@"select-%@", result);
}
- (void)photoAlbumCancelSelect {
    NSLog(@"cancel");
}

@end
