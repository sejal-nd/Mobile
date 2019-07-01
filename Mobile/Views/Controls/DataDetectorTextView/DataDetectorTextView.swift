//
//  DataDetectorTextView.swift
//  Mobile
//
//  Created by Marc Shilling on 3/20/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit

protocol DataDetectorTextViewLinkTapDelegate: class {
    func dataDetectorTextView(_ textView: DataDetectorTextView, didInteractWith URL: URL)
}

class DataDetectorTextView: UITextView, UITextViewDelegate {
    
    weak var linkTapDelegate: DataDetectorTextViewLinkTapDelegate?
    
    var voiceOverRunning: Bool {
        get {
            return UIAccessibility.isVoiceOverRunning
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    private func commonInit() {
        isEditable = false
        dataDetectorTypes = .phoneNumber
        accessibilityTraits = .staticText
        
        didChangeVoiceOver()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeVoiceOver), name: NSNotification.Name(rawValue: UIAccessibilityVoiceOverStatusChanged), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didChangeVoiceOver() {
        if voiceOverRunning {
            delegate = nil
        } else {
            delegate = self
        }
    }
    
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        linkTapDelegate?.dataDetectorTextView(self, didInteractWith: URL)
        return true
    }
    
}
