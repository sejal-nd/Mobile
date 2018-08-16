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
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var noNetworkImageView: UIImageView!
    @IBOutlet weak var reloadButton: ButtonControl!
    @IBOutlet weak var reloadImageView: UIImageView!
    @IBOutlet weak var reloadLabel: UILabel!
    @IBOutlet weak var noNetworkConnectionLabel: UILabel!
    @IBOutlet weak var pleaseReloadLabel: UILabel!
    
    @IBInspectable var isColorBackground: Bool = true {
        didSet {
            if isColorBackground {
                containerView.backgroundColor = .primaryColor
                noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork")
                reloadImageView.image = #imageLiteral(resourceName: "ic_reload")
                reloadLabel.textColor = .white
                noNetworkConnectionLabel.textColor = .white
                pleaseReloadLabel.textColor = .white
            } else {
                containerView.backgroundColor = .white
                noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork_color")
                reloadImageView.image = #imageLiteral(resourceName: "ic_reload_blue")
                reloadLabel.textColor = .actionBlue
                noNetworkConnectionLabel.textColor = .blackText
                pleaseReloadLabel.textColor = .blackText
            }
        }
    }

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
