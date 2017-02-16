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
    
    var username = Variable("")
    var password = Variable("")
    
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
        
        usernameTextField.rx.text.orEmpty.bindTo(username).addDisposableTo(disposeBag)
        passwordTextField.rx.text.orEmpty.bindTo(password).addDisposableTo(disposeBag)
        
        usernameTextField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.passwordTextField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)
        passwordTextField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.onLoginPress()
        }).addDisposableTo(disposeBag)
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
        let service = ServiceFactory.createAuthenticationService()
        
        let signedIn = service.login(username.value, password: password.value).observeOn(MainScheduler.instance)
    
        signInButton.setLoading()
        signedIn.subscribe(onNext: { (signed: Bool) in
            self.signInButton.setSuccess(animationCompletion: { () in
                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                self.present(viewController!, animated: true, completion: nil)
            })
        }, onError: { (error: Error) in
            self.signInButton.setFailure()
            var errorString = ""
            switch(error as! ServiceError) {
                case ServiceError.JSONParsing:
                    errorString = ""
                    break
                case ServiceError.Custom(let code, let description):
                    errorString = description
                    break
                case ServiceError.Other(let error):
                    errorString = error.localizedDescription
                    break
            }
            let errorAlert = UIAlertView(title: "Error", message: errorString, delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "OK")
            errorAlert.show()
        }).addDisposableTo(disposeBag)
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
