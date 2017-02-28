//
//  ChangePasswordViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 2/27/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var passwordRequirementsView: UIView!
    @IBOutlet weak var currentPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var newPasswordTextField: FloatLabelTextField!
    @IBOutlet weak var confirmPasswordTextField: FloatLabelTextField!
    
    @IBOutlet weak var passwordRequirementsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var confirmPasswordHeightConstraint: NSLayoutConstraint!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDonePress))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)

        //passwordRequirementsView.translatesAutoresizingMaskIntoConstraints = true
        passwordRequirementsViewHeightConstraint.constant = 0
        confirmPasswordHeightConstraint.constant = 0
        
        currentPasswordTextField.textField.placeholder = "Current Password"
        currentPasswordTextField.textField.isSecureTextEntry = true
        currentPasswordTextField.textField.returnKeyType = .next
        
        newPasswordTextField.textField.placeholder = "New Password"
        newPasswordTextField.textField.isSecureTextEntry = true
        newPasswordTextField.textField.returnKeyType = .next
        
        confirmPasswordTextField.textField.placeholder = "Confirm Password"
        confirmPasswordTextField.textField.isSecureTextEntry = true
        confirmPasswordTextField.textField.returnKeyType = .done
        confirmPasswordTextField.setEnabled(false)
        
        newPasswordTextField.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { _ in
            self.view.layoutIfNeeded()
            self.scrollView.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, animations: {
                self.passwordRequirementsViewHeightConstraint.constant = 254
                self.confirmPasswordHeightConstraint.constant = 30
                self.view.layoutIfNeeded()
                self.scrollView.layoutIfNeeded()
            })
        }).addDisposableTo(disposeBag)
        
        newPasswordTextField.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { _ in
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, animations: {
                self.passwordRequirementsViewHeightConstraint.constant = 0
                self.confirmPasswordHeightConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
        }).addDisposableTo(disposeBag)
        
        currentPasswordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.newPasswordTextField.textField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)
        newPasswordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.confirmPasswordTextField.textField.becomeFirstResponder()
        }).addDisposableTo(disposeBag)
        confirmPasswordTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.onDonePress()
        }).addDisposableTo(disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onDonePress() {
        NSLog("Done")
    }
    
    // MARK: Scroll View
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        var tabBarHeight: CGFloat = 0
        if let tabController = tabBarController {
            tabBarHeight = tabController.tabBar.frame.size.height
        }
        
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height - tabBarHeight, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
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
