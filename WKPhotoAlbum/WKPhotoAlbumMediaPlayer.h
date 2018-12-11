//
//  WKPhotoAlbumMediaPlayer.h
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/9.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoAlbumMediaPlayer : UIView

@property (nonatomic, assign, readonly, getter=isPlaying) BOOL playing;

- (void)playInContainer:(UIView *)container withPlayerItem:(AVPlayerItem *)playerItem;

- (void)cancelPlay;

- (void)play;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
