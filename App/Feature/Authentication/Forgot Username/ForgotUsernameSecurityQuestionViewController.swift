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

class ForgotUsernameSecurityQuestionViewController: KeyboardAvoidingStickyFooterViewController {
    
    weak var delegate: ForgotUsernameSecurityQuestionViewControllerDelegate?
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerTextField: FloatLabelTextField!
    @IBOutlet weak var submitButton: PrimaryButton!
    
    var viewModel: ForgotUsernameViewModel!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationTitle: String
        if FeatureFlagUtility.shared.bool(forKey: .hasNewRegistration) && Configuration.shared.opco != .bge {
            navigationTitle = Configuration.shared.opco.isPHI ? "Forgot Username" : "Forgot Email"
        } else {
            navigationTitle = "Forgot Username"
        }
        title = navigationTitle
        
        viewModel.securityQuestionAnswerNotEmpty.drive(submitButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.textColor = .deepGray
        instructionLabel.text = NSLocalizedString("Please answer the security question.", comment: "")
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        
        questionLabel.textColor = .deepGray
        questionLabel.font = SystemFont.regular.of(textStyle: .subheadline)
        questionLabel.text = viewModel.getSecurityQuestion()
        
        answerTextField.placeholder = NSLocalizedString("Your Answer*", comment: "")
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
    
    @IBAction func onSubmitPress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.submitSecurityQuestionAnswer(onSuccess: { [weak self] unmaskedUsername in
            LoadingView.hide()
            guard let self = self, let rootNavVc = self.navigationController?.presentingViewController as? LargeTitleNavigationController else { return }
            for vc in rootNavVc.viewControllers {
                guard let dest = vc as? LoginViewController else {
                    continue
                }
                self.delegate = dest

                FirebaseUtility.logEventV2(.forgotUsername(parameters: [.answer_question_complete]))

                self.delegate?.forgotUsernameSecurityQuestionViewController(self, didUnmaskUsername: unmaskedUsername)
                self.dismissModal()
                break
            }
        }, onAnswerNoMatch: { [weak self] inlineErrorMessage in
            LoadingView.hide()
            self?.answerTextField.setError(inlineErrorMessage)
            self?.accessibilityErrorLabel()
        }, onError: { [weak self] errorMessage in
            LoadingView.hide()

            FirebaseUtility.logEventV2(.forgotUsername(parameters: [.network_submit_error]))

            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
}
