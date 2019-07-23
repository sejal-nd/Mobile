//
//  RegistrationBGEAccountNumberViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 6/1/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Toast_Swift

class RegistrationBGEAccountNumberViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var questionMarkButton: UIButton!

    var viewModel: RegistrationViewModel!
    var nextButton = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Register", comment: "")
        
        setupNavigationButtons()
        
        populateHelperLabels()
        
        prepareTextFieldsForInput()
        
    }

    /// Helpers
    func setupNavigationButtons() {
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        viewModel.accountNumberHasTenDigits.drive(nextButton.rx.isEnabled).disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = nextButton
    }

    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("The information entered is associated with multiple accounts. Please enter the account number for which you would like to proceed.", comment: "")
        instructionLabel.font = SystemFont.regular.of(textStyle: .headline)
    }
    
    func prepareTextFieldsForInput() {
        accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
        accountNumberTextField.textField.autocorrectionType = .no
        accountNumberTextField.setKeyboardType(.numberPad, doneActionTarget: self, doneActionSelector: #selector(onAccountNumberKeyboardDonePress))
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).disposed(by: disposeBag)
		questionMarkButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
		
		accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).asDriver()
			.withLatestFrom(Driver.zip(viewModel.accountNumber.asDriver(), viewModel.accountNumberHasTenDigits))
			.drive(onNext: { [weak self] accountNumber, hasTenDigits in
				guard let self = self else { return }
				if !accountNumber.isEmpty && !hasTenDigits {
					self.accountNumberTextField.setError(NSLocalizedString("Account number must be 10 digits long", comment: ""))
				}
				self.accessibilityErrorLabel()
			})
			.disposed(by: disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).asDriver().drive(onNext: { [weak self] in
            self?.accountNumberTextField.setError(nil)
            self?.accessibilityErrorLabel()
        }).disposed(by: disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        let message = accountNumberTextField.getError()
        
        if message.isEmpty {
            nextButton.accessibilityLabel = NSLocalizedString("Next", comment: "")
        } else {
            nextButton.accessibilityLabel = String(format: NSLocalizedString("%@ Next", comment: ""), message)
        }
    }
    
	@objc func onAccountNumberKeyboardDonePress() {
		viewModel.accountNumberHasTenDigits
            .asObservable()
            .take(1)
            .asDriver(onErrorDriveWith: .empty())
			.drive(onNext: { [weak self] enabled in
				if enabled {
					self?.onNextPress()
				}
			}).disposed(by: disposeBag)
	}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    @objc func onNextPress() {
        guard nextButton.isEnabled else { return }
        
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.validateAccount(onSuccess: {
            LoadingView.hide()
            GoogleAnalytics.log(event: .registerAccountSetup)
            self.performSegue(withIdentifier: "createCredentialsSegue", sender: self)
            
        }, onMultipleAccounts:  { // should never happen
            LoadingView.hide()
            
        }, onError: { (title, message) in
            LoadingView.hide()
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let vc = segue.destination as? RegistrationCreateCredentialsViewController {
            vc.viewModel = viewModel
        }
    }
    
    @IBAction func onAccountNumberTooltipPress() {
        let description: String
        switch Environment.shared.opco {
        case .bge:
            description = NSLocalizedString("Your Customer Account Number may be found in the top right portion on your bill in the bill summary section. Please enter 10-digits including leading zeros.", comment: "")
        case .comEd:
            description = NSLocalizedString("Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes.", comment: "")
        case .peco:
            description = NSLocalizedString("Your Account Number is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appears after your name on your bill, please enter any account from your list of individual accounts.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Find Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: description)
        
        self.navigationController?.present(infoModal, animated: true, completion: nil)
    }
    
}

extension RegistrationBGEAccountNumberViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField ==  accountNumberTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 10
        }
        
        return true
    }
    
}
