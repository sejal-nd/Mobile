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

// PECO test logins:
// User_0005084051@test.com / Password1
// kat@test.com / Password1

// BGE:
// multprem02 / Password1

class LoginViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var usernameTextField: FloatLabelTextField!
    @IBOutlet weak var passwordTextField: FloatLabelTextField!
    @IBOutlet weak var signInButton: PrimaryButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    var viewModel = LoginViewModel(authService: ServiceFactory.createAuthenticationService(), fingerprintService: ServiceFactory.createFingerprintService())
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = .white

        logoView.backgroundColor = .primaryColor
        
        usernameTextField.textField.placeholder = "Username / Email Address"
        usernameTextField.textField.autocorrectionType = .no
        usernameTextField.textField.returnKeyType = .next
        
        passwordTextField.textField.placeholder = "Password"
        passwordTextField.textField.isSecureTextEntry = true
        passwordTextField.textField.returnKeyType = .done
    
        usernameTextField.textField.rx.text.orEmpty.bindTo(viewModel.username).addDisposableTo(disposeBag)
        passwordTextField.textField.rx.text.orEmpty.bindTo(viewModel.password).addDisposableTo(disposeBag)
        
        usernameTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.passwordTextField.textField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)
        passwordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.onLoginPress()
        }).addDisposableTo(disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.attemptLoginWithTouchID(onLoad: {
            self.signInButton.setLoading()
        }, onSuccess: {
            self.signInButton.setSuccess(animationCompletion: { () in
                self.launchMainApp()
            })
        }, onError: { (errorMessage) in
            self.showErrorAlertWithMessage(errorMessage)
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onLoginPress() {
        view.endEditing(true)
        view.isUserInteractionEnabled = false
        
        signInButton.setLoading()
        viewModel.performLogin(onSuccess: {
            self.signInButton.setSuccess(animationCompletion: { () in
                self.view.isUserInteractionEnabled = true
                self.viewModel.storeUsername() // We store the logged in username regardless of Touch ID
                if self.viewModel.isDeviceTouchIDCompatible() {
                    if UserDefaults.standard.object(forKey: UserDefaultKeys.PromptedForTouchID) == nil {
                        let touchIDAlert = UIAlertController(title: "Enable Touch ID", message: "Would you like to use Touch ID to sign in from now on?", preferredStyle: .alert)
                        touchIDAlert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action) in
                            self.launchMainApp()
                        }))
                        touchIDAlert.addAction(UIAlertAction(title: "Enable", style: .default, handler: { (action) in
                            self.viewModel.storePasswordInTouchIDKeychain()
                            self.launchMainApp()
                        }))
                        self.present(touchIDAlert, animated: true, completion: nil)
                        UserDefaults.standard.set(true, forKey: UserDefaultKeys.PromptedForTouchID)
                    } else if self.viewModel.didLoginWithDifferentAccountThanStoredInKeychain() {
                        let differentAccountAlert = UIAlertController(title: "Change Touch ID", message: "This is different account than the one linked to your Touch ID. Would you like to use Touch ID for this account from now on?", preferredStyle: .alert)
                        differentAccountAlert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action) in
                            self.launchMainApp()
                        }))
                        differentAccountAlert.addAction(UIAlertAction(title: "Change", style: .default, handler: { (action) in
                            self.viewModel.storePasswordInTouchIDKeychain()
                            self.launchMainApp()
                        }))
                        self.present(differentAccountAlert, animated: true, completion: nil)
                    } else {
                        self.launchMainApp()
                    }
                } else {
                    self.launchMainApp()
                }

            })
        }, onError: { (errorMessage) in
            self.view.isUserInteractionEnabled = true
            self.showErrorAlertWithMessage(errorMessage)
        })
    }
    
    func launchMainApp() {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        self.present(viewController!, animated: true, completion: nil)
    }
    
    func showErrorAlertWithMessage(_ errorMessage: String) {
        signInButton.setFailure()
        
        let errorAlert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(errorAlert, animated: true, completion: nil)
    }
    
    // MARK: Scroll View
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
        scrollView.scrollRectToVisible(forgotPasswordButton.frame, animated: true)
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
