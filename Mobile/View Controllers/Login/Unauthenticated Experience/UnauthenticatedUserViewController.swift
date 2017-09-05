//
//  UnauthenticatedUserViewController.swift
//  Mobile
//
//  Created by Junze Liu on 7/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import Foundation
import Lottie

class UnauthenticatedUserViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lottieView: UIView!
    @IBOutlet weak var textLabel: UILabel!

    @IBOutlet weak var loginRegisterButton: UIButton!
    
    @IBOutlet weak var reportAnOutageButton: DisclosureButton!
    @IBOutlet weak var checkMyOutageStatusButton: DisclosureButton!
    @IBOutlet weak var viewOutageMapButton: DisclosureButton!
    
    @IBOutlet weak var contactUsButton: DisclosureButton!
    @IBOutlet weak var TermPoliciesButton: DisclosureButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .primaryColor
        
        scrollView.indicatorStyle = .white
        loginRegisterButton.titleLabel!.font =  OpenSans.bold.of(textStyle: .title1)
        textLabel.font =  OpenSans.regular.of(textStyle: .subheadline)
        
        var lottieName = ""
        switch Environment.sharedInstance.opco {
        case .bge:
            lottieName = "uu_otp_bge"
            break
        case .comEd:
            lottieName = "uu_otp_comed"
            break
        case .peco:
            lottieName = "uu_otp_peco"
            break
        }
        
        let animationView = LOTAnimationView(name: lottieName)
        animationView.frame = CGRect(x: 0, y: 0, width: 230, height: 180)
        animationView.contentMode = .scaleAspectFill
        animationView.loopAnimation = true
        
        // put the animation at the center top screen
        var center = lottieView.center
        center.x = self.view.center.x;
        animationView.center = center;
        
        lottieView.addSubview(animationView)
        animationView.play()
        
        accessibilitySetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = true
        
        setNeedsStatusBarAppearanceUpdate()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func accessibilitySetup() {
        lottieView.isAccessibilityElement = true
        lottieView.accessibilityLabel = NSLocalizedString("Animation showing home screen payment", comment: "")
        
        textLabel.isAccessibilityElement = true
        textLabel.accessibilityLabel = textLabel.text
        
        contactUsButton.isAccessibilityElement = true
        contactUsButton.accessibilityLabel = NSLocalizedString("Contact us", comment: "")
        TermPoliciesButton.isAccessibilityElement = true
        TermPoliciesButton.accessibilityLabel = NSLocalizedString("Policies and Terms", comment: "")
    }
    
    @IBAction func onLoginRegisterPress(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        dLog()
    }
}
