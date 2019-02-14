//
//  ToastView.swift
//  Mobile
//
//  Created by Marc Shilling on 6/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Toast_Swift

extension UIView {
    
    func showToast(_ message: String, twoLines: Bool = false) {
        makeToast(message, duration: 5, position: .bottom, title: nil, image: nil, style: ToastManager.shared.style, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: {
            UIAccessibility.post(notification: .announcement, argument: message)
        })
    }
}
