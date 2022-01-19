//
//  StatusInfoView.swift
//  EUMobile
//
//  Created by Gina Mullins on 12/9/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

enum StatusInfoMessage: Int {
    case etrToolTip
    case hazardMessage
    case rerouted
    case hasOutageDef
    case hasOutageNondef
    case whyStop
    case none
    
    var title: String {
        switch self {
            case .etrToolTip:
                return "Estimated Time of Restoration"
            case .hazardMessage:
                return "Safety Hazards Reported"
            case .rerouted:
                return "Why was the assigned BGE crew rerouted to a new location?"
            case .hasOutageDef, .hasOutageNondef:
                return "Still have an outage?"
            case .whyStop:
                return "Why did the BGE crew need to temporarily stop their work?"
            case .none:
                return ""
        }
    }
    
    var details: String {
        switch self {
            case .etrToolTip:
                return "At BGE we strive to give our customers the most up to date ETRs available. New information will be provided to keep you updated on our team's most recent estimate.\n\nETRs are first based on restoration repair history or data from previous storms. After that, the most accurate estimates come from our field crews."
            case .hazardMessage:
                return "BGE is investigating safety hazards reported in your area. Please keep in mind that fallen powerlines, street lights, sparking wires, and equipment on fire should never be approached or touched.\n\nCall BGE at %@ immediately to report a hazard."
            case .rerouted:
                return "This can occur during severe emergencies or potentially hazardous situations.\n\nA new BGE crew will be dispatched as soon as possible to restore your service."
            case .hasOutageDef:
                return "Your address is equipped with a smart meter reporting that the power is on.\n\nIf you are still experiencing a power outage, please check that your fuses or circuit breakers are on."
            case .hasOutageNondef:
                return "If you are still experiencing a power outage, please check that your fuses or circuit breakers are on.\n\nIf you still do not have power, please help us by reporting the outage."
            case .whyStop:
                return "This can occur when specialized equipment is needed, or to take appropriate safety precautions for our workers due to system damage and severe weather.\n\nA BGE crew will return as soon as possible to continue working to restore your service."
            case .none:
                return ""
        }
    }
}

protocol StatusInfoViewDelegate: AnyObject {
    func dismissInfoView()
    func reportOutagePressed()
}

class StatusInfoView: UIView {

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var messageView: UIView!
    @IBOutlet private weak var infoTitleLabel: UILabel!
    @IBOutlet private weak var textView: ZeroInsetDataDetectorTextView!
    @IBOutlet private weak var buttonContainerView: UIView!
    @IBOutlet private weak var buttonView: UIView!
    @IBOutlet private weak var reportButton: PrimaryButton!
    @IBOutlet private weak var alertImageView: UIImageView!
    @IBOutlet private weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var messageViewWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: StatusInfoViewDelegate?
    
    func configure(withInfo info: StatusInfoMessage) {
        infoTitleLabel.text = NSLocalizedString(info.title, comment: "")
        alertImageView.isHidden = info != .hazardMessage
        buttonContainerView.isHidden = info != .hasOutageNondef
        titleTopConstraint.constant = info == .hazardMessage ? 88 : 50
        
        if info == .hazardMessage {
            textView.tintColor = .actionBlue // For the phone numbers
            textView.attributedText = hazardText(text: info.details)
        } else {
            textView.text = info.details
        }
    }
    
    private func hazardText(text: String) -> NSAttributedString {
        let phone1 = "1-877-778-2222"
        let phoneNumbers = [phone1]
        let localizedString = String.localizedStringWithFormat(text, phone1)
        
        let attributedText = NSMutableAttributedString(string: localizedString, attributes: [.font: SystemFont.regular.of(textStyle: .caption1)])
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attributedText.addAttribute(.font, value: SystemFont.semibold.of(textStyle: .caption1), range: $0)
                }
        }
        return attributedText
    }
    
    @IBAction func dismissedPressed(_ sender: Any) {
        if let delegate = self.delegate {
            delegate.dismissInfoView()
        }
    }
    
    @IBAction func reportOutagePressed(_ sender: Any) {
        if let delegate = self.delegate {
            delegate.reportOutagePressed()
        }
    }
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(self.className, owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        messageView.roundCorners(.allCorners, radius: 10)
        buttonView.layer.cornerRadius = buttonView.frame.size.height / 2
        buttonView.clipsToBounds = true
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        var newWidth = screenWidth - 62
        if newWidth > 398 {
            newWidth = 398
        }
        messageViewWidthConstraint.constant = newWidth
    }

}
