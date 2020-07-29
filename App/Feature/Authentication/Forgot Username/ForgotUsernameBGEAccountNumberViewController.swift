//
//  ForgotUsernameBGEAccountNumberViewController.swift
//  Mobile
//
//  Created by Marc Shilling on 4/7/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ForgotUsernameBGEAccountNumberViewController: KeyboardAvoidingStickyFooterViewController {
    
    let viewModel = ForgotUsernameViewModel()

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var accountNumberTooltipButton: UIButton!
    
    @IBOutlet weak var continueButton: PrimaryButton!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Forgot Username", comment: "")
        
        viewModel.accountNumberHasValidLength.drive(continueButton.rx.isEnabled).disposed(by: disposeBag)
        
        instructionLabel.textColor = .deepGray
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
        instructionLabel.text = NSLocalizedString("The information entered is associated with multiple accounts. Please enter the account number you would like to proceed with.", comment: "")

        accountNumberTextField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.autocorrectionType = .no
        accountNumberTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onAccountNumberKeyboardDonePress))
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
        
        accountNumberTextField?.textField.rx.controlEvent(.editingDidEnd).asDriver()
            .withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberHasValidLength))
            .drive(onNext: { [weak self] accountNumber, hasTenDigits in
                guard let self = self else { return }
                if !accountNumber.isEmpty {
                    if !hasTenDigits {
                        self.accountNumberTextField.setError(NSLocalizedString("Account number must be 10 digits long.", comment: ""))
                    } else {
                        self.accountNumberTextField.setError(nil)
                    }
                }
                self.accessibilityErrorLabel()
            })
            .disposed(by: disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] _ in
            self?.accountNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
        
        accountNumberTooltipButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
    }
    
    private func accessibilityErrorLabel() {
        let message = accountNumberTextField.getError()
        
        if message.isEmpty {
            continueButton.accessibilityLabel = NSLocalizedString("Continue", comment: "")
        } else {
            continueButton.accessibilityLabel = String(format: NSLocalizedString("%@ Continue", comment: ""), message)
        }
    }
    
    @IBAction func onContinuePress() {
        view.endEditing(true)
        
        LoadingView.show()
        viewModel.validateAccount(onSuccess: {
            LoadingView.hide()
            self.performSegue(withIdentifier: "forgotUsernameResultSegue", sender: self)
        }, onNeedAccountNumber: { // Should not happen here
            LoadingView.hide()
        }, onError: { title, message in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    @objc func onAccountNumberKeyboardDonePress() {
        viewModel.accountNumberHasValidLength.asObservable().take(1).asDriver(onErrorDriveWith: .empty()).drive(onNext: { [weak self] valid in
            if valid {
                self?.onContinuePress()
            } else {
                self?.view.endEditing(true)
            }
        }).disposed(by: disposeBag)
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        let infoModal = InfoModalViewController(title: NSLocalizedString("Find Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: NSLocalizedString("Your Customer Account Number may be found in the top right portion on your bill in the bill summary section. Please enter 10-digits including leading zeros.", comment: ""))
        self.navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ForgotUsernameResultViewController {
            vc.viewModel = viewModel
        }
    }
    
}

extension ForgotUsernameBGEAccountNumberViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let characterSet = CharacterSet(charactersIn: string)
        return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 10
    }
    
}
