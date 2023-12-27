//
//  UIView+Impk.m
//  ImpressionKit-OC
//
//  Created by Dwarven on 2023/8/3.
//

#import "UIView+Impk.h"
#import <objc/runtime.h>

static CGFloat impkAreaRatioThreshold = 0.5;
static CGFloat impkDurationThreshold = 1;
static CGFloat impkDetectionInterval = 0.2;
static ImpkRedetectOption impkDedetectOptions = ImpkRedetectOptionUnknown;
static ImpkUnimpressedOutOfScreenOption impkunimpressedOutOfScreenOptions = ImpkUnimpressedOutOfScreenOptionUnknown;

@implementation ImpkStateModel

+ (ImpkStateModel *)modelWithState:(ImpkState)state {
    return [ImpkStateModel modelWithState:state date:[NSDate date]];
}

+ (ImpkStateModel *)modelWithState:(ImpkState)state date:(NSDate *)date {
    return [ImpkStateModel modelWithState:state date:date areaRatio:0 rectInSelf:CGRectZero rectInWindow:CGRectZero rectInScreen:CGRectZero];
}

+ (ImpkStateModel *)modelWithState:(ImpkState)state date:(NSDate *)date areaRatio:(CGFloat)areaRatio rectInSelf:(CGRect)rectInSelf rectInWindow:(CGRect)rectInWindow rectInScreen:(CGRect)rectInScreen {
    return [ImpkStateModel modelWithState:state date:date updateDate:date areaRatio:areaRatio rectInSelf:rectInSelf rectInWindow:rectInWindow rectInScreen:rectInScreen];
}

+ (ImpkStateModel *)modelWithState:(ImpkState)state date:(NSDate *)date updateDate:(NSDate *)updateDate areaRatio:(CGFloat)areaRatio rectInSelf:(CGRect)rectInSelf rectInWindow:(CGRect)rectInWindow rectInScreen:(CGRect)rectInScreen {
    ImpkStateModel *model = [[ImpkStateModel alloc] init];
    model.state = state;
    model.date = date;
    model.updateDate = updateDate;
    model.areaRatio = areaRatio;
    model.rectInSelf = rectInSelf;
    model.rectInWindow = rectInWindow;
    model.rectInScreen = rectInScreen;
    return model;
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[ImpkStateModel class]]) return NO;
    ImpkStateModel *obj = object;
    if (self.state != obj.state) return NO;
    switch (self.state) {
        case ImpkStateInScreen: {
            return [self.date isEqualToDate:obj.date];
        } break;
        case ImpkStateImpressed: {
            return [self.date isEqualToDate:obj.date] && ABS(self.areaRatio - obj.areaRatio) < 0.0001;
        } break;
        default: {
            return YES;
        } break;
    }
}

@end

@interface ImpkObserverArray : NSObject

@property (nonatomic, copy) NSArray *observers;

@end

@implementation ImpkObserverArray

+ (instancetype)arrayWithArray:(NSArray *)array {
    ImpkObserverArray *result = [[ImpkObserverArray alloc] init];
    result.observers = array;
    return result;
}

- (void)dealloc {
    for (id obj in self.observers) {
        [NSNotificationCenter.defaultCenter removeObserver:obj];
    }
}

@end

@interface UIView (Impk)

@property (nonatomic, strong, readwrite) ImpkStateModel *impk_privateState;
@property (nonatomic, strong, nullable) NSTimer *impk_timer;
@property (nonatomic, strong) NSString *impk_uuid;
@property (nonatomic, assign) BOOL impk_hookingDidMoveToWindow;
@property (nonatomic, assign) BOOL impk_hookingViewDidDisappear;
@property (nonatomic, strong, nullable) ImpkObserverArray *impk_notificationTokens;

- (void)impk_viewControllerDidDisappear:(BOOL)animated;

@end

@interface UIViewController (Impk)

@property (nonatomic, strong) NSMapTable<NSString *, UIView *> *impk_hookingViewDidDisappearViews;

@end

@implementation UIViewController (Impk)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void(^swizzle)(SEL, SEL) = ^(SEL oriSel, SEL swiSel) {
            Method oriMethod = class_getInstanceMethod(self, oriSel);
            Method swiMethod = class_getInstanceMethod(self, swiSel);
            BOOL didAddMethod = class_addMethod(self, oriSel, method_getImplementation(swiMethod), method_getTypeEncoding(swiMethod));
            if (didAddMethod) {
                class_replaceMethod(self, swiSel, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
            } else {
                method_exchangeImplementations(oriMethod, swiMethod);
            }
        };
        swizzle(@selector(viewDidDisappear:), @selector(impk_viewDidDisappear:));
    });
}

- (void)impk_viewDidDisappear:(BOOL)animated {
    [self impk_viewDidDisappear:animated];
    for (UIView *view in [self.impk_hookingViewDidDisappearViews.objectEnumerator allObjects]) {
        [view impk_viewControllerDidDisappear:animated];
    }
}

- (NSMapTable<NSString *, UIView *> *)impk_hookingViewDidDisappearViews {
    NSMapTable<NSString *, UIView *> *views = objc_getAssociatedObject(self, @selector(impk_hookingViewDidDisappearViews));
    if (views) return views;
    views = [NSMapTable<NSString *, UIView *> mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory];
    self.impk_hookingViewDidDisappearViews = views;
    return views;
}

- (void)setImpk_hookingViewDidDisappearViews:(NSMapTable<NSString *,UIView *> *)impk_hookingViewDidDisappearViews {
    objc_setAssociatedObject(self, @selector(impk_hookingViewDidDisappearViews), impk_hookingViewDidDisappearViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIView (Impk)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void(^swizzle)(SEL, SEL) = ^(SEL oriSel, SEL swiSel) {
            Method oriMethod = class_getInstanceMethod(self, oriSel);
            Method swiMethod = class_getInstanceMethod(self, swiSel);
            BOOL didAddMethod = class_addMethod(self, oriSel, method_getImplementation(swiMethod), method_getTypeEncoding(swiMethod));
            if (didAddMethod) {
                class_replaceMethod(self, swiSel, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
            } else {
                method_exchangeImplementations(oriMethod, swiMethod);
            }
        };
        swizzle(@selector(didMoveToWindow), @selector(impk_didMoveToWindow));
    });
}

- (UIViewController *)impk_parentViewController {
    UIResponder * parentResponder = self;
    while (parentResponder) {
        parentResponder = [parentResponder nextResponder];
        if (parentResponder && [parentResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)parentResponder;
        }
    }
    return nil;
}

- (void)impk_rehookViewDidDisappearIfNeeded {
    if (self.impk_hookingViewDidDisappear) return;
    if (![self impk_isRedetectionOn:ImpkRedetectOptionViewControllerDidDisappear]) return;
    UIViewController *vc = [self impk_parentViewController];
    if (!vc) return;
    [vc.impk_hookingViewDidDisappearViews setObject:self forKey:self.impk_uuid];
    self.impk_hookingViewDidDisappear = YES;
}

- (void)impk_cancelHookViewDidDisappearIfNeeded {
    [[self impk_parentViewController].impk_hookingViewDidDisappearViews removeObjectForKey:self.impk_uuid];
    self.impk_hookingViewDidDisappear = NO;
}

- (void)impk_viewControllerDidDisappear:(BOOL)animated {
    if ([self impk_isRedetectionOn:ImpkRedetectOptionViewControllerDidDisappear]) {
        self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateViewControllerDidDisappear];
    } else {
        [self impk_cancelHookViewDidDisappearIfNeeded];
    }
}

- (void)impk_didMoveToWindow {
    [self impk_didMoveToWindow];
    if (self.impk_hookingDidMoveToWindow) {
        if (self.window) {
            if (self.impk_privateState.state != ImpkStateImpressed) {
                self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateUnknown];
            }
            [self impk_rehookViewDidDisappearIfNeeded];
            [self impk_startTimerIfNeeded];
        } else {
            if (self.impk_privateState.state != ImpkStateImpressed) {
                self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateNoWindow];
            }
            [self impk_stopTimer];
        }
    }
}

+ (CGFloat)impk_areaRatioThreshold {
    return impkAreaRatioThreshold;
}

+ (void)setImpk_areaRatioThreshold:(CGFloat)impk_areaRatioThreshold {
    impkAreaRatioThreshold = impk_areaRatioThreshold;
}

- (NSNumber *)impk_areaRatioThreshold {
    return objc_getAssociatedObject(self, @selector(impk_areaRatioThreshold));
}

- (void)setImpk_areaRatioThreshold:(NSNumber *)impk_areaRatioThreshold {
    objc_setAssociatedObject(self, @selector(impk_areaRatioThreshold), impk_areaRatioThreshold, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (CGFloat)impk_durationThreshold {
    return impkDurationThreshold;
}

+ (void)setImpk_durationThreshold:(CGFloat)impk_durationThreshold {
    impkDurationThreshold = impk_durationThreshold;
}

- (NSNumber *)impk_durationThreshold {
    return objc_getAssociatedObject(self, @selector(impk_durationThreshold));
}

- (void)setImpk_durationThreshold:(NSNumber *)impk_durationThreshold{
    objc_setAssociatedObject(self, @selector(impk_durationThreshold), impk_durationThreshold, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (CGFloat)impk_detectionInterval {
    return impkDetectionInterval;
}

+ (void)setImpk_detectionInterval:(CGFloat)impk_detectionInterval {
    impkDetectionInterval = impk_detectionInterval;
}

- (NSNumber *)impk_detectionInterval {
    return objc_getAssociatedObject(self, @selector(impk_detectionInterval));
}

- (void)setImpk_detectionInterval:(NSNumber *)impk_detectionInterval{
    objc_setAssociatedObject(self, @selector(impk_detectionInterval), impk_detectionInterval, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)impk_uuid {
    NSString *uuid = objc_getAssociatedObject(self, @selector(impk_uuid));
    if (uuid && [uuid isKindOfClass:[NSString class]] && uuid.length > 0) return uuid;
    uuid = [[NSUUID UUID] UUIDString];
    self.impk_uuid = uuid;
    return uuid;
}

- (void)setImpk_uuid:(NSString *)impk_uuid {
    objc_setAssociatedObject(self, @selector(impk_uuid), impk_uuid, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)impk_hookingViewDidDisappear {
    return [objc_getAssociatedObject(self, @selector(impk_hookingViewDidDisappear)) boolValue];
}

- (void)setImpk_hookingViewDidDisappear:(BOOL)impk_hookingViewDidDisappear {
    objc_setAssociatedObject(self, @selector(impk_hookingViewDidDisappear), @(impk_hookingViewDidDisappear), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)impk_hookingDidMoveToWindow {
    return [objc_getAssociatedObject(self, @selector(impk_hookingDidMoveToWindow)) boolValue];
}

- (void)setImpk_hookingDidMoveToWindow:(BOOL)impk_hookingDidMoveToWindow {
    objc_setAssociatedObject(self, @selector(impk_hookingDidMoveToWindow), @(impk_hookingDidMoveToWindow), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)impk_setupObservers {
    [self impk_removeNotificationObserverIfNeeded];
    NSMutableArray<NSNotificationName> *names = [NSMutableArray<NSNotificationName> array];
    if ([self impk_isRedetectionOn:ImpkRedetectOptionDidEnterBackground] || [self impk_isUnimpressedOutOfScreenOn:ImpkUnimpressedOutOfScreenOptionDidEnterBackground]) {
        [names addObject:UIApplicationDidEnterBackgroundNotification];
    }
    if ([self impk_isRedetectionOn:ImpkRedetectOptionWillResignActive] || [self impk_isUnimpressedOutOfScreenOn:ImpkUnimpressedOutOfScreenOptionWillResignActive]) {
        [names addObject:UIApplicationWillResignActiveNotification];
    }
    if (names.count < 1) return;
    NSMutableArray *tokens = [NSMutableArray array];
    __typeof(self) __weak weakSelf = self;
    for (NSNotificationName name in names) {
        [tokens addObject:[NSNotificationCenter.defaultCenter addObserverForName:name object:nil queue:nil usingBlock:^(NSNotification *note) {
            if (!weakSelf) return;
            if ([note.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
                if ([weakSelf impk_isRedetectionOn:ImpkRedetectOptionDidEnterBackground]) {
                    weakSelf.impk_privateState = [ImpkStateModel modelWithState:ImpkStateDidEnterBackground];
                } else if ([weakSelf impk_isUnimpressedOutOfScreenOn:ImpkUnimpressedOutOfScreenOptionDidEnterBackground]) {
                    if (weakSelf.impk_privateState.state != ImpkStateImpressed) {
                        weakSelf.impk_privateState = [ImpkStateModel modelWithState:ImpkStateOutOfScreen];
                    }
                }
            } else if ([note.name isEqualToString:UIApplicationWillResignActiveNotification]) {
                if ([weakSelf impk_isRedetectionOn:ImpkRedetectOptionWillResignActive]) {
                    weakSelf.impk_privateState = [ImpkStateModel modelWithState:ImpkStateWillResignActive];
                } else if ([weakSelf impk_isUnimpressedOutOfScreenOn:ImpkUnimpressedOutOfScreenOptionWillResignActive]) {
                    if (weakSelf.impk_privateState.state != ImpkStateImpressed) {
                        weakSelf.impk_privateState = [ImpkStateModel modelWithState:ImpkStateOutOfScreen];
                    }
                }
            } else {
                NSAssert(NO, nil);
                return;
            }
            [weakSelf impk_startTimerIfNeeded];
        }]];
    }
    self.impk_notificationTokens = [ImpkObserverArray arrayWithArray:tokens];
}

- (void)impk_removeNotificationObserverIfNeeded {
    self.impk_notificationTokens = nil;
}

- (ImpkStateModel *)impk_state {
    return self.impk_privateState;
}

- (ImpkStateModel *)impk_privateState {
    return objc_getAssociatedObject(self, @selector(impk_privateState))?:[ImpkStateModel modelWithState:ImpkStateUnknown];
}

- (void)setImpk_privateState:(ImpkStateModel *)impk_privateState {
    ImpkStateModel *old = self.impk_privateState;
    objc_setAssociatedObject(self, @selector(impk_privateState), impk_privateState, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!(impk_privateState.state == ImpkStateInScreen && self.impk_callBackForEqualInScreenState) && [old isEqual:impk_privateState]) return;
    if ([self impk_isDetectionOn]) self.impk_getStateCallback(self, impk_privateState);
}

+ (ImpkRedetectOption)impk_redetectOptions {
    return impkDedetectOptions;
}

+ (void)setImpk_redetectOptions:(ImpkRedetectOption)impk_redetectOptions {
    impkDedetectOptions = impk_redetectOptions;
}

- (ImpkRedetectOption)impk_redetectOptions {
    return [objc_getAssociatedObject(self, @selector(impk_redetectOptions)) integerValue];
}

- (void)setImpk_redetectOptions:(ImpkRedetectOption)impk_redetectOptions {
    objc_setAssociatedObject(self, @selector(impk_redetectOptions), @(impk_redetectOptions), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (ImpkUnimpressedOutOfScreenOption)impk_unimpressedOutOfScreenOptions {
    return impkunimpressedOutOfScreenOptions;
}

+ (void)setImpk_unimpressedOutOfScreenOptions:(ImpkUnimpressedOutOfScreenOption)impk_unimpressedOutOfScreenOptions {
    impkunimpressedOutOfScreenOptions = impk_unimpressedOutOfScreenOptions;
}

- (ImpkUnimpressedOutOfScreenOption)impk_unimpressedOutOfScreenOptions {
    return [objc_getAssociatedObject(self, @selector(impk_unimpressedOutOfScreenOptions)) integerValue];
}

- (void)setImpk_unimpressedOutOfScreenOptions:(ImpkUnimpressedOutOfScreenOption)impk_unimpressedOutOfScreenOptions {
    objc_setAssociatedObject(self, @selector(impk_unimpressedOutOfScreenOptions), @(impk_unimpressedOutOfScreenOptions), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimer *)impk_timer {
    return objc_getAssociatedObject(self, @selector(impk_timer));
}

- (void)setImpk_timer:(NSTimer *)impk_timer {
    objc_setAssociatedObject(self, @selector(impk_timer), impk_timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)impk_topEdgeInset {
    return objc_getAssociatedObject(self, @selector(impk_topEdgeInset));
}

- (void)setImpk_topEdgeInset:(NSNumber *)impk_topEdgeInset {
    objc_setAssociatedObject(self, @selector(impk_topEdgeInset), impk_topEdgeInset, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSNumber *)impk_leftEdgeInset {
    return objc_getAssociatedObject(self, @selector(impk_leftEdgeInset));
}

- (void)setImpk_leftEdgeInset:(NSNumber *)impk_leftEdgeInset {
    objc_setAssociatedObject(self, @selector(impk_leftEdgeInset), impk_leftEdgeInset, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSNumber *)impk_bottomEdgeInset {
    return objc_getAssociatedObject(self, @selector(impk_bottomEdgeInset));
}

- (void)setImpk_bottomEdgeInset:(NSNumber *)impk_bottomEdgeInset {
    objc_setAssociatedObject(self, @selector(impk_bottomEdgeInset), impk_bottomEdgeInset, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSNumber *)impk_rightEdgeInset {
    return objc_getAssociatedObject(self, @selector(impk_rightEdgeInset));
}

- (void)setImpk_rightEdgeInset:(NSNumber *)impk_rightEdgeInset {
    objc_setAssociatedObject(self, @selector(impk_rightEdgeInset), impk_rightEdgeInset, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)impk_callBackForEqualInScreenState {
    return [objc_getAssociatedObject(self, @selector(impk_callBackForEqualInScreenState)) boolValue];
}

- (void)setImpk_callBackForEqualInScreenState:(BOOL)impk_callBackForEqualInScreenState {
    objc_setAssociatedObject(self, @selector(impk_callBackForEqualInScreenState), @(impk_callBackForEqualInScreenState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ImpkObserverArray *)impk_notificationTokens {
    return objc_getAssociatedObject(self, @selector(impk_notificationTokens));
}

- (void)setImpk_notificationTokens:(ImpkObserverArray *)impk_notificationTokens {
    objc_setAssociatedObject(self, @selector(impk_notificationTokens), impk_notificationTokens, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void(^)(UIView *, ImpkStateModel *))impk_getStateCallback {
    return objc_getAssociatedObject(self, @selector(impk_getStateCallback));
}

- (void)impk_detectImpression:(void(^)(UIView *, ImpkStateModel *))block {
    [self impk_detectImpression:block state:nil];
}

- (void)impk_detectImpression:(void(^)(UIView *, ImpkStateModel *))block state:(ImpkStateModel *)state {
    NSAssert([NSThread isMainThread], @"");
    self.impk_privateState = state;
    if (block) {
        objc_setAssociatedObject(self, @selector(impk_getStateCallback), ^(UIView *view, ImpkStateModel *state) {
            if (view) block(view, state);
        }, OBJC_ASSOCIATION_COPY_NONATOMIC);
        self.impk_hookingDidMoveToWindow = YES;
        [self impk_rehookViewDidDisappearIfNeeded];
        [self impk_setupObservers];
        [self impk_startTimerIfNeeded];
    } else {
        [self impk_stopTimer];
        [self impk_removeNotificationObserverIfNeeded];
        [self impk_cancelHookViewDidDisappearIfNeeded];
        self.impk_hookingDidMoveToWindow = NO;
        objc_setAssociatedObject(self, @selector(impk_getStateCallback), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

- (BOOL)impk_isDetectionOn {
    return [self impk_getStateCallback] != nil;
}

- (void)impk_redetect {
    self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateUnknown];
    [self impk_startTimerIfNeeded];
}

- (BOOL)impk_isRedetectionOn:(ImpkRedetectOption)option {
    if (option == ImpkRedetectOptionUnknown) return NO;
    ImpkRedetectOption options = self.impk_redetectOptions;
    if (options == ImpkRedetectOptionUnknown) options = UIView.impk_redetectOptions;
    if (options == ImpkRedetectOptionUnknown) return NO;
    return (options & option) == option;
}

- (BOOL)impk_isUnimpressedOutOfScreenOn:(ImpkUnimpressedOutOfScreenOption)option {
    if (option == ImpkUnimpressedOutOfScreenOptionUnknown) return NO;
    ImpkUnimpressedOutOfScreenOption options = self.impk_unimpressedOutOfScreenOptions;
    if (options == ImpkUnimpressedOutOfScreenOptionUnknown) options = UIView.impk_unimpressedOutOfScreenOptions;
    if (options == ImpkUnimpressedOutOfScreenOptionUnknown) return NO;
    return (options & option) == option;
}

- (BOOL)impk_keepDetectionAfterImpressed {
    return
    [self impk_isRedetectionOn:ImpkRedetectOptionLeftScreen] ||
    [self impk_isRedetectionOn:ImpkRedetectOptionViewControllerDidDisappear] ||
    [self impk_isRedetectionOn:ImpkRedetectOptionDidEnterBackground] ||
    [self impk_isRedetectionOn:ImpkRedetectOptionWillResignActive];
}

- (CGRect)impk_rectForEdgeInsetsWithRect:(CGRect)rect {
    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    if (self.impk_leftEdgeInset) {
        x = MAX(x, self.impk_leftEdgeInset.floatValue);
        width = MAX(0, width - (x - rect.origin.x));
    }
    if (self.impk_topEdgeInset) {
        y = MAX(y, self.impk_topEdgeInset.floatValue);
        height = MAX(0, height - (y - rect.origin.y));
    }
    if (self.impk_rightEdgeInset) {
        width = MAX(0, MIN(width, self.bounds.size.width - self.impk_rightEdgeInset.floatValue - x));
    }
    if (self.impk_bottomEdgeInset) {
        height = MAX(0, MIN(height, self.bounds.size.height - self.impk_bottomEdgeInset.floatValue - y));
    }
    return CGRectMake(x, y, width, height);
}

- (CGRect)impk_validBounds {
    return [self impk_rectForEdgeInsetsWithRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
}

- (CGRect)impk_validFrame {
    CGRect rect = [self impk_validBounds];
    rect = CGRectMake(rect.origin.x + self.frame.origin.x,
                      rect.origin.y + self.frame.origin.y,
                      rect.size.width,
                      rect.size.height);
    return rect;
}

- (void)impk_areaRatio:(void(^)(CGFloat areaRatio, CGRect rectInSelf, CGRect rectInWindow, CGRect rectInScreen))completion {
    if (!completion) return;
    if (self.hidden || self.alpha <= CGFLOAT_MIN) {
        completion(0, CGRectZero, CGRectZero, CGRectZero);
    } else if ([self isKindOfClass:[UIWindow class]] && !self.superview) {
        CGRect validFrame = [self impk_validFrame];
        CGRect intersection = CGRectIntersection(validFrame, [[(UIWindow *)self screen] bounds]);
        CGFloat ratio = (intersection.size.width * intersection.size.height) / (validFrame.size.width * validFrame.size.height);
        CGFloat areaRatio = [self impk_fixRatioPrecisionWithNumber:ratio];
        if (areaRatio > 0) {
            CGRect rectInWindow = CGRectMake(intersection.origin.x - self.frame.origin.x,
                                             intersection.origin.y - self.frame.origin.y,
                                             intersection.size.width,
                                             intersection.size.height);
            completion(areaRatio, rectInWindow, rectInWindow, intersection);
        } else {
            completion(0, CGRectZero, CGRectZero, CGRectZero);
        }
    } else if (!self.window || self.window.hidden || self.window.alpha <= CGFLOAT_MIN) {
        completion(0, CGRectZero, CGRectZero, CGRectZero);
    } else {
        UIView *aView = self;
        CGRect validBounds = [self impk_validBounds];
        CGRect frameInSuperView = validBounds;
        while (aView.superview) {
            if (aView.superview.hidden || aView.superview.alpha <= CGFLOAT_MIN) {
                completion(0, CGRectZero, CGRectZero, CGRectZero);
                return;
            }
            frameInSuperView = [aView convertRect:frameInSuperView toView:aView.superview];
            frameInSuperView = [aView.superview impk_rectForEdgeInsetsWithRect:frameInSuperView];
            if (aView.clipsToBounds) {
                frameInSuperView = CGRectIntersection(frameInSuperView, aView.frame);
            }
            if (CGRectIsEmpty(frameInSuperView)) {
                completion(0, CGRectZero, CGRectZero, CGRectZero);
                return;
            }
            aView = aView.superview;
        }
        CGRect frameInWindow = frameInSuperView;
        CGRect frameInScreen = CGRectMake(frameInWindow.origin.x + self.window.frame.origin.x,
                                          frameInWindow.origin.y + self.window.frame.origin.y,
                                          frameInWindow.size.width,
                                          frameInWindow.size.height);
        if (aView.clipsToBounds) {
            frameInScreen = CGRectIntersection(frameInScreen, aView.frame);
        }
        CGRect intersection = CGRectIntersection(frameInScreen, self.window.screen.bounds);
        CGFloat ratio = (intersection.size.width * intersection.size.height) / (validBounds.size.width * validBounds.size.height);
        CGFloat areaRatio = [self impk_fixRatioPrecisionWithNumber:ratio];
        if (areaRatio > 0) {
            CGRect rectInWindow = CGRectMake(intersection.origin.x - self.window.frame.origin.x,
                                             intersection.origin.y - self.window.frame.origin.y,
                                             intersection.size.width,
                                             intersection.size.height);
            completion(areaRatio, [self.window convertRect:rectInWindow toView:self], rectInWindow, intersection);
        } else {
            completion(0, CGRectZero, CGRectZero, CGRectZero);
        }
    }
}

- (CGFloat)impk_fixRatioPrecisionWithNumber:(CGFloat)number {
    CGFloat ratioPrecisionOffset = 0.0001;
    if (number <= ratioPrecisionOffset) return 0;
    if (number >= 1 - ratioPrecisionOffset) return 1;
    return number;
}

- (void)impk_detect {
    if (self.impk_privateState.state == ImpkStateImpressed) {
        if (![self impk_keepDetectionAfterImpressed]) {
            [self impk_stopTimer];
            return;
        }
    }
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        if ([self impk_isRedetectionOn:ImpkRedetectOptionDidEnterBackground]) {
            self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateDidEnterBackground];
            return;
        }
        if ([self impk_isUnimpressedOutOfScreenOn:ImpkUnimpressedOutOfScreenOptionDidEnterBackground] && self.impk_privateState.state != ImpkStateImpressed) {
            self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateOutOfScreen];
            return;
        }
    }
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateInactive) {
        if ([self impk_isRedetectionOn:ImpkRedetectOptionWillResignActive]) {
            self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateWillResignActive];
            return;
        }
        if ([self impk_isUnimpressedOutOfScreenOn:ImpkUnimpressedOutOfScreenOptionWillResignActive] && self.impk_privateState.state != ImpkStateImpressed) {
            self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateOutOfScreen];
            return;
        }
    }
    UIViewController *pvc = [self impk_parentViewController];
    if (pvc && pvc.presentedViewController) {
        if ([self impk_isRedetectionOn:ImpkRedetectOptionViewControllerDidDisappear]) {
            self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateViewControllerDidDisappear];
            return;
        }
        if (self.impk_privateState.state != ImpkStateImpressed) {
            self.impk_privateState = [ImpkStateModel modelWithState:ImpkStateViewControllerDidDisappear];
        }
        return;
    }
    if (self.impk_privateState.state == ImpkStateImpressed) {
        if (![self impk_isRedetectionOn:ImpkRedetectOptionLeftScreen]) return;
    }
    __typeof(self) __weak weakSelf = self;
    [self impk_areaRatio:^(CGFloat areaRatio, CGRect rectInSelf, CGRect rectInWindow, CGRect rectInScreen) {
        CGFloat areaRatioThreshold = weakSelf.impk_areaRatioThreshold ? weakSelf.impk_areaRatioThreshold.floatValue : UIView.impk_areaRatioThreshold;
        if (areaRatio >= areaRatioThreshold) {
            if (weakSelf.impk_privateState.state == ImpkStateInScreen) {
                NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:weakSelf.impk_privateState.date];
                CGFloat durationThreshold = weakSelf.impk_durationThreshold ? weakSelf.impk_durationThreshold.floatValue : UIView.impk_durationThreshold;
                if (interval >= durationThreshold) {
                    weakSelf.impk_privateState = [ImpkStateModel modelWithState:ImpkStateImpressed date:[NSDate date] areaRatio:areaRatio rectInSelf:rectInSelf rectInWindow:rectInWindow rectInScreen:rectInScreen];
                    if (![weakSelf impk_keepDetectionAfterImpressed]) {
                        [weakSelf impk_stopTimer];
                    }
                } else if (weakSelf.impk_callBackForEqualInScreenState) {
                    weakSelf.impk_privateState = [ImpkStateModel modelWithState:ImpkStateInScreen date:weakSelf.impk_privateState.date updateDate:[NSDate date] areaRatio:areaRatio rectInSelf:rectInSelf rectInWindow:rectInWindow rectInScreen:rectInScreen];
                }
            } else if (weakSelf.impk_privateState.state != ImpkStateImpressed) {
                weakSelf.impk_privateState = [ImpkStateModel modelWithState:ImpkStateInScreen date:[NSDate date] areaRatio:areaRatio rectInSelf:rectInSelf rectInWindow:rectInWindow rectInScreen:rectInScreen];
            }
        } else {
            weakSelf.impk_privateState = [ImpkStateModel modelWithState:ImpkStateOutOfScreen];
        }
    }];
}

- (void)impk_startTimerIfNeeded {
    if (self.impk_privateState.state == ImpkStateImpressed) {
        if (![self impk_keepDetectionAfterImpressed]) {
            [self impk_stopTimer];
            return;
        }
    }
    if (self.impk_timer || ![self impk_isDetectionOn]) return;
    [self impk_startTimer];
}

- (void)impk_startTimer {
    NSTimeInterval timeInterval = self.impk_detectionInterval ? self.impk_detectionInterval.doubleValue : UIView.impk_detectionInterval;
    __typeof(self) __weak weakSelf = self;
    self.impk_timer = [NSTimer timerWithTimeInterval:timeInterval repeats:YES block:^(NSTimer *timer) {
        if (!weakSelf) {
            [timer invalidate];
            return;
        }
        NSTimeInterval currentTimeInterval = weakSelf.impk_detectionInterval ? weakSelf.impk_detectionInterval.doubleValue : UIView.impk_detectionInterval;
        if (ABS(currentTimeInterval - timeInterval) < 0.001) {
            [weakSelf impk_detect];
        } else {
            [weakSelf impk_stopTimer];
            [weakSelf impk_startTimerIfNeeded];
        }
    }];
    [NSRunLoop.mainRunLoop addTimer:self.impk_timer forMode:NSRunLoopCommonModes];
}

- (void)impk_stopTimer {
    if (self.impk_timer) {
        [self.impk_timer invalidate];
        self.impk_timer = nil;
    }
}

@end
