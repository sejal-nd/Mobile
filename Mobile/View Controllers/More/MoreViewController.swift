//
//  MoreViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/17/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift

class MoreViewController: UIViewController {
    
    @IBOutlet weak var settingsButton: DisclosureButton!
    @IBOutlet weak var contactUsButton: DisclosureButton!
    @IBOutlet weak var termAndPoliciesButton: DisclosureButton!
    @IBOutlet weak var signOutButton: DisclosureButton!

    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addAccessibility()
        styleViews()
        bindViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func addAccessibility() {
        settingsButton.isAccessibilityElement = true
        settingsButton.accessibilityLabel = NSLocalizedString("Settings", comment: "")
        contactUsButton.isAccessibilityElement = true
        contactUsButton.accessibilityLabel = NSLocalizedString("Contact us", comment: "")
        termAndPoliciesButton.isAccessibilityElement = true
        termAndPoliciesButton.accessibilityLabel = NSLocalizedString("Terms and Policies", comment: "")
        signOutButton.isAccessibilityElement = true
        signOutButton.accessibilityLabel = NSLocalizedString("Sign out", comment: "")
    }
    
    func styleViews() {
        view.backgroundColor = .primaryColor
        signOutButton.setHideCaret(caretHidden: true)
    }
    
    func bindViews() {
        settingsButton.rx.touchUpInside.asDriver()
            .drive(onNext: {
                self.performSegue(withIdentifier: "settingsSegue", sender: self)
            })
            .addDisposableTo(disposeBag)
        contactUsButton.rx.touchUpInside.asDriver()
            .drive(onNext: {
                self.performSegue(withIdentifier: "contactUsSegue", sender: self)
            })
            .addDisposableTo(disposeBag)
        termAndPoliciesButton.rx.touchUpInside.asDriver()
            .drive(onNext: {
                self.performSegue(withIdentifier: "termsPoliciesSegue", sender: self)
            })
            .addDisposableTo(disposeBag)
        signOutButton.rx.touchUpInside.asDriver()
            .drive(onNext: {
                self.onSignOutPress()
            })
            .addDisposableTo(disposeBag)
    }
    
    
    func onSignOutPress() {
        let confirmAlert = UIAlertController(title: NSLocalizedString("Sign Out", comment: ""), message: NSLocalizedString("Are you sure you want to sign out?", comment: ""), preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: logout))
        present(confirmAlert, animated: true, completion: nil)
    }
    
    func logout(action: UIAlertAction) {
        let authService = ServiceFactory.createAuthenticationService()
        authService.logout().subscribe(onNext: { (success) in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.resetNavigation()
        }, onError: { (error) in
            print("Logout Error: \(error)")
        }).addDisposableTo(disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
