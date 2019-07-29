//
//  UIViewController+AddCloseButton.swift
//  Mobile
//
//  Created by Joseph Erlandson on 7/9/19.
//  Copyright © 2019 Exelon Corporation. All rights reserved.
//

import UIKit

extension UIViewController {
    public func addCloseButton() {
        // Remove back button
        navigationItem.setHidesBackButton(true, animated: true)
        
        // Add X Button
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissModal))
        closeButton.accessibilityLabel = NSLocalizedString("Close", comment: "")
        navigationItem.setLeftBarButton(closeButton, animated: false)
    }
    
    
    // MARK: - Action
    
    @objc func dismissModal() {
        dismiss(animated: true, completion: nil)
    }
}
