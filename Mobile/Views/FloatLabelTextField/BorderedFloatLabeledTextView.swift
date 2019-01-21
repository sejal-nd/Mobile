//
//  BorderedFloatLabeledTextView.swift
//  Mobile
//
//  Created by Samuel Francis on 6/12/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import JVFloatLabeledTextField

class BorderedFloatLabeledTextView: JVFloatLabeledTextView {
    
    var cornerLayer: CALayer?
    
    // We have to add the borders here because the textView's frame is not yet available in either
    // FloatLabelTextField.commonInit() or FloatLabelTextField.layoutSubviews()
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // So that we don't add duplicate borders
        cornerLayer?.removeFromSuperlayer()
        cornerLayer = addRoundedTopRightBorder(radius: 4,
                                               borderColor: .accentGray,
                                               borderWidth: 2.0 / UIScreen.main.scale)
    }
}
