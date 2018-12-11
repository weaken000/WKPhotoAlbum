//
//  WKPhotoPreviewTransition.h
//  WKProject
//
//  Created by mac on 2018/10/11.
//  Copyright © 2018 weikun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKPhotoPreviewTransition : NSObject<UIViewControllerAnimatedTransitioning>

+ (WKPhotoPreviewTransition *)animationWithAnimationControllerForOperation:(UINavigationControllerOperation)operation completed:(nullable void(^)(void))completed;

@end

NS_ASSUME_NONNULL_END
