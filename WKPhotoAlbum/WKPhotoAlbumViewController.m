//
//  WKPhotoAlbumViewController.m
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <Photos/Photos.h>

#import "WKPhotoAlbumViewController.h"
#import "WKPhotoCollectionViewController.h"

#import "WKPhotoAlbumUtils.h"
#import "WKPhotoAlbumCell.h"

#import "WKPhotoAlbumConfig.h"

@interface WKPhotoAlbumViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *assetCollection;

@end

@implementation WKPhotoAlbumViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    [self readPhotoCollect];
    [self setupSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"相册";
    UIButton *backButton = [[UIButton alloc] init];
    [backButton setImage:[UIImage imageNamed:@"login_icon_back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(click_backButton) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0, 0, 50, 44);
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _tableView.frame = self.view.bounds;
}

- (void)setupSubviews {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    _tableView.rowHeight = 120;
    [self.view addSubview:_tableView];
}

- (void)click_backButton {
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];
    if ([config.delegate respondsToSelector:@selector(photoAlbumCancelSelect)]) {
        [config.delegate photoAlbumCancelSelect];
    }
    if (config.cancelBlock) {
        config.cancelBlock();
    }
    [WKPhotoAlbumConfig clearReback];
    
    if (self.navigationController.childViewControllers.firstObject == self) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - About PhotoCollect
- (void)readPhotoCollect {
    
    self.assetCollection = [NSMutableArray array];
    WKPhotoAlbumConfig *config = [WKPhotoAlbumConfig sharedConfig];

    //系统相册
    PHFetchResult<PHAssetCollection *> *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        PHFetchResult *asset = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        if (asset.count == 0 || !asset) continue;
        NSMutableArray<PHAsset *> *assets = [NSMutableArray array];
        [asset enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.mediaType == PHAssetMediaTypeVideo && config.isIncludeVideo) {
                [assets addObject:obj];
            }
            if (obj.mediaType == PHAssetMediaTypeImage && config.isIncludeImage) {
                [assets addObject:obj];
            }
            if (obj.mediaType == PHAssetMediaTypeAudio && config.isIncludeAudio) {
                [assets addObject:obj];
            }
        }];
        if (!assets.count) continue;
        [WKPhotoAlbumUtils readImageByAsset:assets.firstObject size:CGSizeMake(150, 150) deliveryMode:0 contentModel:PHImageContentModeAspectFit synchronous:YES complete:^(UIImage * _Nonnull image) {
            [self.assetCollection addObject:@{@"collection": collection,
                                              @"asset": assets,
                                              @"cover": image}];
        }];
    }
    
    //自定义相册
    PHFetchResult<PHAssetCollection *> *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in albums) {
        
        PHFetchResult<PHAsset *> *asset = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        if (!asset || !asset.count) continue;
        NSMutableArray<PHAsset *> *assets = [NSMutableArray array];
        [asset enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.mediaType == PHAssetMediaTypeVideo && config.isIncludeVideo) {
                [assets addObject:obj];
            }
            if (obj.mediaType == PHAssetMediaTypeImage && config.isIncludeImage) {
                [assets addObject:obj];
            }
            if (obj.mediaType == PHAssetMediaTypeAudio && config.isIncludeAudio) {
                [assets addObject:obj];
            }
        }];
        if (!assets.count) continue;
        [WKPhotoAlbumUtils readImageByAsset:assets.firstObject size:CGSizeMake(100, 100) deliveryMode:0 contentModel:PHImageContentModeAspectFit synchronous:YES complete:^(UIImage * _Nonnull image) {
            [self.assetCollection addObject:@{@"collection": collection,
                                              @"asset": assets,
                                              @"cover": image}];
        }];
    }

    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.assetCollection.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WKPhotoAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"assetCell"];
    if (!cell) {
        cell = [[WKPhotoAlbumCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"assetCell"];
    }
    NSDictionary *dict = self.assetCollection[indexPath.row];
    NSMutableArray<PHAsset *> *assets = dict[@"asset"];
    PHAssetCollection *collection = dict[@"collection"];
    
    cell.albumTitleLabel.text      = collection.localizedTitle?:@"";
    cell.albumCountLabel.text      = [NSString stringWithFormat:@"%zd", assets.count];
    cell.albumCoverImageView.image = dict[@"cover"];
    return cell;
}

#pragma mark -
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WKPhotoCollectionViewController *next = [[WKPhotoCollectionViewController alloc] init];
    next.assetDict = self.assetCollection[indexPath.row];
    [self.navigationController pushViewController:next animated:YES];
}

@end


