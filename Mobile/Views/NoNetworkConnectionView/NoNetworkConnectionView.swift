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
            styleViews()
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
    
    private func commonInit() {
        Bundle.main.loadNibNamed(NoNetworkConnectionView.className, owner: self, options: nil)
        containerView.frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(containerView)
        styleViews()
    }
    
    private func styleViews() {
        reloadLabel.font = SystemFont.bold.of(textStyle: .headline)
        noNetworkConnectionLabel.font = OpenSans.semibold.of(textStyle: .title1)
        pleaseReloadLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        
        switch (isColorBackground, StormModeStatus.shared.isOn) {
        // Colored Background
        case (true, false):
            containerView.backgroundColor = .primaryColor
            noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork")
            reloadImageView.image = #imageLiteral(resourceName: "ic_reload")
            reloadLabel.textColor = .white
            noNetworkConnectionLabel.textColor = .white
            pleaseReloadLabel.textColor = .white
            contactDetailsSpacerView.isHidden = true
            contactDetailsTextView.isHidden = true
            
        // Light Background
        case (false, false):
            containerView.backgroundColor = .softGray
            noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork_color")
            reloadImageView.image = #imageLiteral(resourceName: "ic_reload_blue")
            reloadLabel.textColor = .actionBlue
            noNetworkConnectionLabel.textColor = .blackText
            pleaseReloadLabel.textColor = .blackText
            contactDetailsSpacerView.isHidden = true
            contactDetailsTextView.isHidden = true
            
        // Storm Mode
        case (_, true):
            containerView.backgroundColor = .clear
            noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork_sm.pdf")
            reloadImageView.image = #imageLiteral(resourceName: "ic_reload")
            reloadLabel.textColor = .white
            noNetworkConnectionLabel.textColor = .white
            pleaseReloadLabel.textColor = .white
            contactDetailsTextView.textColor = .white
            contactDetailsSpacerView.isHidden = false
            contactDetailsTextView.isHidden = false
            configureContactText()
        }
    }
    
    private func configureContactText() {
        let downedPowerLineText: String
        let phoneNumber: String
        switch Environment.shared.opco {
        case .comEd:
            downedPowerLineText = NSLocalizedString("To report a downed or sparking power line, please call ", comment: "")
            phoneNumber = "1-800-685-0123"
        case .bge:
            downedPowerLineText = NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call ", comment: "")
            phoneNumber = "1-800-334-7661"
        case .peco:
            downedPowerLineText = NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call ", comment: "")
            phoneNumber = "1-800-841-4141"
        }
        
        let downedPowerLineAttributedText = NSMutableAttributedString(string: downedPowerLineText,
                                                                      attributes: [.foregroundColor: UIColor.white,
                                                                                   .font: OpenSans.regular.of(textStyle: .subheadline)])
        
        let phoneNumberAttributedText = NSAttributedString(string: phoneNumber,
                                                           attributes: [.font: OpenSans.semibold.of(textStyle: .subheadline)])
        
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        downedPowerLineAttributedText.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, downedPowerLineAttributedText.string.count))
        
        downedPowerLineAttributedText.append(phoneNumberAttributedText)
        
        contactDetailsTextView.attributedText = downedPowerLineAttributedText
    }
    
    private(set) lazy var reload: Observable<Void> = self.reloadButton.rx.touchUpInside.asObservable()
}

extension NoNetworkConnectionView: DataDetectorTextViewLinkTapDelegate {
    
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL) {
        Analytics.log(event: .outageAuthEmergencyCall)
    }
    
}
