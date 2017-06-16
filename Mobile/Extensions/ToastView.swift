//
//  ToastView.swift
//  Mobile
//
//  Created by Marc Shilling on 6/15/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import ToastSwiftFramework

extension UIView {
    
    func showToast(_ message: String, twoLines: Bool = false, distanceFromBottom: CGFloat = 50) {
        if twoLines {
            var toastStyle = ToastManager.shared.style
            toastStyle.verticalPadding = 10
            toastStyle.horizontalPadding = 44
            toastStyle.cornerRadius = 30
            self.makeToast(message, duration: 5.0, position: CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height - distanceFromBottom), style: toastStyle)
        } else {
            self.makeToast(message, duration: 5.0, position: CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height - distanceFromBottom))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500), execute: {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, message)
        })
    }
}
