//
//  ImpressionGroup.swift
//  ImpressionKit
//
//  Created by Yanni Wang on 2/6/21.
//

import UIKit

private var indexKey = 0

public class ImpressionGroup<IndexType: Hashable> {
    
    // MARK: - config
    // Change the detection (scan) interval (in seconds). Smaller detectionInterval means more accuracy and higher CPU consumption. Apply to the group. `UIView.detectionInterval` will be used if it's nil.
    public var detectionInterval: Float?
    
    // Chage the threshold of duration in screen (in seconds). The view will be impressed if it keeps being in screen after this seconds. Apply to the group. `UIView.durationThreshold` will be used if it's nil.
    public var durationThreshold: Float?
    
    // Chage the threshold of area ratio in screen. It's from 0 to 1. The view will be impressed if it's area ratio keeps being bigger than this value. Apply to the group. `UIView.areaRatioThreshold` will be used if it's nil.
    public var areaRatioThreshold: Float?
        
    // Retrigger the impression. Apply to the group. `UIView.redetectOptions` will be used if it's nil.
    public var redetectOptions: UIView.Redetect?
    
    // MARK: - public
    public typealias ImpressionGroupCallback = (_ group: ImpressionGroup, _ index: IndexType, _ view: UIView, _ state: UIView.ImpressionState) -> ()
    
    public private(set) var states = [IndexType: UIView.ImpressionState]()
    
    // MARK: - private
    private let allViews = NSHashTable<UIView>.weakObjects()
    
    private let impressionGroupCallback: ImpressionGroupCallback
    
    private lazy var impressionBlock: (_ view: UIView, _ state: UIView.ImpressionState) -> () = { [weak self] (view, state) in
        guard let self = self,
              let index = ImpressionGroup.getIndex(view: view) else {
            return
        }
        if case .viewControllerDidDisappear = state,
           view.isRedetectionOn(.viewControllerDidDisappear) {
            self.updateState(state)
            return
        }
        if case .didEnterBackground = state,
           view.isRedetectionOn(.didEnterBackground) {
            self.updateState(state)
            return
        }
        if case .willResignActive = state,
           view.isRedetectionOn(.willResignActive) {
            self.updateState(state)
            return
        }
        
        if let currentState = self.states[index],
           currentState.isImpressed {
            guard view.isRedetectionOn(.leftScreen) else {
                return
            }
        }
        self.changeState(index: index, view: view, state: state)
    }
    
    public init(impressionGroupCallback: @escaping ImpressionGroupCallback) {
        self.impressionGroupCallback = impressionGroupCallback
    }
    
    /**
     This method must be called every time in
     1. UICollectionView: `func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell`
     2. or UITableView: `func cellForRow(at indexPath: IndexPath) -> UITableViewCell?`
     3. or your customized methods.
     Non-calling may cause abnormal impression.
     if a index doesn't need to be impressed.  pass `ignoreDetection = true` to ignore this index.
     */
    public func bind(view: UIView, index: IndexType, ignoreDetection: Bool = false) {
        if !allViews.contains(view) {
            allViews.add(view)
        }
        
        let enumerator = allViews.objectEnumerator()
        while let view = enumerator.nextObject() as? UIView {
            if ImpressionGroup.getIndex(view: view) == index {
                ImpressionGroup.setIndex(view: view, index: nil)
                break
            }
        }
        ImpressionGroup.setIndex(view: view, index: index)
        
        view.detectionInterval = self.detectionInterval
        view.durationThreshold = self.durationThreshold
        view.areaRatioThreshold = self.areaRatioThreshold
        view.redetectOptions = self.redetectOptions
        view.detectImpression(nil)
        
        guard ignoreDetection == false else {
            self.changeState(index: index, view: view, state: .unknown)
            return
        }
        
        if let currentState = self.states[index],
           currentState.isImpressed {
            if view.keepDetectionAfterImpressed() {
                if view.isRedetectionOn(.leftScreen) {
                    self.changeState(index: index, view: view, state: .unknown)
                }
                view.detectImpression(impressionBlock)
            }
        } else {
            self.changeState(index: index, view: view, state: .unknown)
            view.detectImpression(impressionBlock)
        }
    }
    
    public func redetect() {
        self.states.removeAll()
        self.allViews.allObjects.forEach { (view) in
            view.redetect()
            guard let index = ImpressionGroup.getIndex(view: view) else {
                return
            }
            self.changeState(index: index, view: view, state: .unknown)
        }
    }
    
    private func updateState(_ state: UIView.ImpressionState) {
        self.allViews.allObjects.forEach { (view) in
            guard let index = ImpressionGroup.getIndex(view: view) else {
                return
            }
            self.changeState(index: index, view: view, state: state)
        }
        self.states = self.states.mapValues { (_) -> UIView.ImpressionState in
            return state
        }
    }
    
    private func changeState(index: IndexType, view: UIView, state: UIView.ImpressionState) {
        if let previousState = self.states[index] {
            guard previousState != state else {
                return
            }
        }
        self.states[index] = state
        self.impressionGroupCallback(self, index, view, state)
    }
    
    
    static private func getIndex(view: UIView) -> IndexType? {
        return objc_getAssociatedObject(view, &indexKey) as? IndexType
    }
    
    static private func setIndex(view: UIView, index: IndexType?) {
        objc_setAssociatedObject(view, &indexKey, index, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
