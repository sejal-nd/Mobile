//
//  LoadingVIew.swift
//  Mobile
//
//  Created by Marc Shilling on 3/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import Lottie

class LoadingView: UIView {
    
    static let shared = LoadingView(frame: .zero)
    
    private var loadingAnimationView = AnimationView(name: "full_screen_loading")
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        loadingAnimationView.frame.size = CGSize(width: 72, height: 72)
        loadingAnimationView.loopMode = .loop
        loadingAnimationView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(loadingAnimationView)
        
        loadingAnimationView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        loadingAnimationView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Not coder compliant")
    }
    
    public class func show(animated: Bool = true) {
        let loadingView = LoadingView.shared
        
        loadingView.frame = loadingView.containerView.bounds
        loadingView.isAccessibilityElement = true
        loadingView.accessibilityLabel = NSLocalizedString("Loading", comment: "")
        loadingView.accessibilityViewIsModal = true
        if loadingView.superview == nil {
            loadingView.alpha = 0.0
            
            loadingView.containerView.addSubview(loadingView)
            
            loadingView.topAnchor.constraint(equalTo: loadingView.containerView.topAnchor, constant: 0).isActive = true
            loadingView.bottomAnchor.constraint(equalTo: loadingView.containerView.bottomAnchor, constant: 0).isActive = true
            loadingView.leadingAnchor.constraint(equalTo: loadingView.containerView.leadingAnchor, constant: 0).isActive = true
            loadingView.trailingAnchor.constraint(equalTo: loadingView.containerView.trailingAnchor, constant: 0).isActive = true
            
            loadingView.loadingAnimationView.play()
            
            UIView.animate(withDuration: animated ? 0.2 : 0, delay: 0.0, options: .curveEaseOut, animations: {
                loadingView.alpha = 1.0
            }, completion: { _ in
                UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Loading", comment: ""))
            })
        }
    }
    
    public class func hide(animated: Bool = false, _ completion: (() -> Void)? = nil) {
        DispatchQueue.main.async(execute: {
            let loadingView = LoadingView.shared
            loadingView.accessibilityViewIsModal = false
            loadingView.isAccessibilityElement = false
            if loadingView.superview == nil {
                return
            }
            
            UIView.animate(withDuration: animated ? 0.2 : 0, delay: 0.0, options: .curveEaseOut, animations: {
                loadingView.alpha = 0.0
            }, completion: {_ in
                loadingView.loadingAnimationView.pause()
                loadingView.alpha = 1.0
                loadingView.removeFromSuperview()
                
                completion?()
            })
        })
    }
    
    private var containerView: UIView {
        guard let containerView = UIApplication.shared.keyWindow else {
            fatalError("\n`UIApplication.keyWindow` is `nil`. If you're trying to show a spinner from your view controller's `viewDidLoad` method, do that from `viewWillAppear` instead")
        }
        return containerView
    }
    
}
