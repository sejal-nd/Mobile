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
    
    public class var sharedInstance: LoadingView {
        struct Singleton {
            static let instance = LoadingView(frame: CGRect.zero)
        }
        return Singleton.instance
    }
    
    private lazy var animationContainer = UIView()
    private var loadingAnimationView = LOTAnimationView(name: "full_screen_loading")!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        animationContainer.frame.size = UIApplication.shared.keyWindow!.bounds.size
        animationContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        loadingAnimationView.frame.size = CGSize(width: 72, height: 72)
        loadingAnimationView.loopAnimation = true
        
        animationContainer.addSubview(loadingAnimationView)
        addSubview(animationContainer)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Not coder compliant")
    }
    
    public class func show(animated: Bool = true) {
        let loadingView = LoadingView.sharedInstance
        
        loadingView.updateFrame()
        loadingView.isAccessibilityElement = true
        loadingView.accessibilityLabel = "Loading"
        loadingView.accessibilityViewIsModal = true
        if loadingView.superview == nil {
            loadingView.alpha = 0.0
            
            guard let containerView = containerView() else {
                fatalError("\n`UIApplication.keyWindow` is `nil`. If you're trying to show a spinner from your view controller's `viewDidLoad` method, do that from `viewWillAppear` instead")
            }
            
            containerView.addSubview(loadingView)
            
            loadingView.loadingAnimationView.play()
            
            UIView.animate(withDuration: animated ? 0.2 : 0, delay: 0.0, options: .curveEaseOut, animations: {
                loadingView.alpha = 1.0
            }, completion: { _ in
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Loading", comment: ""))
            })
        }
    }
    
    public class func hide(animated: Bool = false, _ completion: (() -> Void)? = nil) {
        
        let loadingView = LoadingView.sharedInstance
        loadingView.accessibilityViewIsModal = false
        loadingView.isAccessibilityElement = false
        DispatchQueue.main.async(execute: {
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
    
    // Observe the view frame and update the subviews layout
    public override var frame: CGRect {
        didSet {
            if frame == CGRect.zero {
                return
            }
            animationContainer.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
            loadingAnimationView.center = CGPoint(x: animationContainer.bounds.width / 2, y: animationContainer.bounds.height / 2)
        }
    }
    
    private static func containerView() -> UIView? {
        return UIApplication.shared.keyWindow
    }
    
    public func updateFrame() {
        if let containerView = LoadingView.containerView() {
            LoadingView.sharedInstance.frame = containerView.bounds
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        updateFrame()
    }
    
}
