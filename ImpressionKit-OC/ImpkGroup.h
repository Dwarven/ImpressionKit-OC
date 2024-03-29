//
//  ImpkGroup.h
//  ImpressionKit-OC
//
//  Created by Dwarven on 2023/8/3.
//

#import "UIView+Impk.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImpkGroup : NSObject

@property (nonatomic, copy) NSNumber *detectionInterval;
@property (nonatomic, copy) NSNumber *durationThreshold;
@property (nonatomic, copy) NSNumber *areaRatioThreshold;
@property (nonatomic, assign) ImpkRedetectOption redetectOptions;
@property (nonatomic, assign) ImpkUnimpressedOutOfScreenOption unimpressedOutOfScreenOptions;
@property (nonatomic, assign) BOOL callBackForEqualInScreenState;
@property (nonatomic, assign) BOOL ignoreHidden;

- (instancetype)initWithCallback:(void(^)(ImpkGroup *group, NSIndexPath *index, UIView *view, ImpkStateModel *state))callback;
- (void)bindWithView:(nullable UIView *)view index:(nullable NSIndexPath *)index;
- (void)bindWithView:(nullable UIView *)view index:(nullable NSIndexPath *)index ignoreDetection:(BOOL)ignoreDetection;
- (void)bindWithView:(nullable UIView *)view index:(nullable NSIndexPath *)index customization:(nullable void(^)(UIView *view))customization;
- (void)bindWithView:(nullable UIView *)view index:(nullable NSIndexPath *)index ignoreDetection:(BOOL)ignoreDetection customization:(nullable void(^)(UIView *view))customization;
- (nullable UIView *)viewForIndex:(nullable NSIndexPath *)index;
- (void)unbindIndex:(nullable NSIndexPath *)index;
- (void)redetect;

@end

NS_ASSUME_NONNULL_END
