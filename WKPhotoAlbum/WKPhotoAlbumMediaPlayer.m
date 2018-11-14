//
//  WKPhotoAlbumMediaPlayer.m
//  WKPhotoAlbumSample
//
//  Created by mac on 2018/11/9.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoAlbumMediaPlayer.h"
#import "WKPhotoAlbumUtils.h"

@implementation WKPhotoAlbumMediaPlayer {
    AVPlayer      *_player;
    AVPlayerLayer *_playerLayer;
    UIButton      *_playControl;
}

- (void)playInContainer:(UIView *)container withPlayerItem:(AVPlayerItem *)playerItem {
    self.frame = container.bounds;
    [container addSubview:self];
    
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:playerItem.asset];
    _player = [AVPlayer playerWithPlayerItem:item];
    if (!_playerLayer) {
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        [self.layer addSublayer:_playerLayer];
    } else {
        _playerLayer.player = _player;
    }
    _playerLayer.frame = self.bounds;
    
    if (!_playControl) {
        _playControl = [[UIButton alloc] init];
        [_playControl addTarget:self action:@selector(click_videoControl) forControlEvents:UIControlEventTouchUpInside];
        [_playControl setBackgroundImage:[WKPhotoAlbumUtils imageName:@"wk_video_play"] forState:UIControlStateNormal];
        [self addSubview:_playControl];
    }
    _playControl.frame = CGRectMake((self.bounds.size.width - 75) / 2.0,
                                    (self.bounds.size.height - 75) / 2.0,
                                    75, 75);
    
    _playing = NO;
    [self addNotification];
}

- (void)cancelPlay {
    [self removeFromSuperview];

    [self removeNotification];
    [_player pause];
    _player = nil;
    [_playControl setBackgroundImage:[WKPhotoAlbumUtils imageName:@"wk_video_play"] forState:UIControlStateNormal];
    _playing = NO;
}

- (void)play {
    if (!self.isPlaying) {
        [_player play];
        [_playControl setBackgroundImage:[WKPhotoAlbumUtils imageName:@"wk_video_pause"] forState:UIControlStateNormal];
        _playing = YES;
    }
}

- (void)stop {
    if (self.isPlaying) {
        [_player pause];
        [_playControl setBackgroundImage:[WKPhotoAlbumUtils imageName:@"wk_video_play"] forState:UIControlStateNormal];
        _playing = NO;
    }
}

- (void)click_videoControl {
    if (self.isPlaying) {
        [_player pause];
        [_playControl setBackgroundImage:[WKPhotoAlbumUtils imageName:@"wk_video_play"] forState:UIControlStateNormal];
    } else {
        [_player play];
        [_playControl setBackgroundImage:[WKPhotoAlbumUtils imageName:@"wk_video_pause"] forState:UIControlStateNormal];
    }
    _playing = !_playing;
}

#pragma mark - Observer & Notification
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    [_player removeObserver:self forKeyPath:@"status"];
}

- (void)appDidEnterBackground {
    if (self.isPlaying) {
        [_playControl setBackgroundImage:[WKPhotoAlbumUtils imageName:@"wk_video_play"] forState:UIControlStateNormal];
        [_player pause];
    }
}

- (void)appDidEnterPlayGround {
    if (self.isPlaying) {
        [_playControl setBackgroundImage:[WKPhotoAlbumUtils imageName:@"wk_video_pause"] forState:UIControlStateNormal];
        [_player play];
    }
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    _playing = NO;
    [_playControl setBackgroundImage:[WKPhotoAlbumUtils imageName:@"wk_video_play"] forState:UIControlStateNormal];
    [_player seekToTime:CMTimeMake(0, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {}];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            [self click_videoControl];
        }
    }
}

@end
