//
//  ForgotPasswordViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit

protocol ForgotPasswordViewControllerDelegate: class {
    func forgotPasswordViewControllerDidSubmit(_ viewController: UIViewController)
}

class ForgotPasswordViewController: KeyboardAvoidingStickyFooterViewController {
    
    weak var delegate: ForgotPasswordViewControllerDelegate?
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var usernameTextField: FloatLabelTextField!
    @IBOutlet weak var submitButton: PrimaryButton!
    
    let viewModel = ForgotPasswordViewModel()
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCloseButton()

        title = NSLocalizedString("Forgot Password", comment: "")

        viewModel.submitButtonEnabled.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.text = viewModel.getInstructionLabelText()
        instructionLabel.font = .headline
        instructionLabel.textColor = .neutralDark
        instructionLabel.setLineHeight(lineHeight: 24)
        var placeholderText = "Username / Email Address"
        if Configuration.shared.opco != .bge {
            placeholderText = "Email"
        } else {
            placeholderText = Configuration.shared.opco.isPHI ? "Username (Email Address)" : "Username / Email Address"
        }
        
        usernameTextField.placeholder = NSLocalizedString(placeholderText, comment: "")
        usernameTextField.textField.autocorrectionType = .no
        usernameTextField.textField.returnKeyType = .done
        usernameTextField.textField.textContentType = .username
        
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
    }
    
    private func accessibilityErrorLabel() {
        let message = usernameTextField.getError()
        
        if message.isEmpty {
            submitButton.accessibilityLabel = NSLocalizedString("Submit", comment: "")
        } else {
            submitButton.accessibilityLabel = String(format: NSLocalizedString("%@ Submit", comment: ""), message)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func onSubmitPress() {
        view.endEditing(true)
        // For PHI opcos, user cannot request for forgot password flow with a username, hence restricting the flow to email only
        if !viewModel.username.value.isValidEmail() && Configuration.shared.opco.isPHI {
            usernameTextField.setError(NSLocalizedString("Username (Email Address) is invalid.", comment: ""))
            return
        }
        LoadingView.show()
        viewModel.submitForgotPassword(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }

            FirebaseUtility.logEvent(.forgotPassword(parameters: [.complete]))

            self.delegate?.forgotPasswordViewControllerDidSubmit(self)
            self.dismissModal()
        }, onProfileNotFound: { [weak self] error in
            LoadingView.hide()
            guard let self = self else { return }
            let errorMessage = Configuration.shared.opco.isPHI ? "Username (Email Address) is invalid." : error

            self.usernameTextField.setError(NSLocalizedString(errorMessage, comment: ""))
            self.accessibilityErrorLabel()
        }, onError: { [weak self] errorMessage in
            LoadingView.hide()
            guard let self = self else { return }

            FirebaseUtility.logEvent(.forgotPassword(parameters: [.network_submit_error]))

            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
        
}
