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
//default is NO
@property (nonatomic, assign) BOOL isIncludeVideo;
//default is NO
@property (nonatomic, assign) BOOL isIncludeAudio;
//default is YES
@property (nonatomic, assign) BOOL isIncludeImage;
//default is 1
@property (nonatomic, assign) NSUInteger maxSelectCount;
//default is NO
@property (nonatomic, assign) BOOL canClipWhileSingle;

@property (nonatomic, copy  , nullable) void (^ selectBlock)(NSArray *result);

@property (nonatomic, copy  , nullable) void (^ cancelBlock)(void);

@property (nonatomic, weak  , nullable) id<WKPhotoAlbumDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
