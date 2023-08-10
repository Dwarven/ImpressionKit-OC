//
//  SwiftUIListDemoViewOC.swift
//  ImpressionKit-OC
//
//  Created by Dwarven on 2023/8/3.
//

import Foundation
import ImpressionKit_OC
import SwiftUI

@available(iOS 13.0, *)
final class SwiftUIListDemoViewOCModel: ObservableObject {
    lazy var group = ImpkGroup { [weak self] (_, index, _, state) in
        if state.state == .impressed {
            print("impressed index: \(index.row)")
        }
        self?.list[index.row].1 = state
    }
    
    func setupGroupParams() -> Bool {
        group.detectionInterval = NSNumber(floatLiteral: Double(UIView.detectionInterval))
        group.durationThreshold = NSNumber(floatLiteral: Double(UIView.durationThreshold))
        group.areaRatioThreshold = NSNumber(floatLiteral: Double(UIView.areaRatioThreshold))
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
        group.redetectOptions = options
        group.unimpressedOutOfScreenOptions = [.didEnterBackground]
        return true
    }
    
    @Published
    var list = (0 ..< 100).map { index in (index, ImpkStateModel(state: .unknown)) }
}

@available(iOS 13.0, *)
struct SwiftUIListDemoViewOC: View {
    @ObservedObject
    var viewModel = SwiftUIListDemoViewOCModel()
    
    var body: some View {
        if viewModel.setupGroupParams() {
            List(viewModel.list, id: \.0) { index, state in
                CellView(index: index)
                    .frame(height: 100)
                    .background(state.state == .impressed ? Color.green : Color.red)
                    .impk_detectImpression(group: viewModel.group, index: IndexPath(row: index, section: 0))
            }
        }
    }
}

@available(iOS 13.0, *)
extension SwiftUIListDemoViewOC {
    struct CellView: View {
        let index: Int
        
        var body: some View {
            Text(String(index))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
