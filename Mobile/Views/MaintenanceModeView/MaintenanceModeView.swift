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
                containerView.backgroundColor = .clear
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
            let localizedText = NSLocalizedString("%@ is currently unavailable due to\nscheduled maintenance.", comment: "")
            detailLabel.text = String(format: localizedText, sectionName)
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
    }
    
    func styleViews() {
        reloadLabel.font = SystemFont.bold.of(textStyle: .headline)
        scheduledMaintenanceLabel.font = OpenSans.semibold.of(textStyle: .title1)
        detailLabel.font = OpenSans.regular.of(textStyle: .subheadline)
        infoTextContainerView.addShadow(color: .black, opacity: 0.15, offset: .zero, radius: 4)
    }
    
    let infoText: NSAttributedString = {
        let leaveAreaString = NSLocalizedString("leave the area immediately", comment: "")
        let emergencyAttrString: NSMutableAttributedString
        var localizedString: String
        
        let phone1: String
        let phone2: String
        switch Environment.sharedInstance.opco {
        case .bge:
            phone1 = "1-800-685-0123"
            phone2 = "1-877-778-2222"
            localizedString = String(format: NSLocalizedString("If you smell natural gas or see downed power lines, %@ and then call BGE at %@\n\nIf your power is out, call %@", comment: ""), leaveAreaString, phone1, phone2)
        case .comEd:
            phone1 = "1-800-334-7661"
            phone2 = "\n1-800-334-7661" // Included the line break in the second number so the range(of:) method could find it, and bold it. Not hacky at all 👀
            localizedString = String(format: NSLocalizedString("If you see downed power lines, %@ and then call ComEd at %@ Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call%@ M-F 7AM to 7PM", comment: ""), leaveAreaString, phone1, phone2)
        case .peco:
            phone1 = "1-800-841-4141"
            phone2 = "1-800-494-4000"
            localizedString = String(format: NSLocalizedString("If you smell natural gas or see downed power lines, %@ and then call PECO at %@ Representatives are available 24 hours a day, 7 days a week.\n\nFor all other inquiries, please call\n%@ M-F 7AM to 7PM", comment: ""), leaveAreaString, phone1, phone2)
        }
        
        emergencyAttrString = NSMutableAttributedString(string: localizedString)
        emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: leaveAreaString))
        emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phone1))
        emergencyAttrString.addAttribute(.font, value: OpenSans.bold.of(textStyle: .footnote), range: (localizedString as NSString).range(of: phone2))
        
        return emergencyAttrString
    }()
    
    private(set) lazy var reload: Observable<Void> = self.reloadButton.rx.touchUpInside.asObservable()
}
