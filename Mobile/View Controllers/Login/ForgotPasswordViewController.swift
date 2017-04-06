//
//  ForgotPasswordViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/6/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import RxSwift

protocol ForgotPasswordViewControllerDelegate: class {
    func forgotPasswordViewControllerDidSubmit(_ forgotPasswordViewController: ForgotPasswordViewController)
}

class ForgotPasswordViewController: UIViewController {
    
    weak var delegate: ForgotPasswordViewControllerDelegate?
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var usernameTextField: FloatLabelTextField!
    
    let viewModel = ForgotPasswordViewModel()
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Forgot Password", comment: "")
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        let submitButton = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .done, target: self, action: #selector(onSubmitPress))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = submitButton
        viewModel.submitButtonEnabled().bindTo(submitButton.rx.isEnabled).addDisposableTo(disposeBag)
        
        instructionLabel.text = viewModel.getInstructionLabelText()
        
        usernameTextField.textField.placeholder = NSLocalizedString("Username / Email Address", comment: "")
        usernameTextField.textField.autocorrectionType = .no
        usernameTextField.textField.returnKeyType = .done
        
        usernameTextField.textField.rx.text.orEmpty.bindTo(viewModel.username).addDisposableTo(disposeBag)
        usernameTextField.textField.rx.controlEvent(.editingDidEndOnExit).subscribe(onNext: { _ in
            self.viewModel.submitButtonEnabled().single().subscribe(onNext: { enabled in
                if enabled {
                    self.onSubmitPress()
                }
            }).addDisposableTo(self.disposeBag)
        }).addDisposableTo(disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.tintColor = .mediumPersianBlue
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.darkJungleGreen,
            NSFontAttributeName: UIFont(name: "OpenSans-Bold", size: 18)!
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        setNeedsStatusBarAppearanceUpdate()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func onCancelPress() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onSubmitPress() {
        self.view.endEditing(true)
        
        viewModel.submitChangePassword(onSuccess: { 
            self.delegate?.forgotPasswordViewControllerDidSubmit(self)
            _ = self.navigationController?.popViewController(animated: true)
        }, onProfileNotFound: {
            self.usernameTextField.setError(NSLocalizedString("Incorrect username/email address", comment: ""))
        }, onError: { errorMessage in
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }


}
