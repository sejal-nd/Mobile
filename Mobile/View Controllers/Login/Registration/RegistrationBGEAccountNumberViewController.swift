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
import ToastSwiftFramework

class RegistrationBGEAccountNumberViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var questionMarkButton: UIButton!

    var viewModel: RegistrationViewModel!// = RegistrationViewModel(registrationService: ServiceFactory.createRegistrationService())
    var nextButton = UIBarButtonItem()

    /////////////////////////////////////////////////////////////////////////////////////////////////
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
        viewModel.accountNumberHasTenDigits().bind(to: nextButton.rx.isEnabled).addDisposableTo(disposeBag)
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
        accountNumberTextField.textField.returnKeyType = .next
        accountNumberTextField.textField.delegate = self
        accountNumberTextField.textField.isShowingAccessory = true
        accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(disposeBag)
        accountNumberTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        questionMarkButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.accountNumber.value.characters.count > 0 {
                self.viewModel.accountNumberHasTenDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.accountNumberTextField.setError(NSLocalizedString("Account number must be 10 digits long.", comment: ""))
                    } else {
                        
                    }
                }).addDisposableTo(self.disposeBag)
            }
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        
        accountNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.accountNumberTextField.setError(nil)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
    }
    
    private func accessibilityErrorLabel() {
        let message = accountNumberTextField.getError()
        
        if message.isEmpty {
            self.nextButton.accessibilityLabel = NSLocalizedString("Next", comment: "")
        } else {
            self.nextButton.accessibilityLabel = NSLocalizedString(message + " Next", comment: "")
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.view.backgroundColor = .primaryColor // This prevents a black color from appearing during the transition between `isTranslucent = false` and `isTranslucent = true`
        navigationController?.navigationBar.barTintColor = .primaryColor
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black // Needed for white status bar
        navigationController?.navigationBar.tintColor = .white
        
        setNeedsStatusBarAppearanceUpdate()
        
        let titleDict: [String: Any] = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: OpenSans.bold.of(size: 18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func onNextPress() {
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.validateAccount(onSuccess: {
            LoadingView.hide()
            
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
        switch Environment.sharedInstance.opco {
        case .bge:
            description = NSLocalizedString("Your Customer Account Number can be found in the lower right portion of your bill. Please enter 10-digits including leading zeros.", comment: "")
        case .comEd:
            description = NSLocalizedString("Your Account Number is located in the upper right portion of a residential bill and the upper center portion of a commercial bill. Please enter all 10 digits, including leading zeros, but no dashes.", comment: "")
        case .peco:
            description = NSLocalizedString("Your Account Number is located in the upper left portion of your bill. Please enter all 10 digits, including leading zeroes, but no dashes. If \"SUMM\" appears after your name on your bill, please enter any account from your list of individual accounts.", comment: "")
        }
        let infoModal = InfoModalViewController(title: NSLocalizedString("Where to Look for Your Account Number", comment: ""), image: #imageLiteral(resourceName: "bill_infographic"), description: description)
        
        self.navigationController?.present(infoModal, animated: true, completion: nil)
    }

}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
extension RegistrationBGEAccountNumberViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField ==  accountNumberTextField.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 10
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.accountNumberHasTenDigits().single().subscribe(onNext: { enabled in
            if enabled {
                self.onNextPress()
            }
        }).addDisposableTo(disposeBag)

        return true
    }
}

