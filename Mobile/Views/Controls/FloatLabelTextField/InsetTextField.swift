//
//  InsetTextField.swift
//  Mobile
//
//  Created by Marc Shilling on 6/25/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class InsetTextField: UITextField {

    var isShowingAccessory = false
    var customAccessibilityLabel: String?
    
    /* We need this because setting the text programatically (textField.text = "like this"), does
     * NOT trigger rx.text (or rx.controlEvent(.valueChanged)) observers. I tried just calling
     * `sendActions(for: .valueChanged)` in the didSet, but that can cause an infinite loop in places
     * like Make A Payment where we transform (and then re-set) text as the user types. */
    var textPublishSubject = PublishSubject<String?>()
    override var text: String? {
        didSet {
            textPublishSubject.onNext(text)
        }
    }
    
    override var accessibilityLabel: String? {
        get {
            if let _ = self.text {
                if let customA11yLabel = customAccessibilityLabel {
                    return customA11yLabel
                } else if let floatLabelText = placeholder {
                    return floatLabelText.replacingOccurrences(of: "*", with: NSLocalizedString(", required", comment: ""))
                }
            }
            return ""
        }
        set { }
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return getRect(forBounds: bounds)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return getRect(forBounds: bounds)
    }
    
    override var isSecureTextEntry: Bool {
        didSet {
            // Hides the caps lock icon that appears, which conflicts with our password eyeball.
            rightView = isSecureTextEntry ? UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0)) : nil
        }
    }
    
    func getRect(forBounds bounds: CGRect) -> CGRect {
        if isShowingAccessory {
            if hasText {
                return CGRect(x: 16, y: 7, width: bounds.size.width - 59, height: bounds.size.height)
            }
            return CGRect(x: 16, y: 0, width: bounds.size.width - 59, height: bounds.size.height)
        } else {
            if hasText {
                return CGRect(x: 16, y: 7, width: bounds.size.width - 32, height: bounds.size.height)
            }
            return CGRect(x: 16, y: 0, width: bounds.size.width - 32, height: bounds.size.height)
        }
    }

}

