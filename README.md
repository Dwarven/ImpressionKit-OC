[中文](README.zh-Hans.md)

# ImpressionKit

This is a user behavior tracking (UBT) tool to analyze impression events for UIView (exposure of UIView) in iOS.

![ezgif com-gif-maker](https://user-images.githubusercontent.com/5275802/120922347-30a2d200-c6fb-11eb-8994-f97c2bbc0ff8.gif)

# How to use ImpressionKit

### Main APIs

It's quite simple. 

```swift
UIView().detectImpression { (view, state) in
    if state.isImpressed {
        print("This view is impressed to users.")
    }
}
```

Use `ImpressionGroup` for UICollectionView, UITableView or other reusable view cases.

```swift

var group = ImpressionGroup.init {(_, index: IndexPath, view, state) in
    if state.isImpressed {
        print("impressed index: \(index.row)")
    }
}

...

func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
    self.group.bind(view: cell, index: indexPath)
    return cell
}

```

### Others APIs

Change the detection (scan) interval (in seconds). Smaller `detectionInterval` means more accuracy and higher CPU consumption.

```swift
UIView.detectionInterval = 0.1  // apply to all views
UIView().detectionInterval = 0.1    // apply to the specific view. `UIView.detectionInterval` will be used if it's nil.
ImpressionGroup().detectionInterval = 0.1   // apply to the group. `UIView.detectionInterval` will be used if it's nil.
```

Chage the threshold of duration in screen (in seconds). The view will be impressed if it keeps being in screen after this seconds.

```swift
UIView.durationThreshold = 2  // apply to all views
UIView().durationThreshold = 2    // apply to the specific view. `UIView.durationThreshold` will be used if it's nil.
ImpressionGroup().durationThreshold = 2   // apply to the group. `UIView.durationThreshold` will be used if it's nil.
```

Chage the threshold of area ratio in screen. It's from 0 to 1. The view will be impressed if it's area ratio keeps being bigger than this value.

```swift
UIView.areaRatioThreshold = 0.4  // apply to all views
UIView().areaRatioThreshold = 0.4    // apply to the specific view. `UIView.areaRatioThreshold` will be used if it's nil.
ImpressionGroup().areaRatioThreshold = 0.4   // apply to the group. `UIView.areaRatioThreshold` will be used if it's nil.
```

Retrigger the impression event when a view leaving screen.

```swift
UIView.redetectWhenLeavingScreen = true  // apply to all views
UIView().redetectWhenLeavingScreen = true    // apply to the specific view. `UIView.redetectWhenLeavingScreen` will be used if it's nil.
ImpressionGroup().redetectWhenLeavingScreen = true   // apply to the group. `UIView.redetectWhenLeavingScreen` will be used if it's nil.
```

Retrigger the impression event when the UIViewController which the view in did disappear.

```swift
UIView.redetectWhenViewControllerDidDisappear = true  // apply to all views
UIView().redetectWhenViewControllerDidDisappear = true    // apply to the specific view. `UIView.redetectWhenViewControllerDidDisappear` will be used if it's nil.
ImpressionGroup().redetectWhenViewControllerDidDisappear = true   // apply to the group. `UIView.redetectWhenViewControllerDidDisappear` will be used if it's nil.
```

Retrigger the impression event when the App did enter background.

```swift
UIView.redetectWhenReceiveSystemNotification.insert(UIApplication.didEnterBackgroundNotification)  // apply to all views

UIView().redetectWhenReceiveSystemNotification.insert(UIApplication.didEnterBackgroundNotification)    // apply to the specific view. `UIView.redetectWhenReceiveSystemNotification.union(self.redetectWhenReceiveSystemNotification)` will be applied finally.

ImpressionGroup().redetectWhenReceiveSystemNotification.insert(UIApplication.didEnterBackgroundNotification)   // apply to the group. `UIView.redetectWhenReceiveSystemNotification.union(self.redetectWhenReceiveSystemNotification)` will be applied finally.
```

Retrigger the impression event when the App will resign active.

```swift
UIView.redetectWhenReceiveSystemNotification.insert(UIApplication.willResignActiveNotification)  // apply to all views

UIView().redetectWhenReceiveSystemNotification.insert(UIApplication.willResignActiveNotification)    // apply this value to the specific view. `UIView.redetectWhenReceiveSystemNotification.union(self.redetectWhenReceiveSystemNotification)` will be applied finally.

ImpressionGroup().redetectWhenReceiveSystemNotification.insert(UIApplication.willResignActiveNotification)   // apply to the group. `UIView.redetectWhenReceiveSystemNotification.union(self.redetectWhenReceiveSystemNotification)` will be applied finally.
```

Refer to the Demo for more details.

# How to integrate ImpressionKit

**ImpressionKit** can be integrated by [cocoapods](https://cocoapods.org/). 

```
pod 'ImpressionKit'
```

# Requirements

- iOS 10.0+
- Xcode 11+
