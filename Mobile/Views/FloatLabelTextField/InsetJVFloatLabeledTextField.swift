//
//  InsetJVFloatLabeledTextField.swift
//  Mobile
//
//  Created by Marc Shilling on 2/23/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import JVFloatLabeledText

class InsetJVFloatLabeledTextField: JVFloatLabeledTextField {
    
    var borderLayers = [CALayer]()
    var isShowingAccessory = false
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        if isShowingAccessory {
            if hasText {
                return CGRect(x: 8, y: 7, width: bounds.size.width - 51, height: bounds.size.height)
            }
            return CGRect(x: 8, y: 0, width: bounds.size.width - 51, height: bounds.size.height)
        } else {
            if hasText {
                return CGRect(x: 8, y: 7, width: bounds.size.width - 16, height: bounds.size.height)
            }
            return CGRect(x: 8, y: 0, width: bounds.size.width - 16, height: bounds.size.height)
        }
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        if isShowingAccessory {
            if hasText {
                return CGRect(x: 8, y: 7, width: bounds.size.width - 51, height: bounds.size.height)
            }
            return CGRect(x: 8, y: 0, width: bounds.size.width - 51, height: bounds.size.height)
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
        
        borderLayers.append(addTopBorder(color: .timberwolf, width: 0.5))
        borderLayers.append(addRightBorder(color: .timberwolf, width: 0.5))
        borderLayers.append(addBottomBorder(color: .timberwolf, width: 0.5))
    }
    
}
