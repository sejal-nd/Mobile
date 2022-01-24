//
//  GasOnlyView.swift
//  EUMobile
//
//  Created by Gina Mullins on 12/21/21.
//  Copyright © 2021 Exelon Corporation. All rights reserved.
//

import UIKit

class GasOnlyView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var gasImageView: UIImageView!
    @IBOutlet private weak var gasTitleLabel: UILabel!
    @IBOutlet private weak var textView: ZeroInsetDataDetectorTextView!
    @IBOutlet private weak var footerTextView: ZeroInsetDataDetectorTextView!
    
    var gasText: NSAttributedString {
        let phone1 = "1-877-778-7798"
        let phoneNumbers = [phone1]
        let localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas, leave the area immediately and call us at %@.
                """
                ,phone1)
        
        let attributedText = NSMutableAttributedString(string: localizedString, attributes: [.font: SystemFont.regular.of(textStyle: .subheadline)])
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attributedText.addAttribute(.font, value: SystemFont.semibold.of(textStyle: .subheadline), range: $0)
                }
        }
        return attributedText
    }
    
    var footerText: NSAttributedString {
        let phone1 = "1-877-778-7798"
        let phone2 = "1-877-778-2222"
        let phone3 = "1-800-685-0123"
        let phoneNumbers = [phone1, phone2, phone3]
        let localizedString = String.localizedStringWithFormat(
                """
                Please call %@ to report a natural gas emergency. Natural gas emergencies cannot be reported online.\n\nFor downed power lines, stay away from the area and call BGE at %@ or %@.
                """
                ,phone1, phone2, phone3)
        
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
    
    
    private func configureFooterTextView() {
        textView.font = SystemFont.regular.of(textStyle: .footnote)
        textView.attributedText = gasText
        textView.textColor = .blackText
        textView.tintColor = .actionBlue // For the phone numbers
        
        footerTextView.font = SystemFont.regular.of(textStyle: .footnote)
        footerTextView.attributedText = footerText
        footerTextView.textColor = .blackText
        footerTextView.tintColor = .actionBlue // For the phone numbers
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
        
        configureFooterTextView()
    }

}
