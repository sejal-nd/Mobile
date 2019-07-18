//
//  ForgotUsernameSecurityQuestionViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol ForgotUsernameSecurityQuestionViewControllerDelegate: class {
    func forgotUsernameSecurityQuestionViewController(_ forgotUsernameSecurityQuestionViewController: ForgotUsernameSecurityQuestionViewController, didUnmaskUsername username: String)
}

class ForgotUsernameSecurityQuestionViewController: UIViewController {
    
    weak var delegate: ForgotUsernameSecurityQuestionViewControllerDelegate?
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerTextField: FloatLabelTextField!
    
    var viewModel: ForgotUsernameViewModel!
    
    let disposeBag = DisposeBag()
    var submitButton = UIBarButtonItem()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Forgot Username", comment: "")
        
        submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.rightBarButtonItem = submitButton
        viewModel.securityQuestionAnswerNotEmpty.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please answer the security question.", comment: "")
        instructionLabel.font = SystemFont.bold.of(textStyle: .headline)
        
        questionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        questionLabel.text = viewModel.getSecurityQuestion()
        
        answerTextField.textField.placeholder = NSLocalizedString("Your Answer*", comment: "")
        answerTextField.textField.autocorrectionType = .no
        answerTextField.textField.returnKeyType = .done
        answerTextField.textField.rx.text.orEmpty.bind(to: viewModel.securityQuestionAnswer).disposed(by: disposeBag)
        
        answerTextField.textField.rx.controlEvent(.editingDidEndOnExit).asDriver()
            .withLatestFrom(viewModel.securityQuestionAnswerNotEmpty)
            .drive(onNext: { [weak self] in
                if $0 {
                    self?.onSubmitPress()
                } else {
                    self?.view.endEditing(true)
                }
            })
            .disposed(by: disposeBag)
        
        answerTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.answerTextField.setError(nil)
            self?.accessibilityErrorLabel()
            
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        let message = answerTextField.getError()
        if message.isEmpty {
            submitButton.accessibilityLabel = NSLocalizedString("Submit", comment: "")
        } else {
            submitButton.accessibilityLabel = String(format: NSLocalizedString("%@ Submit", comment: ""), message)
        }
    }
    
    @objc func onSubmitPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.submitSecurityQuestionAnswer(onSuccess: { [weak self] unmaskedUsername in
            LoadingView.hide()
            guard let self = self, let viewControllers = self.navigationController?.viewControllers else { return }
            for vc in viewControllers {
                guard let dest = vc as? LoginViewController else {
                    continue
                }
                self.delegate = dest
                self.delegate?.forgotUsernameSecurityQuestionViewController(self, didUnmaskUsername: unmaskedUsername)
                self.navigationController?.popToViewController(dest, animated: true)
                break
            }
        }, onAnswerNoMatch: { [weak self] inlineErrorMessage in
            LoadingView.hide()
            self?.answerTextField.setError(inlineErrorMessage)
            self?.accessibilityErrorLabel()
            
        }, onError: { [weak self] errorMessage in
            LoadingView.hide()
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
        })
    }

}
