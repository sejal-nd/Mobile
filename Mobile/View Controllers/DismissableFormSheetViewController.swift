//
//  DismissableFormSheetViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit


class DismissableFormSheetViewController: UIViewController {
    
    private var tapOutsideRecognizer: UITapGestureRecognizer!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if tapOutsideRecognizer == nil && UIDevice.current.userInterfaceIdiom == .pad {
            tapOutsideRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapBehind))
            tapOutsideRecognizer.numberOfTapsRequired = 1
            tapOutsideRecognizer.cancelsTouchesInView = false
            tapOutsideRecognizer.delegate = self
            
            if let window = UIApplication.shared.delegate?.window ?? nil {
                window.addGestureRecognizer(tapOutsideRecognizer)
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // If we want to customize the cornerRadius:
        //self.view.superview?.layer.cornerRadius = 30
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if tapOutsideRecognizer != nil {
            if let window = UIApplication.shared.delegate?.window ?? nil {
                window.removeGestureRecognizer(tapOutsideRecognizer)
            }
            tapOutsideRecognizer = nil
        }
    }
    
    @objc func handleTapBehind(sender: UITapGestureRecognizer) {
        
        if sender.state == .ended {
            var location: CGPoint = sender.location(in: nil)
            
            if UIApplication.shared.statusBarOrientation.isLandscape {
                location = CGPoint(x: location.y, y: location.x)
            }
            
            if !view.point(inside: view.convert(location, from: view.window), with: nil) {
                view.window?.removeGestureRecognizer(sender)
                dismiss(animated: true, completion: nil)
            }
        }
    }

}

extension DismissableFormSheetViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
