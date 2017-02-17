//
//  LoginViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/13/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

// Test login: "User_0005084051@test.com"
// Test pass: "Password1"

class LoginViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var signInButton: LoginButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    var viewModel: LoginViewModel?
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = .white

        logoView.backgroundColor = .primaryColor
        
        viewModel = LoginViewModel(authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService())
        
        usernameTextField.rx.text.orEmpty.bindTo(viewModel!.username).addDisposableTo(disposeBag)
        passwordTextField.rx.text.orEmpty.bindTo(viewModel!.password).addDisposableTo(disposeBag)
        
        usernameTextField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.passwordTextField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)
        passwordTextField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.onLoginPress()
        }).addDisposableTo(disposeBag)
        
        viewModel!.attemptLoginWithTouchID { 
            self.launchMainApp()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onLoginPress() {
        signInButton.setLoading()
        
        viewModel!.performLogin(onSuccess: {
            if UserDefaults.standard.object(forKey: UserDefaultKeys.HavePromptedForTouchID) == nil && self.viewModel!.isDeviceTouchIDEnabled() {
                let touchIDAlert = UIAlertController(title: "Enable Touch ID", message: "Would you like to sign in with Touch ID in the future?", preferredStyle: .alert)
                touchIDAlert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
                touchIDAlert.addAction(UIAlertAction(title: "Enable", style: .default, handler: { (action) in
                    self.viewModel!.enableTouchID()
                    self.launchMainApp()
                }))
                self.present(touchIDAlert, animated: true, completion: nil)
                UserDefaults.standard.set(true, forKey: UserDefaultKeys.HavePromptedForTouchID)
            } else {
                self.signInButton.setSuccess(animationCompletion: { () in
                    self.launchMainApp()
                })
            }
        }, onError: { (errorMessage) in
            self.signInButton.setFailure()
            let errorAlert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
        })
    }
    
    func launchMainApp() {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        self.present(viewController!, animated: true, completion: nil)
    }
    
    // MARK: Scroll View
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
        scrollView.scrollRectToVisible(signInButton.frame, animated: true)
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
