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
    
    @IBOutlet weak var reportAnOutageButton: DisclosureButton!
    @IBOutlet weak var checkMyOutageStatusButton: DisclosureButton!
    @IBOutlet weak var viewOutageMapButton: DisclosureButton!
    
    
    @IBOutlet weak var contactUsButton: DisclosureButton!
    @IBOutlet weak var TermPoliciesButton: DisclosureButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let animationView = LOTAnimationView(name: "UU_OTP_animation") {
            animationView.frame = CGRect(x: 0, y: 0, width: 230, height: 180)
            animationView.contentMode = .scaleAspectFill
            animationView.loopAnimation = true
            
            // put the animation at the center top screen
            var center = lottieView.center
            center.x = self.view.center.x;
            animationView.center = center;
            
            lottieView.addSubview(animationView)
            
            animationView.play()
        }
        
        
        // For release one, only contact us and term policies button will be shown,
        // so, hide the other 3 buttons
        reportAnOutageButton.isHidden = true
        checkMyOutageStatusButton.isHidden = true
        viewOutageMapButton.isHidden = true
        
        view.backgroundColor = .primaryColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.view.backgroundColor = .primaryColor
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        navigationController?.setNavigationBarHidden(false, animated: false)
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
}
