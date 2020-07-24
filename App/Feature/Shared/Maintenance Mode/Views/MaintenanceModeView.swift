//
//  MaintenanceModeView.swift
//  Mobile
//
//  Created by Samuel Francis on 4/30/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MaintenanceModeView: UIView {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var maintenanceImageView: UIImageView!
    @IBOutlet weak var reloadButton: ButtonControl!
    @IBOutlet weak var reloadImageView: UIImageView!
    @IBOutlet weak var reloadLabel: UILabel!
    @IBOutlet weak var scheduledMaintenanceLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var infoTextContainerView: UIView!
    @IBOutlet weak var infoTextView: DataDetectorTextView!
    
    let disposeBag = DisposeBag()
    
    @IBInspectable var isColorBackground: Bool = true {
        didSet {
            if isColorBackground {
                containerView.backgroundColor = .primaryColor
                maintenanceImageView.image = #imageLiteral(resourceName: "ic_maint_mode_white")
                reloadImageView.image = #imageLiteral(resourceName: "ic_reload")
                reloadLabel.textColor = .white
                scheduledMaintenanceLabel.textColor = .white
                detailLabel.textColor = .white
            } else {
                containerView.backgroundColor = .softGray
                maintenanceImageView.image = #imageLiteral(resourceName: "ic_maint_mode")
                reloadImageView.image = #imageLiteral(resourceName: "ic_reload_blue")
                reloadLabel.textColor = .actionBlue
                scheduledMaintenanceLabel.textColor = .blackText
                detailLabel.textColor = .blackText
            }
        }
    }
    
    @IBInspectable var showInfoText: Bool = false {
        didSet {
            infoTextContainerView.isHidden = !showInfoText
        }
    }
    
    @IBInspectable var sectionName: String = "" {
        didSet {
            detailLabel.text = String.localizedStringWithFormat("%@ is currently unavailable due to maintenance.", sectionName)
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
        Bundle.main.loadNibNamed(MaintenanceModeView.className, owner: self, options: nil)
        containerView.frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(containerView)
        containerView.backgroundColor = .primaryColor
        reloadButton.isAccessibilityElement = true
        reloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        styleViews()
        infoTextView.attributedText = infoText
        infoTextView.accessibilityLabel = infoText.string
    }
    
    func styleViews() {
        reloadLabel.font = SystemFont.bold.of(textStyle: .headline)
        scheduledMaintenanceLabel.font = OpenSans.semibold.of(textStyle: .title1)
        detailLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        infoTextContainerView.layer.cornerRadius = 8.0
        infoTextContainerView.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 4)
        infoTextView.tintColor = .actionBlue
    }
    
    let infoText: NSAttributedString = {
        let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
        var localizedString: String
        
        let phoneNumbers: [String]
        switch Environment.shared.opco {
        case .bge:
            let phone1 = "1-800-685-0123"
            let phone2 = "1-877-778-7798"
            let phone3 = "1-877-778-2222"
            phoneNumbers = [phone1, phone2, phone3]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas, %@ and call BGE at %@ or %@\n
                If your power is out or for downed or sparking power lines, please call %@ or %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone1, phone2, phone1, phone3)
        case .comEd:
            let phone = "1-800-334-7661"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you see downed power lines, %@ and then call ComEd at %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone)
        case .peco:
            let phone = "1-800-841-4141"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas or see downed power lines, %@ and then call PECO at %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone)
        case .pepco:
            let phone = "1-877-737-2662"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas or see downed power lines, %@ and then call PECO at %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone)
        case .ace:
            let phone = "1-800-833-7476"
            phoneNumbers = [phone]
            localizedString = String.localizedStringWithFormat(
                """
                If you see a downed power line, %@ and then call %@\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone)
        case .delmarva:
            let phone1 = "1-800-898-8042"
            let phone2 = "302-454-0317"
            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat(
                """
                If you see a downed power line or smell natural gas, %@ and then call %@.\n
                For natural gas emergencies, call %@.\n
                Representatives are available 24 hours a day, 7 days a week.
                """
                , leaveAreaString, phone1, phone2)
        }
        
        let emergencyAttrString = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .footnote)])
        emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: $0)
            }
        }
        
        return emergencyAttrString
    }()
    
    private(set) lazy var reload: Observable<Void> = self.reloadButton.rx.touchUpInside.asObservable()
}
