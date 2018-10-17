//
//  WKPhotoCollectionViewController.h
//  WKProject
//
//  Created by mac on 2018/10/10.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoCollectionViewController : UIViewController

@property (nonatomic, strong) NSDictionary *assetDict;

@property (nonatomic, strong, readonly, nullable) UICollectionViewCell *selectCell;

@end

NS_ASSUME_NONNULL_END
