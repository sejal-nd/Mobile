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
    
    @IBOutlet weak var stormModeContactView: UIView!
    @IBOutlet weak var contactGroup1StackView: UIStackView!
    @IBOutlet weak var group1Label: UILabel!
    @IBOutlet weak var phone1Button: ButtonControl!
    @IBOutlet weak var phone1Label: UILabel!
    @IBOutlet weak var phone2Button: ButtonControl!
    @IBOutlet weak var phone2Label: UILabel!
    @IBOutlet weak var contactGroup2StackView: UIStackView!
    @IBOutlet weak var group2Label: UILabel!
    @IBOutlet weak var phone3Button: ButtonControl!
    @IBOutlet weak var phone3Label: UILabel!
    @IBOutlet weak var phone4Button: ButtonControl!
    @IBOutlet weak var phone4Label: UILabel!
    
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
        group1Label.font = OpenSans.regular.of(textStyle: .subheadline)
        group2Label.font = OpenSans.regular.of(textStyle: .subheadline)
        phone1Button.roundCorners(.allCorners, radius: 4)
        phone1Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        phone2Button.roundCorners(.allCorners, radius: 4)
        phone2Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        phone3Button.roundCorners(.allCorners, radius: 4)
        phone3Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        phone4Button.roundCorners(.allCorners, radius: 4)
        phone4Button.addShadow(color: .black, opacity: 0.2, offset: CGSize(width: 0, height: 1), radius: 3)
        
        switch (isColorBackground, StormModeStatus.shared.isOn) {
        // Colored Background
        case (true, false):
            containerView.backgroundColor = .primaryColor
            noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork")
            reloadImageView.image = #imageLiteral(resourceName: "ic_reload")
            reloadLabel.textColor = .white
            noNetworkConnectionLabel.textColor = .white
            pleaseReloadLabel.textColor = .white
            stormModeContactView.isHidden = true
            
        // Light Background
        case (false, false):
            containerView.backgroundColor = .softGray
            noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork_color")
            reloadImageView.image = #imageLiteral(resourceName: "ic_reload_blue")
            reloadLabel.textColor = .actionBlue
            noNetworkConnectionLabel.textColor = .blackText
            pleaseReloadLabel.textColor = .blackText
            stormModeContactView.isHidden = true
            
        // Storm Mode
        case (_, true):
            containerView.backgroundColor = .clear
            noNetworkImageView.image = #imageLiteral(resourceName: "ic_nonetwork_sm.pdf")
            reloadImageView.image = #imageLiteral(resourceName: "ic_reload")
            reloadLabel.textColor = .white
            noNetworkConnectionLabel.textColor = .white
            pleaseReloadLabel.textColor = .white
            stormModeContactView.isHidden = false
            configureContactText()
        }
    }
    
    private func configureContactText() {
        if Environment.shared.opco != .bge {
            contactGroup2StackView.isHidden = true
            phone2Button.isHidden = true
        }

        switch Environment.shared.opco {
        case .bge:
            group1Label.text = NSLocalizedString("If you smell natural gas, leave the area immediately and call", comment: "")
            group2Label.text = NSLocalizedString("For downed or sparking power lines, please call", comment: "")
            phone1Label.text = "1-800-685-0123"
            phone2Label.text = "1-877-778-7798"
            phone3Label.text = "1-800-685-0123"
            phone4Label.text = "1-877-778-2222"
        case .comEd:
            group1Label.text = NSLocalizedString("To report a downed or sparking power line, please call", comment: "")
            phone1Label.text = "1-800-334-7661"
        case .peco:
            group1Label.text = NSLocalizedString("To report a gas emergency or a downed or sparking power line, please call", comment: "")
            phone1Label.text = "1-800-841-4141"
        }
        
        phone1Button.accessibilityLabel = phone1Label.text
        phone2Button.accessibilityLabel = phone2Label.text
        phone3Button.accessibilityLabel = phone3Label.text
        phone4Button.accessibilityLabel = phone4Label.text
    }
    
    private(set) lazy var reload: Observable<Void> = self.reloadButton.rx.touchUpInside.asObservable()
    
    @IBAction func onPhoneNumberPress(_ sender: ButtonControl) {
        let phone: String?
        switch sender {
        case phone1Button:
            phone = phone1Label.text
        case phone2Button:
            phone = phone2Label.text
        case phone3Button:
            phone = phone3Label.text
        case phone4Button:
            phone = phone4Label.text
        default:
            phone = nil // Won't happen
        }
        
        if let phone = phone, let url = URL(string: "telprompt://\(phone)"), UIApplication.shared.canOpenURL(url) {
            Analytics.log(event: .outageAuthEmergencyCall)
            UIApplication.shared.open(url)
        }
    }
}
