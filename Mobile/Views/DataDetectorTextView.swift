//
//  DataDetectorTextView.swift
//  Mobile
//
//  Created by Marc Shilling on 3/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

class DataDetectorTextView: UITextView {
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        isEditable = false
        dataDetectorTypes = .phoneNumber
        
        var mutableGestureRecognizers = [UIGestureRecognizer]()
        for gestureRecognizer in gestureRecognizers! {
            if gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) {
                let longPressGestureRecognizer = gestureRecognizer as! UILongPressGestureRecognizer
                if longPressGestureRecognizer.minimumPressDuration < 0.3 {
                    mutableGestureRecognizers.append(gestureRecognizer)
                }
            }
            if gestureRecognizer.isKind(of: UITapGestureRecognizer.self) {
                let tapGestureRecognizer = gestureRecognizer as! UITapGestureRecognizer
                if (tapGestureRecognizer.numberOfTapsRequired < 2) {
                    mutableGestureRecognizers.append(gestureRecognizer)
                }
            }
        }
        gestureRecognizers = mutableGestureRecognizers
    }

}
