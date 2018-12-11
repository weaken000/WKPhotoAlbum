//
//  WKPhotoAlbumConfig.h
//  WKProject
//
//  Created by mac on 2018/10/12.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WKPhotoAlbumDelegate <NSObject>

@optional
- (void)photoAlbumDidSelectResult:(NSArray *)result;

- (void)photoAlbumCancelSelect;

@end

@interface WKPhotoAlbumConfig : NSObject

+ (WKPhotoAlbumConfig *)sharedConfig;

+ (void)resetConfig;

+ (void)clearReback;

//default is 20
@property (nonatomic, strong) UIFont  *naviTitleFont;
//default is 14
@property (nonatomic, strong) UIFont  *naviItemFont;
//default is r:42 g:42 b:42 a:0.8
@property (nonatomic, strong) UIColor *naviBgColor;
//default is white
@property (nonatomic, strong) UIColor *naviTitleColor;
//default is [UIColor colorWithWhite:0.7 alpha:0.7]
@property (nonatomic, strong) UIColor *unEnableTitleColor;
//default is r:39 g:170 b:45 a:1.0
@property (nonatomic, strong) UIColor *selectColor;
//default is r:27 g:81 b:28 a:1.0
@property (nonatomic, strong) UIColor *unSelectColor;
//default is r:42 g:47 b:55 a:1.0
@property (nonatomic, strong) UIColor *bottomBarColorWhileCollect;
//default is r:42 g:42 b:42 a:0.8
@property (nonatomic, strong) UIColor *bottomBarColorWhilePreview;
//default is NO
@property (nonatomic, assign) BOOL isIncludeVideo;
//default is YES
@property (nonatomic, assign) BOOL isIncludeImage;
//default is 1, max is 6
@property (nonatomic, assign) NSUInteger maxSelectCount;
//default is NO
@property (nonatomic, assign) BOOL canClip;
//default is 4
@property (nonatomic, assign) NSUInteger numberOfLine;
//default is 5
@property (nonatomic, assign) CGFloat lineSpace;
//default is YES
@property (nonatomic, assign) BOOL allowTakePicture;
//default is NO, it works while isIncludeVideo is yes
@property (nonatomic, assign) BOOL allowTakeVideo;
//default is 20s
@property (nonatomic, assign) NSTimeInterval videoMaxRecordTime;

@property (nonatomic, copy  , nullable) void (^ selectBlock)(NSArray *result);

@property (nonatomic, copy  , nullable) void (^ cancelBlock)(void);

@property (nonatomic, weak  , nullable) id<WKPhotoAlbumDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
