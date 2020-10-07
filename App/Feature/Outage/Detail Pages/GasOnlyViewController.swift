//
//  GasOnlyViewController.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/15/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class GasOnlyViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: ZeroInsetDataDetectorTextView!
    
    @IBOutlet weak var textViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewLeadingConstraint: NSLayoutConstraint!
    
    var gasOnlyText: NSAttributedString {
        var localizedString: String
        let phoneNumbers: [String]
        switch Environment.shared.opco {
        case .bge:
            let phone1 = "1-800-685-0123"
            let phone2 = "1-877-778-7798"
            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat(
                """
                We currently do not allow reporting of gas issues online but want to hear from you right away.\n
                If you smell natural gas, leave the area immediately and call %@ or %@.
                """
                , phone1, phone2)
        case .peco:
            let phone1 = "1-800-841-4141"
            let phone2 = "1-877-778-7798"
            phoneNumbers = [phone1, phone2]
            localizedString = String.localizedStringWithFormat(
                """
                If you smell natural gas, leave the area immediately and call us at %@ or %@. Gas emergencies can not be reported through the mobile app.
                """
                , phone1, phone2)
        case .delmarva:
            let phone1 = "302-454-0317"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat(
                """
                Natural gas emergencies cannot be reported online, but we want to hear from you right away.\n
                If you smell natural gas, leave the area immediately and call %@.
                """
                , phone1)
        default:
            phoneNumbers = []
            localizedString = NSLocalizedString("We currently do not allow reporting of gas issues online but want to hear from you right away.", comment: "")
        }
        
        let attributedText = NSMutableAttributedString(string: localizedString, attributes: [.font: OpenSans.regular.of(textStyle: .subheadline)])
        for phone in phoneNumbers {
            localizedString.ranges(of: phone, options: .regularExpression)
                .map { NSRange($0, in: localizedString) }
                .forEach {
                    attributedText.addAttribute(.font, value: OpenSans.bold.of(textStyle: .subheadline), range: $0)
            }
        }
        return attributedText
    }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.attributedText = gasOnlyText
        style()
    }
    
    
    // MARK: - Helper
    
    private func style() {
        titleLabel.textColor = .deepGray
        titleLabel.font = SystemFont.semibold.of(textStyle: .title3)
        
        textView.textColor = .deepGray
        textView.font = SystemFont.regular.of(textStyle: .subheadline)
        
        let padding: CGFloat = Environment.shared.opco.isPHI ? 30.0 : 46.0
        textViewLeadingConstraint.constant = padding
        textViewTrailingConstraint.constant = padding
    }
}
