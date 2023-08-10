//
//  ImpkGroup.m
//  ImpressionKit-OC
//
//  Created by Dwarven on 2023/8/3.
//

#import "ImpkGroup.h"

@interface ImpkGroup ()

@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, ImpkStateModel *> *states;
@property (nonatomic, strong) NSMapTable<NSIndexPath *, UIView *> *views;
@property (nonatomic, copy) void(^impressionGroupCallback)(ImpkGroup *group, NSIndexPath *index, UIView *view, ImpkStateModel *state);
@property (nonatomic, copy) void(^impressionBlock)(UIView *view, ImpkStateModel *state);

@end

@implementation ImpkGroup

- (instancetype)initWithCallback:(void(^)(ImpkGroup *group, NSIndexPath *index, UIView *view, ImpkStateModel *state))callback {
    self = [super init];
    if (self) {
        self.impressionGroupCallback = callback;
    }
    return self;
}

- (NSMutableDictionary<NSIndexPath *,ImpkStateModel *> *)states {
    if (!_states) {
        _states = [NSMutableDictionary<NSIndexPath *, ImpkStateModel *> dictionary];
    }
    return _states;
}

- (NSMapTable<NSIndexPath *,UIView *> *)views {
    if (!_views) {
        _views = [NSMapTable<NSIndexPath *, UIView *> mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory];
    }
    return _views;
}

- (void(^)(UIView *, ImpkStateModel *))impressionBlock {
    if (!_impressionBlock) {
        __typeof(self) __weak weakSelf = self;
        _impressionBlock = ^(UIView *view, ImpkStateModel *state) {
            if (!weakSelf) return;
            NSIndexPath *index = nil;
            for (NSIndexPath *indexPath in [weakSelf.views.keyEnumerator allObjects]) {
                if ([weakSelf.views objectForKey:indexPath] == view) {
                    index = indexPath;
                    break;
                }
            }
            if (!index) return;
            ImpkStateModel *previousState = weakSelf.states[index];
            if (previousState) {
                if ([previousState isEqual:state]) return;
            }
            if ([view impk_isRedetectionOn:ImpkRedetectOptionViewControllerDidDisappear] && state.state == ImpkStateViewControllerDidDisappear) {
                [weakSelf resetGroupStateAndRedetect:[ImpkStateModel modelWithState:ImpkStateViewControllerDidDisappear]];
                return;
            }
            if ([view impk_isRedetectionOn:ImpkRedetectOptionDidEnterBackground] && state.state == ImpkStateDidEnterBackground) {
                [weakSelf resetGroupStateAndRedetect:[ImpkStateModel modelWithState:ImpkStateDidEnterBackground]];
                return;
            }
            if ([view impk_isRedetectionOn:ImpkRedetectOptionWillResignActive] && state.state == ImpkStateWillResignActive) {
                [weakSelf resetGroupStateAndRedetect:[ImpkStateModel modelWithState:ImpkStateWillResignActive]];
                return;
            }
            if (previousState && previousState.state == ImpkStateImpressed) {
                if (![view impk_isRedetectionOn:ImpkRedetectOptionLeftScreen]) return;
            }
            [weakSelf changeStateWithIndex:index view:view state:state];
        };
    }
    return _impressionBlock;
}

- (void)bindWithView:(UIView *)view index:(NSIndexPath *)index {
    [self bindWithView:view index:index ignoreDetection:NO];
}

- (void)bindWithView:(UIView *)view index:(NSIndexPath *)index ignoreDetection:(BOOL)ignoreDetection {
    if (!view || !index) return;
    [view impk_stopTimer];
    NSIndexPath *previousIndex = nil;
    for (NSIndexPath *indexPath in [self.views.keyEnumerator allObjects]) {
        if ([self.views objectForKey:indexPath] == view) {
            previousIndex = indexPath;
            break;
        }
    }
    if (previousIndex) [self.views removeObjectForKey:previousIndex];
    UIView *previousView = [self.views objectForKey:index];
    if (previousView) [previousView impk_detectImpression:nil state:nil];
    if (ignoreDetection) {
        ImpkStateModel *state = [ImpkStateModel modelWithState:ImpkStateUnknown];
        [view impk_detectImpression:nil state:state];
        [self bindStateWithIndex:index view:view state:state];
        return;
    }
    [self.views setObject:view forKey:index];
    view.impk_detectionInterval = self.detectionInterval;
    view.impk_durationThreshold = self.durationThreshold;
    view.impk_areaRatioThreshold = self.areaRatioThreshold;
    view.impk_redetectOptions = self.redetectOptions;
    view.impk_unimpressedOutOfScreenOptions = self.unimpressedOutOfScreenOptions;
    ImpkStateModel *currentState = self.states[index];
    if (!currentState || currentState.state != ImpkStateImpressed) {
        ImpkStateModel *state = [ImpkStateModel modelWithState:ImpkStateUnknown];
        [self bindStateWithIndex:index view:view state:state];
        [view impk_detectImpression:self.impressionBlock state:state];
        return;
    }
    if ([view impk_isRedetectionOn:ImpkRedetectOptionLeftScreen]) {
        ImpkStateModel *state = [ImpkStateModel modelWithState:ImpkStateUnknown];
        [self bindStateWithIndex:index view:view state:state];
        [view impk_detectImpression:self.impressionBlock state:state];
    } else {
        [self bindStateWithIndex:index view:view state:currentState];
        [view impk_detectImpression:self.impressionBlock state:currentState];
    }
}

- (void)bindStateWithIndex:(NSIndexPath *)index view:(UIView *)view state:(ImpkStateModel *)state {
    self.states[index] = state;
    if (self.impressionGroupCallback) self.impressionGroupCallback(self, index, view, state);
}

- (void)redetect {
    [self resetGroupStateAndRedetect:[ImpkStateModel modelWithState:ImpkStateUnknown]];
}

- (void)resetGroupStateAndRedetect:(ImpkStateModel *)state {
    for (NSIndexPath *index in [self.views.keyEnumerator allObjects]) {
        UIView *view = [self.views objectForKey:index];
        if (!view) {
            [self.views removeObjectForKey:index];
            return;
        }
        [self changeStateWithIndex:index view:view state:state];
        [view impk_detectImpression:self.impressionBlock state:state];
        [view impk_redetect];
    }
    for (NSIndexPath *index in self.states.allKeys) {
        self.states[index] = state;
    }
}

- (void)changeStateWithIndex:(NSIndexPath *)index view:(UIView *)view state:(ImpkStateModel *)state {
    ImpkStateModel *previousState = self.states[index];
    if (previousState) {
        if ([previousState isEqual:state]) return;
    }
    self.states[index] = state;
    if (self.impressionGroupCallback) self.impressionGroupCallback(self, index, view, state);
}

@end
