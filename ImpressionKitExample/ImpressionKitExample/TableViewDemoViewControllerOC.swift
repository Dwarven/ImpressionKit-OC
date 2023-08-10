//
//  TableViewDemoViewControllerOC.swift
//  ImpressionKit-OC
//
//  Created by Dwarven on 2023/8/3.
//

import UIKit
import ImpressionKit_OC

class TableViewDemoViewControllerOC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let tableView = { () -> UITableView in
        let view = UITableView.init()
        view.backgroundColor = .white
        view.register(OCCell.self, forCellReuseIdentifier: "Cell")
        return view
    }()
    
    lazy var group = ImpkGroup { _, index, view, state in
        if state.state == .impressed {
            print("impressed index: \(index.row)")
        }
        if let cell = view as? OCCell {
            cell.updateUI(state: state)
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
//        view.impk_topEdgeInset = 160
//        view.impk_bottomEdgeInset = 160
//        view.impk_leftEdgeInset = 80
//        view.impk_rightEdgeInset = 80
        
//        UIView.impk_detectionInterval = CGFloat(UIView.detectionInterval)
//        UIView.impk_durationThreshold = CGFloat(UIView.durationThreshold)
//        UIView.impk_areaRatioThreshold = CGFloat(UIView.areaRatioThreshold)
        
        self.view.backgroundColor = .white
        self.title = "UITableView"
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem.init(title: "push", style: .plain, target: self, action: #selector(pushNextPage)),
            UIBarButtonItem.init(title: "present", style: .plain, target: self, action: #selector(presentNextPage)),
            UIBarButtonItem.init(title: "redetect", style: .plain, target: self, action: #selector(redetect)),
        ]
        
        self.tableView.frame = self.view.bounds
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.addSubview(self.tableView)
    }

    @objc private func redetect() {
        self.group.redetect()
    }

    @objc private func pushNextPage() {
        let nextPage = UIViewController()
        nextPage.view.backgroundColor = .white
        self.navigationController?.pushViewController(nextPage, animated: true)
    }
    
    @objc private func presentNextPage() {
        let nextPage = UIViewController()
        nextPage.view.backgroundColor = .white
        let backButton = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 40))
        backButton.setTitle("back", for: .normal)
        backButton.setTitleColor(.black, for: .normal)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        backButton.center = CGPoint.init(x: nextPage.view.frame.width / 2, y: nextPage.view.frame.height / 2)
        nextPage.view.addSubview(backButton)
        self.present(nextPage, animated: true, completion: nil)
    }
    
    @objc func back(){
        self.presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 99
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! OCCell
        cell.index = indexPath.row
        self.group.bind(with: cell, index: indexPath)
        return cell
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
}

private class OCCell: UITableViewCell {
    private var label = { () -> UILabel in
        let view = UILabel.init()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = .black
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()
    
    var index: Int = -1
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.layer.borderColor = UIColor.gray.cgColor
        self.contentView.layer.borderWidth = 0.5
        self.contentView.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.label.frame = self.contentView.bounds
    }
    
    fileprivate func updateUI(state: ImpkStateModel) {
        self.layer.removeAllAnimations()
        switch state.state {
        case .impressed:
            self.label.text = String.init(format: "\(self.index)\n%0.1f%%", state.areaRatio * 100)
            self.contentView.backgroundColor = .green
        case .inScreen:
            self.contentView.backgroundColor = .white
            UIView.animate(withDuration: TimeInterval(self.durationThreshold ?? UIView.durationThreshold), delay: 0, options: [.curveLinear, .allowUserInteraction], animations: {
                self.contentView.backgroundColor = .red
            }, completion: nil)
        default:
            self.label.text = "\(self.index)\n"
            self.contentView.backgroundColor = .white
        }
    }
}
