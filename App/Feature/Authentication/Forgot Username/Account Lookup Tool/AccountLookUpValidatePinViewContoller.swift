//
//  AccoubntLookUpValidatePinViewContoller.swift
//  EUMobile
//
//  Created by Tiwari, Anurag on 20/04/23.
//  Copyright © 2023 Exelon Corporation. All rights reserved.
//

import RxSwift
import RxCocoa

protocol AccountLookUpValidatePinViewControllerDelegate: class {
    func accountLookUpValidatePinViewController(_ accountLookUpValidatePinViewController: UIViewController, didUnmaskUsername username: String)
}

class AccountLookUpValidatePinViewController: KeyboardAvoidingStickyFooterViewController {

    @IBOutlet weak var resendCodeTextField: FloatLabelTextField!
    @IBOutlet weak var resendCodeDescription: UILabel!
    @IBOutlet weak var resendCodePress: UIButton!
    @IBOutlet weak var continueButton: PrimaryButton!
    @IBOutlet weak var imgCodeSent: UIImageView!
    @IBOutlet weak var codeSentText: UILabel!
    
    let disposeBag = DisposeBag()
    
    var viewModel = AccountLookupToolViewModel()
    
    weak var delegate: AccountLookupToolResultViewControllerDelegate?
    weak var delegateValidatePin: AccountLookUpValidatePinViewControllerDelegate?
    var secondsRemaining = 25
    
    override func viewDidLoad() {
        
        addCloseButton()
        title = NSLocalizedString("Account Lookup Tool", comment: "")
        resendCodeTextField.placeholder = NSLocalizedString("6-Digit Code", comment: "")
        resendCodeTextField.textField.delegate = self
        resendCodeTextField.textField.autocorrectionType = .no
        resendCodeTextField.setKeyboardType(.phonePad)
        resendCodeTextField.textField.rx.text.orEmpty.bind(to: viewModel.sixDigitPinNumber).disposed(by: disposeBag)
        viewModel.phoneNumber.bind(to: resendCodeDescription.rx.text).disposed(by: disposeBag)
        resendCodeDescription.text =  NSLocalizedString("Enter the six-digit code sent to (***) ***-\(String(viewModel.phoneNumber.value.suffix(4))). This code will expire after 5 minutes.", comment: "")
        viewModel.continuePinButtonEnabled.drive(continueButton.rx.isEnabled).disposed(by: disposeBag)
        self.imgCodeSent.isHidden = true
        self.codeSentText.isHidden = true
        startTimer()
    }
    
    @IBAction func onResendCodePress(_ sender: Any) {
        secondsRemaining = 25
        FirebaseUtility.logEvent(.forgotUsername(parameters: [.resend_code_cta]))
        self.resendCodePress.titleLabel?.textColor = .neutralLight
        LoadingView.show()
        viewModel.sendSixDigitCode(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            self.imgCodeSent.isHidden = false
            self.codeSentText.isHidden = false
            self.startTimer()
        }, onError: { [weak self] title, message in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
        })
    }
    
    @IBAction func continueButton(_ sender: Any) {
        LoadingView.show()
        FirebaseUtility.logEvent(.forgotUsername(parameters: [.send_code_validated]))
        viewModel.validateSixDigitCode(onSuccess: { [weak self] in
            LoadingView.hide()
            guard let self = self else { return }
            if self.viewModel.validatePinResult.isMultiple == false {
                let viewController = UIApplication.shared.windows.first?.rootViewController
                guard let rootNavVc = viewController as? LargeTitleNavigationController else { return }
                for vc in rootNavVc.viewControllers {
                    guard let dest = vc as? LandingViewController else {
                        continue
                    }
                    self.delegateValidatePin = dest
                    self.delegateValidatePin?.accountLookUpValidatePinViewController(self, didUnmaskUsername:(self.viewModel.validatePinResult.usernames?[0].email ?? ""))
                }
                self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
            } else if self.viewModel.validatePinResult.accounts?.count > 0 {
                self.performSegue(withIdentifier: "accountLookupToolResultSegue", sender: self)
            }
        
        }, onError: { [weak self] title, message in
            LoadingView.hide()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alertController, animated: true, completion: nil)
      
        })
    }
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (Timer) in
               if self.secondsRemaining > 0 {
                   self.secondsRemaining -= 1
               } else {
                   self.resendCodePress.titleLabel?.textColor = .actionPrimary
                   self.imgCodeSent.isHidden = true
                   self.codeSentText.isHidden = true
                   Timer.invalidate()
               }
           }
                
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AccountLookupToolResultViewController {
            vc.delegate = delegate
            vc.viewModel = viewModel
        }
    }
}
  
extension AccountLookUpValidatePinViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == resendCodeTextField?.textField {
            let characterSet = CharacterSet(charactersIn: string)
            return CharacterSet.decimalDigits.isSuperset(of: characterSet) && newString.count <= 6
        }
        return true
    }
}

