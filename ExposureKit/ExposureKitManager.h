//
//  ExposureKitManager.h
//  ExposureKit
//
//  Created by Wang Ya on 26/10/18.
//  Copyright © 2018 Shopee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExposureKitMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface ExposureKitManager : NSObject
MACRO_SINGLETON_PATTERN_H

- (void)addView:(UIView *)view;
- (void)removeView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END