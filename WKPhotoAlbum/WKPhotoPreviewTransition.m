//
//  WKPhotoPreviewTransition.m
//  WKProject
//
//  Created by mac on 2018/10/11.
//  Copyright © 2018 weikun. All rights reserved.
//

#import "WKPhotoPreviewTransition.h"

#import "WKPhotoCollectionViewController.h"
#import "WKPhotoPreviewViewController.h"

@implementation WKPhotoPreviewTransition {
    UINavigationControllerOperation _operation;
    void (^ _transitionCompleted)(void);
}

+ (WKPhotoPreviewTransition *)animationWithAnimationControllerForOperation:(UINavigationControllerOperation)operation completed:(nullable void (^)(void))completed {
    WKPhotoPreviewTransition *transition = [[WKPhotoPreviewTransition alloc] init];
    transition->_operation = operation;
    transition->_transitionCompleted = completed;
    return transition;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.4;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (_operation == UINavigationControllerOperationPush) {
        [self animationForPush:transitionContext];
    } else {
        [self animationForPop:transitionContext];
    }
}

- (void)animationForPush:(id<UIViewControllerContextTransitioning>)transitionContext {
    WKPhotoCollectionViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    WKPhotoPreviewViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *contrainer = transitionContext.containerView;
    toVC.view.backgroundColor = [UIColor whiteColor];
    [contrainer addSubview:toVC.view];
    
    //selectCell shot
    CGRect cellRect = [fromVC.selectCell.superview convertRect:fromVC.selectCell.frame toView:contrainer];
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode  = UIViewContentModeScaleAspectFill;
    imageView.frame        = cellRect;
    UIImage *coverImage    = toVC.coverImage;
    imageView.image        = coverImage;
    [contrainer addSubview:imageView];
    
    CGRect realToRect = [self transitionRectByImage:coverImage imageFrame:[UIScreen mainScreen].bounds];

    toVC.view.alpha = 0.0;
    fromVC.selectCell.hidden = YES;
    [contrainer layoutIfNeeded];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:0.75 initialSpringVelocity:8 options:UIViewAnimationOptionCurveEaseOut animations:^{
        imageView.frame = realToRect;
        toVC.view.alpha = 1.0;
    } completion:^(BOOL finished) {
        if (_transitionCompleted) {
            _transitionCompleted();
        }
        [imageView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

- (void)animationForPop:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    WKPhotoPreviewViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    WKPhotoCollectionViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *contrainer = transitionContext.containerView;
    [contrainer insertSubview:toVC.view atIndex:0];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    UIImage *coverImage    = fromVC.coverImage;
    imageView.image        = coverImage;
    imageView.clipsToBounds = YES;
    imageView.contentMode  = UIViewContentModeScaleAspectFill;
    [contrainer addSubview:imageView];
    
    imageView.frame = [fromVC.dismissPreViewImageView.superview convertRect:fromVC.dismissPreViewImageView.frame toView:contrainer];
    fromVC.dismissPreViewImageView.hidden = YES;
    
    CGRect cellRect = [toVC.selectCell.superview convertRect:toVC.selectCell.frame toView:contrainer];
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        imageView.frame = cellRect;
        fromVC.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        toVC.selectCell.hidden = NO;
        [imageView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

- (CGRect)transitionRectByImage:(UIImage *)image imageFrame:(CGRect)imageFrame {
    CGFloat scale = imageFrame.size.width / image.size.width;
    CGFloat w = scale * image.size.width;
    CGFloat h = scale * image.size.height;
    return CGRectMake(imageFrame.origin.x + (imageFrame.size.width - w) * 0.5, imageFrame.origin.y + (imageFrame.size.height - h) * 0.5, w, h);
}

@end
