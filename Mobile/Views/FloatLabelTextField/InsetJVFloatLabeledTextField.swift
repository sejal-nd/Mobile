//
//  InsetJVFloatLabeledTextField.swift
//  Mobile
//
//  Created by Marc Shilling on 2/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField

class InsetJVFloatLabeledTextField: JVFloatLabeledTextField {
    
    var borderLayers = [CALayer]()
    var isShowingAccessory = false
    var isShowingLeftAccessory = false
    var customAccessibilityLabel: String?
    
    override var accessibilityLabel: String? {
        get {
            if let _ = self.text {
                if let customA11yLabel = customAccessibilityLabel {
                    return customA11yLabel
                } else if let floatLabelText = self.floatingLabel.text {
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
        floatingLabelXPadding = isShowingLeftAccessory ? -51 : 0
        if isShowingAccessory && !isShowingLeftAccessory {
            if hasText {
                return CGRect(x: 8, y: 7, width: bounds.size.width - 51, height: bounds.size.height)
            }
            return CGRect(x: 8, y: 0, width: bounds.size.width - 51, height: bounds.size.height)
        } else if isShowingLeftAccessory && !isShowingAccessory {
            if hasText {
                return CGRect(x: 59, y: 7, width: bounds.size.width - 51, height: bounds.size.height)
            }
            return CGRect(x: 59, y: 0, width: bounds.size.width - 51, height: bounds.size.height)
        } else if isShowingAccessory && isShowingLeftAccessory {
            if hasText {
                return CGRect(x: 59, y: 7, width: bounds.size.width - 102, height: bounds.size.height)
            }
            return CGRect(x: 59, y: 0, width: bounds.size.width - 102, height: bounds.size.height)
        } else {
            if hasText {
                return CGRect(x: 8, y: 7, width: bounds.size.width - 16, height: bounds.size.height)
            }
            return CGRect(x: 8, y: 0, width: bounds.size.width - 16, height: bounds.size.height)
        }
    }
    
    // We have to add the borders here because the textView's frame is not yet available in either
    // FloatLabelTextField.commonInit() or FloatLabelTextField.layoutSubviews()
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // So that we don't add duplicate borders
        for layer in borderLayers {
            layer.removeFromSuperlayer()
        }
        
        let edgeWidth = 1.0 / UIScreen.main.scale
        
        borderLayers.append(addRoundedTopRightBorder(radius: 4, borderColor: .accentGray, borderWidth: 2 * edgeWidth))
        borderLayers.append(addTopBorder(color: .accentGray, width: edgeWidth))
        borderLayers.append(addRightBorder(color: .accentGray, width: edgeWidth))
        borderLayers.append(addBottomBorder(color: .accentGray, width: edgeWidth))
    }
    
}
