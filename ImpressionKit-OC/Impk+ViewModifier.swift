//
//  Impk+ViewModifier.swift
//  ImpressionKit-OC
//
//  Created by Dwarven on 2023/8/3.
//

import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

@available(iOS 13.0, *)
private struct ImpkView: UIViewRepresentable {
    let isForGroup: Bool
    let detectionInterval: NSNumber?
    let durationThreshold: NSNumber?
    let areaRatioThreshold: NSNumber?
    let redetectOptions: ImpkRedetectOption?
    let onCreated: ((UIView) -> Void)?
    let onChanged: ((ImpkStateModel) -> Void)?
    
    func makeUIView(context: UIViewRepresentableContext<ImpkView>) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.impk_detectionInterval = detectionInterval
        view.impk_durationThreshold = durationThreshold
        view.impk_areaRatioThreshold = areaRatioThreshold
        if let redetectOptions = redetectOptions {
            view.impk_redetectOptions = redetectOptions
        }
        
        if !isForGroup {
            view.impk_detectImpression { _, state in
                onChanged?(state)
            }
        }
        onCreated?(view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

@available(iOS 13.0, *)
private struct ImpkTrackableModifier: ViewModifier {
    let isForGroup: Bool
    let detectionInterval: NSNumber?
    let durationThreshold: NSNumber?
    let areaRatioThreshold: NSNumber?
    let redetectOptions: ImpkRedetectOption?
    let onCreated: ((UIView) -> Void)?
    let onChanged: ((ImpkStateModel) -> Void)?
    
    func body(content: Content) -> some View {
        content
            .overlay(ImpkView(isForGroup: isForGroup,
                              detectionInterval: detectionInterval,
                              durationThreshold: durationThreshold,
                              areaRatioThreshold: areaRatioThreshold,
                              redetectOptions: redetectOptions,
                              onCreated: onCreated,
                              onChanged: onChanged)
                .allowsHitTesting(false))
    }
}

@available(iOS 13.0, *)
public extension View {
    func impk_detectImpression(detectionInterval: NSNumber? = nil,
                               durationThreshold: NSNumber? = nil,
                               areaRatioThreshold: NSNumber? = nil,
                               redetectOptions: ImpkRedetectOption? = nil,
                               onChanged: @escaping (ImpkStateModel) -> Void) -> some View {
        modifier(ImpkTrackableModifier(isForGroup: false,
                                       detectionInterval: detectionInterval,
                                       durationThreshold: durationThreshold,
                                       areaRatioThreshold: areaRatioThreshold,
                                       redetectOptions: redetectOptions,
                                       onCreated: nil,
                                       onChanged: onChanged))
    }
    
    func impk_detectImpression(group: ImpkGroup, index: IndexPath) -> some View {
        modifier(ImpkTrackableModifier(isForGroup: true,
                                       detectionInterval: group.detectionInterval,
                                       durationThreshold: group.durationThreshold,
                                       areaRatioThreshold: group.areaRatioThreshold,
                                       redetectOptions: group.redetectOptions,
                                       onCreated: { view in
                                           group.bind(with: view, index: index)
                                       },
                                       onChanged: nil))
    }
}
