//
//  UIView+Impk.h
//  ImpressionKit-OC
//
//  Created by Dwarven on 2023/8/3.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ImpkState) {
    ImpkStateUnknown = 0,
    ImpkStateImpressed,
    ImpkStateInScreen,
    ImpkStateOutOfScreen,
    ImpkStateNoWindow,
    ImpkStateViewControllerDidDisappear,
    ImpkStateDidEnterBackground,
    ImpkStateWillResignActive,
};

typedef NS_OPTIONS(NSInteger, ImpkRedetectOption) {
    ImpkRedetectOptionUnknown = 0,
    ImpkRedetectOptionLeftScreen = 1 << 0,
    ImpkRedetectOptionViewControllerDidDisappear = 1 << 1,
    ImpkRedetectOptionDidEnterBackground = 1 << 2,
    ImpkRedetectOptionWillResignActive = 1 << 3,
};

typedef NS_OPTIONS(NSInteger, ImpkUnimpressedOutOfScreenOption) {
    ImpkUnimpressedOutOfScreenOptionUnknown = 0,
    ImpkUnimpressedOutOfScreenOptionDidEnterBackground = 1 << 0,
    ImpkUnimpressedOutOfScreenOptionWillResignActive = 1 << 1,
};

NS_ASSUME_NONNULL_BEGIN

@interface ImpkStateModel : NSObject

@property (nonatomic, assign) ImpkState state;
/// not nil when state is ImpkStateImpressed or ImpkStateInScreen
@property (nonatomic, strong) NSDate *date;
/// not 0 when state is ImpkStateImpressed
@property (nonatomic, assign) CGFloat areaRatio;

+ (ImpkStateModel *)modelWithState:(ImpkState)state;

@end

@interface UIView (Impk)

@property (nonatomic, assign, class) CGFloat impk_areaRatioThreshold;
@property (nonatomic, copy, nullable) NSNumber *impk_areaRatioThreshold;
@property (nonatomic, assign, class) CGFloat impk_durationThreshold;
@property (nonatomic, copy, nullable) NSNumber *impk_durationThreshold;
@property (nonatomic, assign, class) CGFloat impk_detectionInterval;
@property (nonatomic, copy, nullable) NSNumber *impk_detectionInterval;
@property (nonatomic, assign, class) ImpkRedetectOption impk_redetectOptions;
@property (nonatomic, assign) ImpkRedetectOption impk_redetectOptions;
@property (nonatomic, assign, class) ImpkUnimpressedOutOfScreenOption impk_unimpressedOutOfScreenOptions;
@property (nonatomic, assign) ImpkUnimpressedOutOfScreenOption impk_unimpressedOutOfScreenOptions;
@property (nonatomic, copy, nullable) NSNumber *impk_topEdgeInset;
@property (nonatomic, copy, nullable) NSNumber *impk_leftEdgeInset;
@property (nonatomic, copy, nullable) NSNumber *impk_bottomEdgeInset;
@property (nonatomic, copy, nullable) NSNumber *impk_rightEdgeInset;
@property (nonatomic, strong, readonly) ImpkStateModel *impk_state;

- (void)impk_detectImpression:(nullable void(^)(UIView *view, ImpkStateModel *state))block;
- (void)impk_detectImpression:(nullable void(^)(UIView *view, ImpkStateModel *state))block state:(nullable ImpkStateModel *)state;
- (void)impk_redetect;
- (BOOL)impk_isRedetectionOn:(ImpkRedetectOption)option;
- (BOOL)impk_isUnimpressedOutOfScreenOn:(ImpkUnimpressedOutOfScreenOption)option;
- (void)impk_stopTimer;

@end

NS_ASSUME_NONNULL_END
