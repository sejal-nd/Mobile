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
    @IBOutlet weak var contactDetailsSpacerView: UIView!
    @IBOutlet weak var contactDetailsTextView: DataDetectorTextView! {
        didSet {
            contactDetailsTextView.textContainerInset = .zero
            contactDetailsTextView.textColor = .softGray
            contactDetailsTextView.tintColor = .white // For phone numbers
            contactDetailsTextView.linkTapDelegate = self
        }
    }
    
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
                containerView.backgroundColor = .softGray
                noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork_color")
                reloadImageView.image = #imageLiteral(resourceName: "ic_reload_blue")
                reloadLabel.textColor = .actionBlue
                noNetworkConnectionLabel.textColor = .blackText
                pleaseReloadLabel.textColor = .blackText
            }
        }
    }
    
    @IBInspectable var isStormMode: Bool = false {
        didSet {
            if isStormMode {
                containerView.backgroundColor = .clear
                noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork_color")
                contactDetailsSpacerView.isHidden = false
                contactDetailsTextView.isHidden = false
            } else {
                contactDetailsSpacerView.isHidden = true
                contactDetailsTextView.isHidden = true
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
        styleViews()
        contactDetailsSpacerView.isHidden = true
        contactDetailsTextView.isHidden = true
    }
    
    func styleViews() {
        containerView.backgroundColor = .primaryColor
        reloadLabel.font = SystemFont.bold.of(textStyle: .headline)
        noNetworkConnectionLabel.font = OpenSans.semibold.of(textStyle: .title1)
        pleaseReloadLabel.font = OpenSans.regular.of(textStyle: .subheadline)
    }
    
    public func configureContactText(attributedText: NSMutableAttributedString) {
        contactDetailsTextView.attributedText = attributedText
        if isStormMode {
            contactDetailsTextView.textColor = .white
        }
    }
    
    private(set) lazy var reload: Observable<Void> = self.reloadButton.rx.touchUpInside.asObservable()
}

extension NoNetworkConnectionView: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        Analytics.log(event: .outageAuthEmergencyCall)
    }
    
}
