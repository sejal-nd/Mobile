//
//  ForgotUsernameResultViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/10/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class ForgotUsernameResultViewController: UIViewController {
    
    @IBOutlet weak var topTextView: UITextView!
    @IBOutlet weak var topTextViewHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Forgot Username", comment: "")
        
        let signInString = NSLocalizedString("Sign In", comment: "")
        let localizedString = String(format: NSLocalizedString("Remember your username? You can %@, or you can select an account to answer its security question to view your full username.", comment: ""), signInString)

        let attrString = NSMutableAttributedString(string: localizedString)
        let fullRange = NSMakeRange(0, attrString.length)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 24 // Line height
        attrString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: fullRange)
        
        attrString.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 16, weight: UIFontWeightSemibold), range: fullRange)
        attrString.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkJungleGreen, range: fullRange)
        let url = URL(fileURLWithPath: "") // Does not matter
        attrString.addAttribute(NSLinkAttributeName, value: url, range: (localizedString as NSString).range(of: signInString))
        
        topTextView.textContainerInset = .zero
        topTextView.attributedText = attrString
        
        // In case the localized string needs to grow the text view:
        topTextView.sizeToFit()
        topTextView.layoutIfNeeded()
        topTextViewHeightConstraint.constant = topTextView.sizeThatFits(CGSize(width: topTextView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
    }
    
    func onBackToSignInPress() {
        for vc in (navigationController?.viewControllers)! {
            if vc.isKind(of: LoginViewController.self) {
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }
    }

}

extension ForgotUsernameResultViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        onBackToSignInPress()
        return false
    }
    
}
