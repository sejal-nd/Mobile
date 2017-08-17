//
//  ForgotPasswordViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

protocol ForgotPasswordViewControllerDelegate: class {
    func forgotPasswordViewControllerDidSubmit(_ forgotPasswordViewController: ForgotPasswordViewController)
}

class ForgotPasswordViewController: UIViewController {
    
    weak var delegate: ForgotPasswordViewControllerDelegate?
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var usernameTextField: FloatLabelTextField!
    @IBOutlet weak var forgotUsernameButton: UIButton!
    
    let viewModel = ForgotPasswordViewModel(authService: ServiceFactory.createAuthenticationService())
    
    let disposeBag = DisposeBag()
    
    var submitButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Forgot Password", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        viewModel.submitButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.text = viewModel.getInstructionLabelText()
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        usernameTextField.textField.placeholder = NSLocalizedString("Username / Email Address", comment: "")
        usernameTextField.textField.autocorrectionType = .no
        usernameTextField.textField.returnKeyType = .done
        
        usernameTextField.textField.rx.text.orEmpty.bind(to: viewModel.username).disposed(by: disposeBag)
        usernameTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .withLatestFrom(viewModel.submitButtonEnabled)
            .filter { $0 }
            .drive(onNext: { [weak self] _ in
                self?.onSubmitPress()
            })
            .disposed(by: disposeBag)
        
        usernameTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.usernameTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        forgotUsernameButton.setTitle(NSLocalizedString("Forgot Username?", comment: ""), for: .normal)
        forgotUsernameButton.setTitleColor(.actionBlue, for: .normal)
    }
    
    private func accessibilityErrorLabel() {
        let message = usernameTextField.getError()
        
        if message.isEmpty {
            submitButton.accessibilityLabel = NSLocalizedString("Submit", comment: "")
        } else {
            submitButton.accessibilityLabel = NSLocalizedString(message + " Submit", comment: "")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.view.backgroundColor = .primaryColor // This prevents a black color from appearing during the transition between `isTranslucent = false` and `isTranslucent = true`
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.isTranslucent = false
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
                
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func onCancelPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.submitForgotPassword(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let `self` = self else { return }
            self.delegate?.forgotPasswordViewControllerDidSubmit(self)
            self.navigationController?.popViewController(animated: true)
        }, onProfileNotFound: { [weak self] error in
            LoadingView.hide()
            guard let `self` = self else { return }
            self.usernameTextField.setError(NSLocalizedString(error, comment: ""))
            self.accessibilityErrorLabel()
            
        }, onError: { [weak self] errorMessage in
            LoadingView.hide()
            guard let `self` = self else { return }
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    @IBAction func onForgotUsernamePress() {
        for vc in (navigationController?.viewControllers)! {
            guard let loginVC = vc as? LoginViewController else {
                continue
            }
            loginVC.onForgotUsernamePress()
            break
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    deinit {
        dLog()
    }

}
