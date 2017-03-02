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
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.insetBy(dx: 8, dy: 0)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.insetBy(dx: 8, dy: 0)
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
