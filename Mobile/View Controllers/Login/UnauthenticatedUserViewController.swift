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
    
    @IBOutlet weak var lottieView: UIView!
    @IBOutlet weak var textLabel: UILabel!

    @IBOutlet weak var LoginRegisterButton: UIButton!
    
    @IBOutlet weak var reportAnOutageButton: DisclosureButton!
    @IBOutlet weak var checkMyOutageStatusButton: DisclosureButton!
    @IBOutlet weak var viewOutageMapButton: DisclosureButton!
    
    
    @IBOutlet weak var contactUsButton: DisclosureButton!
    @IBOutlet weak var TermPoliciesButton: DisclosureButton!
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let animationView = LOTAnimationView(name: "uu_otp")
        animationView.frame = CGRect(x: 0, y: 0, width: 230, height: 180)
        animationView.contentMode = .scaleAspectFill
        animationView.loopAnimation = true
        
        // put the animation at the center top screen
        var center = lottieView.center
        center.x = self.view.center.x;
        animationView.center = center;
        
        lottieView.addSubview(animationView)
        
        animationView.play()
        
        // For release one, only contact us and term policies button will be shown,
        // so, hide the other 3 buttons
        reportAnOutageButton.isHidden = true
        checkMyOutageStatusButton.isHidden = true
        viewOutageMapButton.isHidden = true
        
        view.backgroundColor = .primaryColor
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
        
        LoginRegisterButton.titleLabel!.font =  OpenSans.bold.of(textStyle: .title1)
        textLabel.font =  OpenSans.regular.of(textStyle: .subheadline)
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
    
    @IBAction func onContactUsPress(_ sender: UIButton) {
        self.performSegue(withIdentifier: "ContactUsSegue", sender: self)
    }
    
    @IBAction func onTermPoliciesPress(_ sender: UIButton) {
        self.performSegue(withIdentifier: "TermPoliciesSegue", sender: self)
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
