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
        navigationItem.setLeftBarButton(closeButton, animated: false)
    }
    
    
    // MARK: - Action
    
    @objc
    private func dismissModal() {
        dismiss(animated: true, completion: nil)
    }
}
