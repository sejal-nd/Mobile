//
//  KeyboardAvoidingStickyFooterViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 7/17/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

class KeyboardAvoidingStickyFooterViewController: UIViewController {
    
    @IBOutlet weak var stickyFooterBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        // view.endEditing() triggers the `keyboardWillHideNotification` with a non-zero height,
        // so only trust the keyboardFrameValue for a `keyboardWillShowNotification`
        var keyboardHeight: CGFloat = 0
        if notification.name == UIResponder.keyboardWillShowNotification {
            keyboardHeight = keyboardFrameValue.cgRectValue.size.height
        }
        
        let options = UIView.AnimationOptions(rawValue: curve.uintValue<<16)
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.stickyFooterBottomConstraint.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
}
