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
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat(
                """
                We currently do not allow reporting of gas issues online but want to hear from you right away.\n
                To issue a Gas Emergency Order, please call %@.
                """
                , phone1)
        case .delmarva:
            let phone1 = "302-454-0317"
            phoneNumbers = [phone1]
            localizedString = String.localizedStringWithFormat(
                """
                Natural gas emergencies cannot be reported online, but we want to hear from you right away.
                If you smell natural gas, leave the area immediately and call %@
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
    }
}
