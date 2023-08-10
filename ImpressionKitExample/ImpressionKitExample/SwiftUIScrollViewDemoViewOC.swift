//
//  SwiftUIScrollViewDemoViewOC.swift
//  ImpressionKit-OC
//
//  Created by Dwarven on 2023/8/3.
//

import Foundation
import ImpressionKit_OC
import SwiftUI

@available(iOS 13.0, *)
struct SwiftUIScrollViewDemoViewOC: View {
    var body: some View {
        ScrollView{
            ForEach(0 ..< 100) { _ in
                OCCellView()
            }
        }
    }
}

@available(iOS 13.0, *)
extension SwiftUIScrollViewDemoViewOC {
    struct OCCellView: View {
        @State var state: ImpkState = .unknown
        var body: some View {
            let detectionInterval = NSNumber(floatLiteral: Double(UIView.detectionInterval))
            let durationThreshold = NSNumber(floatLiteral: Double(UIView.durationThreshold))
            let areaRatioThreshold = NSNumber(floatLiteral: Double(UIView.areaRatioThreshold))
            let redetectOptions: ImpkRedetectOption = {
                let redetectOptions = UIView.redetectOptions
                var options: ImpkRedetectOption = []
                if redetectOptions.contains(.leftScreen) {
                    options.insert(.leftScreen)
                }
                if redetectOptions.contains(.viewControllerDidDisappear) {
                    options.insert(.viewControllerDidDisappear)
                }
                if redetectOptions.contains(.didEnterBackground) {
                    options.insert(.didEnterBackground)
                }
                if redetectOptions.contains(.willResignActive) {
                    options.insert(.willResignActive)
                }
                return options
            }()
            (state == .impressed ? Color.green : Color.red)
                .frame(height: 44)
                .impk_detectImpression(detectionInterval: detectionInterval, durationThreshold: durationThreshold, areaRatioThreshold: areaRatioThreshold, redetectOptions: redetectOptions) { state in
                    self.state = state.state
                }
        }
    }
}
