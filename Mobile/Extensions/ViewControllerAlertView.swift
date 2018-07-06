//
//  ViewControllerAlertView.swift
//  BGE
//
//  Created by Joseph Erlandson on 7/6/18.
//  Copyright © 2018 Exelon Corporation. All rights reserved.
//

import UIKit

protocol Alertable {
    func presentAlert(title: String?, message: String?, style: UIAlertControllerStyle, actions: [UIAlertAction])
}

extension Alertable where Self: UIViewController {
    
    // may remove style since we want seperate funcs for action sheet and alert
    func presentAlert(title: String?, message: String?, style: UIAlertControllerStyle, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        for action in actions {
            alertController.addAction(action)
        }
        
        // Handles iPad Use of Action Sheet
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    // ensure we handle iPad case of no Action sheet.
    
//    public func presentActionSheet(title: String?, message: String?, actions: [UIAlertAction]) {
//        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
//
//        for action in actions {
//            alertView.addAction(action)
//        }
//
//        present(alertView, animated: true, completion: nil)
//    }
    // presentActionSheet()
    
}
