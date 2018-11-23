//
//  WKPhotoAlbumAuthorizationView.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/23.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    WKAuthorizationTypeAlbum,
    WKAuthorizationTypeVideo,
    WKAuthorizationTypeImage
} WKAuthorizationType;

@interface WKPhotoAlbumAuthorizationView : UIView

@property (nonatomic, copy, nullable) void (^ authChanged)(PHAuthorizationStatus albumStatus, AVAuthorizationStatus cameraStatus, AVAuthorizationStatus micStatus);

@property (nonatomic, assign) PHAuthorizationStatus albumStatus;

@property (nonatomic, assign) AVAuthorizationStatus cameraStatus;

@property (nonatomic, assign) AVAuthorizationStatus micStatus;

- (void)requestAuthorizationForType:(WKAuthorizationType)type
                             handle:(void (^)(PHAuthorizationStatus albumStatus,
                                              AVAuthorizationStatus cameraStatus,
                                              AVAuthorizationStatus micStatus))handle;

@end

NS_ASSUME_NONNULL_END
