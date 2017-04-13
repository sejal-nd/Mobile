//
//  SecurityQuestionViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/11/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift
import MBProgressHUD

protocol SecurityQuestionViewControllerDelegate: class {
    func securityQuestionViewController(_ securityQuestionViewController: SecurityQuestionViewController, didUnmaskUsername username: String)
}

class SecurityQuestionViewController: UIViewController {
    
    weak var delegate: SecurityQuestionViewControllerDelegate?
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerTextField: FloatLabelTextField!
    
    let viewModel = ForgotUsernameViewModel(authService: MockAuthenticationService())
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Forgot Username", comment: "")
        
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.rightBarButtonItem = submitButton
        viewModel.securityQuestionAnswerNotEmpty().bindTo(submitButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        instructionLabel.textColor = .darkJungleGreen
        instructionLabel.text = NSLocalizedString("Please answer the security question.", comment: "")
        
        questionLabel.text = viewModel.getSecurityQuestion()
        
        answerTextField.textField.placeholder = NSLocalizedString("Your Answer*", comment: "")
        answerTextField.textField.autocorrectionType = .no
        answerTextField.textField.returnKeyType = .done
        answerTextField.textField.rx.text.orEmpty.bindTo(viewModel.securityQuestionAnswer).addDisposableTo(disposeBag)
        answerTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.viewModel.securityQuestionAnswerNotEmpty().single().subscribe(onNext: { notEmpty in
                if notEmpty {
                    self.onSubmitPress()
                } else {
                    self.view.endEditing(true)
                }
            }).addDisposableTo(self.disposeBag)
        }).addDisposableTo(disposeBag)
        answerTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.answerTextField.setError(nil)
        }).addDisposableTo(disposeBag)
    }
    
    func onSubmitPress() {
        view.endEditing(true)
        
        let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
        hud.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
        hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        hud.contentColor = .white
        
        viewModel.submitSecurityQuestionAnswer(onSuccess: { unmaskedUsername in
            hud.hide(animated: true)
            for vc in (self.navigationController?.viewControllers)! {
                if vc.isKind(of: LoginViewController.self) {
                    if let vcDelegate = vc as? SecurityQuestionViewControllerDelegate {
                        self.delegate = vcDelegate
                        self.delegate?.securityQuestionViewController(self, didUnmaskUsername: unmaskedUsername)
                        self.navigationController?.popToViewController(vc, animated: true)
                    }
                }
            }
        }, onAnswerNoMatch: { inlineErrorMessage in
            hud.hide(animated: true)
            self.answerTextField.setError(inlineErrorMessage)
        }, onError: { errorMessage in
            hud.hide(animated: true)
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }

}
