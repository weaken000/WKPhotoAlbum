//
//  WKPhotoAlbumModel.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/6.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumModel.h"

@implementation WKPhotoAlbumModel

- (instancetype)init {
    if (self == [super init]) {
        _collectIndex = -1;
        _selectIndex  = 0;
    }
    return self;
}

@end
