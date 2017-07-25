//
//  NoNetworkConnectionView.swift
//  Mobile
//
//  Created by Sam Francis on 7/25/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class NoNetworkConnectionView: UIView {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var reloadButton: ButtonControl!
    @IBOutlet var reloadLabel: UILabel!
    @IBOutlet var noNetworkConnectionLabel: UILabel!
    @IBOutlet var pleaseReloadLabel: UILabel!
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(NoNetworkConnectionView.className, owner: self, options: nil)
        containerView.frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(containerView)
        containerView.backgroundColor = .primaryColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        styleViews()
    }
    
    func styleViews() {
        reloadLabel.font = SystemFont.bold.of(textStyle: .headline)
        noNetworkConnectionLabel.font = OpenSans.semibold.of(textStyle: .title1)
        pleaseReloadLabel.font = OpenSans.regular.of(textStyle: .subheadline)
    }
    
    private(set) lazy var reload: Observable<Void> = self.reloadButton.rx.touchUpInside.asObservable()
}
