//
//  RegistrationValidateAccountViewController.swift
//  Mobile
//
//  Created by MG-MC-GHill on 5/22/17.
//  Copyright © 2017 Exelon Corporation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ToastSwiftFramework

class RegistrationValidateAccountViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var registrationFormView: UIView!

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var accountNumberView: UIView!
    @IBOutlet weak var accountNumberTextField: FloatLabelTextField!
    @IBOutlet weak var phoneNumberTextField: FloatLabelTextField!
    @IBOutlet weak var ssNumberNumberTextField: FloatLabelTextField!

    @IBOutlet weak var questionMarkButton: UIButton!
    @IBOutlet weak var identifierDescriptionLabel: UILabel?

    let viewModel = RegistrationViewModel(registrationService: ServiceFactory.createRegistrationService(), authenticationService: ServiceFactory.createAuthenticationService())

    var nextButton = UIBarButtonItem()
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotificationCenter()
        
        title = NSLocalizedString("Register", comment: "")

        setupNavigationButtons()
        
        populateHelperLabels()
        
        prepareTextFieldsForInput()
        
        checkForMaintenanceMode()
    }
    
    func checkForMaintenanceMode(){
        viewModel.checkForMaintenance(onSuccess: { isMaintenance in
            if isMaintenance {
                self.navigationController?.view.isUserInteractionEnabled = true
                let ad = UIApplication.shared.delegate as! AppDelegate
                ad.showMaintenanceMode()
            }
        }, onError: { errorMessage in
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    /// Helpers
    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupNavigationButtons() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancelPress))
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .done, target: self, action: #selector(onNextPress))
        viewModel.nextButtonEnabled().bind(to: nextButton.rx.isEnabled).addDisposableTo(disposeBag)

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = nextButton
    }
    
    func populateHelperLabels() {
        instructionLabel.textColor = .blackText
        instructionLabel.text = NSLocalizedString("Please help us validate your account", comment: "")
        instructionLabel.font = SystemFont.semibold.of(textStyle: .headline)
        
        var identifierString = "Last 4 Digits of primary account holder’s Social Security Number"
        
        if Environment.sharedInstance.opco == .bge {
            identifierString.append(", Business Tax ID, or BGE Pin")
        } else {
            identifierString.append(" or Business Tax ID.")
        }
        
        identifierDescriptionLabel?.text = NSLocalizedString(identifierString,
                                                             comment: "")
        identifierDescriptionLabel?.font = SystemFont.regular.of(textStyle: .subheadline)
    }
    
    func prepareTextFieldsForInput() {
        //
        let opCo = Environment.sharedInstance.opco

        // if opco is not BGE, then format it and ready it for usage; else hide it.
        if opCo != .bge {
            accountNumberTextField.textField.placeholder = NSLocalizedString("Account Number*", comment: "")
            accountNumberTextField.textField.autocorrectionType = .no
            accountNumberTextField.textField.returnKeyType = .next
            accountNumberTextField.textField.delegate = self
            accountNumberTextField.textField.isShowingAccessory = true
            accountNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.accountNumber).addDisposableTo(disposeBag)
            accountNumberTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
            questionMarkButton.accessibilityLabel = NSLocalizedString("Tool tip", comment: "")
            
            accountNumberTextField?.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
                if self.viewModel.accountNumber.value.characters.count > 0 {
                    self.viewModel.accountNumberHasTenDigits().single().subscribe(onNext: { valid in
                        if !valid {
                            self.accountNumberTextField?.setError(NSLocalizedString("Account number must be 10 digits long.", comment: ""))
                        }
                    }).addDisposableTo(self.disposeBag)
                }
                self.accessibilityErrorLabel()
                
            }).addDisposableTo(disposeBag)
            
            accountNumberTextField?.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
                self.accountNumberTextField?.setError(nil)
                self.accessibilityErrorLabel()
                
            }).addDisposableTo(disposeBag)
        } else {
            accountNumberView.isHidden = true
        }
        
        //
        phoneNumberTextField.textField.placeholder = NSLocalizedString("Primary Phone Number*", comment: "")
        phoneNumberTextField.textField.autocorrectionType = .no
        phoneNumberTextField.textField.returnKeyType = .next
        phoneNumberTextField.textField.delegate = self
        phoneNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.phoneNumber).addDisposableTo(disposeBag)
        phoneNumberTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.phoneNumber.value.characters.count > 0 {
                self.viewModel.phoneNumberHasTenDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.phoneNumberTextField.setError(NSLocalizedString("Phone number must be 10 digits long.", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        
        phoneNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.phoneNumberTextField.setError(nil)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        
        //
        var ssString = "SSN/Business Tax ID"
        
        if Environment.sharedInstance.opco == .bge {
            ssString.append("/BGE Pin*")
        } else {
            ssString.append("*")
        }
        
        ssNumberNumberTextField.textField.placeholder = NSLocalizedString(ssString, comment: "")
        ssNumberNumberTextField.textField.autocorrectionType = .no
        ssNumberNumberTextField.textField.returnKeyType = .done
        ssNumberNumberTextField.textField.delegate = self
        ssNumberNumberTextField.textField.rx.text.orEmpty.bind(to: viewModel.identifierNumber).addDisposableTo(disposeBag)
        ssNumberNumberTextField.textField.font = SystemFont.regular.of(textStyle: .title2)
        
        ssNumberNumberTextField.textField.rx.controlEvent(.editingDidEnd).subscribe(onNext: { _ in
            if self.viewModel.identifierNumber.value.characters.count > 0 {
                self.viewModel.identifierHasFourDigits().single().subscribe(onNext: { valid in
                    if !valid {
                        self.ssNumberNumberTextField.setError(NSLocalizedString("This number must be 4 digits long.", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
                self.viewModel.identifierIsNumeric().single().subscribe(onNext: { numeric in
                    if !numeric {
                        self.ssNumberNumberTextField.setError(NSLocalizedString("This number must be numeric.", comment: ""))
                    }
                }).addDisposableTo(self.disposeBag)
            }
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        
        ssNumberNumberTextField.textField.rx.controlEvent(.editingDidBegin).subscribe(onNext: { _ in
            self.ssNumberNumberTextField?.setError(nil)
            self.accessibilityErrorLabel()
            
        }).addDisposableTo(disposeBag)
        
        accountNumberTextField.setNumberKeyboard()
        phoneNumberTextField.setNumberKeyboard()
        ssNumberNumberTextField.setNumberKeyboard()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func accessibilityErrorLabel() {
        var message = ""
        message += accountNumberTextField.getError()
        message += phoneNumberTextField.getError()
        message += ssNumberNumberTextField.getError()
        
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
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func onCancelPress() {
        // We do this to cover the case where we push RegistrationViewController from LandingViewController.
        // When that happens, we want the cancel action to go straight back to LandingViewController.
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onNextPress() {
        view.endEditing(true)
        
        LoadingView.show()
        
        viewModel.validateAccount(onSuccess: {
            LoadingView.hide()
            
            self.performSegue(withIdentifier: "createCredentialsSegue", sender: self)
        }, onMultipleAccounts:  {
            LoadingView.hide()

            self.performSegue(withIdentifier: "bgeAccountNumberSegue", sender: self)
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


    // MARK: - ScrollView
    
    func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo!
        let endFrameRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let insets = UIEdgeInsetsMake(0, 0, endFrameRect.size.height, 0)
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if let vc = segue.destination as? RegistrationCreateCredentialsViewController {
            vc.viewModel = viewModel
        } else if let vc = segue.destination as? RegistrationBGEAccountNumberViewController {
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
extension RegistrationValidateAccountViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == phoneNumberTextField.textField {
            let components = newString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            
            if length > 10 {
                return false
            }
            
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if length - index > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            
            textField.sendActions(for: .valueChanged) // Send rx events
            
            return false
        } else if textField == ssNumberNumberTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 4
        } else if textField == accountNumberTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.characters.count <= 10
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == accountNumberTextField.textField {
            phoneNumberTextField.textField.becomeFirstResponder()
        } else if textField == phoneNumberTextField.textField {
            ssNumberNumberTextField.textField.becomeFirstResponder()
        } else if textField == ssNumberNumberTextField?.textField || textField == accountNumberTextField?.textField {
            viewModel.nextButtonEnabled().single().subscribe(onNext: { enabled in
                if enabled {
                    self.onNextPress()
                } else {
                    self.view.endEditing(true)
                }
            }).addDisposableTo(disposeBag)
        }
        return false
    }

}
